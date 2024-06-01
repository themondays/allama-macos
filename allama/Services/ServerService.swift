import Foundation
import SwiftUI

class ServerService {
    static func checkServer(apiUrlHost: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(apiUrlHost)/status") else {
            print("Invalid URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
                return
            }
            
            completion(httpResponse.statusCode == 200)
        }.resume()
    }
    
    static func startServer(completion: @escaping () -> Void) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["ollama", "serve"]
        task.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/path/to/ollama", "HOME": NSHomeDirectory()]
        task.launch()
        completion()
    }
    
    static func fetchModels(apiUrlHost: String, completion: @escaping ([Model]) -> Void) {
        APIService.fetchModels(apiUrlHost: apiUrlHost, completion: completion)
    }

    static func fetchModelNames(apiUrlHost: String, completion: @escaping ([String]) -> Void) {
        APIService.fetchModelNames(apiUrlHost: apiUrlHost, completion: completion)
    }

    static func fetchResponse(for input: String, selectedModel: String, apiUrlHost: String, displayedResponse: Binding<String>, completion: @escaping (String, String, String, Bool) -> Void) {
        guard let url = URL(string: "\(apiUrlHost)/api/chat") else {
            DispatchQueue.main.async {
                completion("Invalid URL", "", "", false)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "messages": [["role": "user", "content": input]],
            "model": selectedModel
        ]
        
        guard let inputStream = createInputStream(from: parameters) else {
            DispatchQueue.main.async {
                completion("Failed to create input stream", "", "", false)
            }
            return
        }
        
        request.httpBodyStream = inputStream
        
        let typeEffectHandler = TypeEffectHandler()
        let streamHandler = StreamHandler(completion: completion, typeEffectHandler: typeEffectHandler, displayedResponse: displayedResponse, updateBotResponse: { response in
            DispatchQueue.main.async {
                displayedResponse.wrappedValue = response
            }
        })
        let session = URLSession(configuration: .default, delegate: streamHandler, delegateQueue: nil)
        streamHandler.dataTask = session.dataTask(with: request)
        streamHandler.dataTask?.resume()
    }
    
    static func createInputStream(from parameters: [String: Any]) -> InputStream? {
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        guard let data = jsonData else { return nil }
        return InputStream(data: data)
    }
    
    static func pullModel(modelName: String, apiUrlHost: String, progressHandler: @escaping (Double) -> Void, completionHandler: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(apiUrlHost)/api/pull") else {
            print("Invalid URL")
            completionHandler(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": modelName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let session = URLSession(configuration: .default, delegate: PullModelDelegate(progressHandler: progressHandler, completionHandler: completionHandler), delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    class PullModelDelegate: NSObject, URLSessionDataDelegate {
        let progressHandler: (Double) -> Void
        let completionHandler: (Error?) -> Void
        
        init(progressHandler: @escaping (Double) -> Void, completionHandler: @escaping (Error?) -> Void) {
            self.progressHandler = progressHandler
            self.completionHandler = completionHandler
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let jsonString = String(data: data, encoding: .utf8) else { return }
            let jsonStringArray = jsonString.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            for jsonString in jsonStringArray {
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let statusResponse = try JSONDecoder().decode(PullModelStatus.self, from: jsonData)
                        DispatchQueue.main.async {
                            switch statusResponse.status {
                            case "success":
                                self.progressHandler(1.0)
                                self.completionHandler(nil)
                            case let status where status.contains("pulling") || status.hasPrefix("downloading"):
                                if let completed = statusResponse.completed, let total = statusResponse.total {
                                    self.progressHandler(Double(completed) / Double(total))
                                }
                            default:
                                break
                            }
                        }
                    } catch {
                        do {
                            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: jsonData)
                            DispatchQueue.main.async {
                                self.completionHandler(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorResponse.message]))
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.completionHandler(error)
                            }
                        }
                    }
                }
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                DispatchQueue.main.async {
                    self.completionHandler(error)
                }
            }
        }
    }
    
    class StreamHandler: NSObject, URLSessionDataDelegate {
        var dataTask: URLSessionDataTask?
        var completion: ((String, String, String, Bool) -> Void)?
        var fullResponse: String = ""
        var typeEffectHandler: TypeEffectHandler
        var displayedResponse: Binding<String>
        var updateBotResponse: (String) -> Void

        init(completion: @escaping (String, String, String, Bool) -> Void, typeEffectHandler: TypeEffectHandler, displayedResponse: Binding<String>, updateBotResponse: @escaping (String) -> Void) {
            self.completion = completion
            self.typeEffectHandler = typeEffectHandler
            self.displayedResponse = displayedResponse
            self.updateBotResponse = updateBotResponse
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            guard let jsonString = String(data: data, encoding: .utf8) else { return }
            let jsonStringArray = jsonString.components(separatedBy: "\n").filter { !$0.isEmpty }
            self.completion?(self.fullResponse, "", "", false)
            for jsonString in jsonStringArray {
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: jsonData)
                        let messageContent = chatResponse.message.content

                        self.fullResponse += messageContent

                        DispatchQueue.main.async {
                            self.typeEffectHandler.typeEffect(for: messageContent, displayedResponse: self.displayedResponse) {
                                // Update bot response in real-time
                                self.updateBotResponse(self.fullResponse)
                            }
                        }

                        if chatResponse.done {
                            DispatchQueue.main.async {
                                self.completion?(self.fullResponse, chatResponse.model, chatResponse.created_at, chatResponse.done)
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.completion?("Failed to decode response", "", "", false)
                        }
                    }
                }
            }
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                DispatchQueue.main.async {
                    self.completion?("Network error: \(error.localizedDescription)", "", "", false)
                }
            }
        }
    }
}
