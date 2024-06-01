import Foundation

class APIService {
    static func fetchModels(apiUrlHost: String, completion: @escaping ([Model]) -> Void) {
        guard let url = URL(string: "\(apiUrlHost)/api/tags") else {
            print("Invalid URL")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let modelsResponse = try JSONDecoder().decode(ModelResponse.self, from: data)
                completion(modelsResponse.models)
            } catch {
                print("Failed to decode models: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    static func fetchModelNames(apiUrlHost: String, completion: @escaping ([String]) -> Void) {
        fetchModels(apiUrlHost: apiUrlHost) { models in
            let modelNames = models.map { $0.name }
            completion(modelNames)
        }
    }

    static func deleteModel(apiUrlHost: String, modelName: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(apiUrlHost)/api/delete") else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["name": modelName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to delete model")
                completion(false)
                return
            }

            completion(true)
        }.resume()
    }

    static func fetchResponse(for input: String, selectedModel: String, apiUrlHost: String, completion: @escaping (String, String, String) -> Void) {
        guard let url = URL(string: "\(apiUrlHost)/api/chat") else {
            completion("Invalid URL", "", "")
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
            completion("Failed to create input stream", "", "")
            return
        }
        
        request.httpBodyStream = inputStream
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Network error: \(error?.localizedDescription ?? "Unknown error")", "", "")
                return
            }
            
            do {
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                completion(chatResponse.message.content, chatResponse.model, chatResponse.created_at)
            } catch {
                completion("Failed to decode response", "", "")
            }
        }
        task.resume()
    }
    
    static func createInputStream(from parameters: [String: Any]) -> InputStream? {
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        guard let data = jsonData else { return nil }
        return InputStream(data: data)
    }
}
