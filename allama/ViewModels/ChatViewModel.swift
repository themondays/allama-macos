import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var chatHistory: [[String]] = [[]]
    @Published var currentChatId: String = UUID().uuidString
    @Published var currentChatIndex = 0
    @Published var serverRunning = false
    @Published var selectedModel = ""
    @Published var models: [String] = []
    @Published var isLoadingModels = false
    @Published var timer: Timer?
    @Published var fullResponse: String = ""
    @Published var displayedResponse: String = ""
    @Published var isLoading: Bool = false
    @Published var chatNames: [(String, String)] = []  // Tuple of (chatId, chatName)
    @Published var apiUrlHost: String = "http://localhost:11434"
    
    func loadChats() {
        DispatchQueue.main.async {
            self.chatNames = DatabaseHelper.shared.fetchChatNames()
            if self.chatNames.isEmpty {
                self.chatNames = [(self.currentChatId, "Chat 1")]
                self.chatHistory = [[]]
                DatabaseHelper.shared.addChatName(id: self.currentChatId, name: "Chat 1")
            } else {
                self.chatHistory = Array(repeating: [], count: self.chatNames.count)
                for (index, chat) in self.chatNames.enumerated() {
                    self.chatHistory[index] = DatabaseHelper.shared.fetchMessages(forChatId: chat.0)
                }
            }
        }
    }
    
    func switchChat(to index: Int) {
        DispatchQueue.main.async {
            self.currentChatIndex = index
            self.currentChatId = self.chatNames[index].0
            self.loadChats()
        }
    }
    
    func startNewChat() {
        DispatchQueue.main.async {
            self.currentChatId = UUID().uuidString
            self.chatHistory.append([])
            self.chatNames.append((self.currentChatId, "Chat \(self.chatNames.count + 1)"))
            DatabaseHelper.shared.addChatName(id: self.currentChatId, name: "Chat \(self.chatNames.count + 1)")
            self.currentChatIndex = self.chatHistory.count - 1
        }
    }
    
    func removeChat(at index: Int) {
        DispatchQueue.main.async {
            let chatIdToRemove = self.chatNames[index].0
            DatabaseHelper.shared.removeMessages(forChatId: chatIdToRemove)
            DatabaseHelper.shared.removeChatName(id: chatIdToRemove)
            self.chatHistory.remove(at: index)
            self.chatNames.remove(at: index)
            if self.chatHistory.isEmpty {
                self.startNewChat()
            } else if self.currentChatIndex >= self.chatHistory.count {
                self.currentChatIndex = self.chatHistory.count - 1
                self.currentChatId = self.chatNames[self.currentChatIndex].0
            }
        }
    }
    
    func checkServer() {
        ServerService.checkServer(apiUrlHost: apiUrlHost) { [weak self] running in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if running {
                    self.serverRunning = true
                    self.fetchModels()
                } else {
                    self.startServer()
                }
            }
        }
    }
    
    func startServer() {
        ServerService.startServer { [weak self] in
            DispatchQueue.main.async {
                self?.serverRunning = true
                self?.fetchModels()
            }
        }
    }
    
    func fetchModels() {
        isLoadingModels = true
        ServerService.fetchModelNames(apiUrlHost: apiUrlHost) { [weak self] models in
            DispatchQueue.main.async {
                self?.models = models
                self?.selectedModel = models.first ?? ""
                self?.isLoadingModels = false
            }
        }
    }
    
    func sendMessage() {
        if !userInput.isEmpty {
            let userMessage = "[user] \(userInput)"
            DispatchQueue.main.async {
                self.chatHistory[self.currentChatIndex].append(userMessage)
                // DatabaseHelper.shared.addMessage(chatId: self.currentChatId, message: userMessage, role: "user", timestamp: "", model: "")

                self.isLoading = true
                self.displayedResponse = ""
                self.chatHistory[self.currentChatIndex].append(self.displayedResponse)
                DatabaseHelper.shared.addMessage(chatId: self.currentChatId, message: self.userInput, role: "user", timestamp: "", model: "")
            }
            
            ServerService.fetchResponse(for: userInput, selectedModel: selectedModel, apiUrlHost: apiUrlHost, displayedResponse: Binding(get: { self.displayedResponse }, set: { self.displayedResponse = $0 })) { [weak self] (response: String, model: String, timestamp: String, done: Bool) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if self.chatNames[self.currentChatIndex].1.hasPrefix("Chat ") {
                        if let firstLine = response.split(separator: "\n").first {
                            let newChatName = self.trimmedChatName(from: String(firstLine))
                            self.chatNames[self.currentChatIndex] = (self.currentChatId, newChatName)
                            DatabaseHelper.shared.updateChatName(id: self.currentChatId, name: newChatName)
                        }
                    }
                    self.chatHistory[self.currentChatIndex][self.chatHistory[self.currentChatIndex].count - 1] = "[assistant] \(response)\n\n \(model)@\(timestamp)"
                    if done == true {
                        DatabaseHelper.shared.addMessage(chatId: self.currentChatId, message: response, role: "assistant", timestamp: timestamp, model: model)
                    }
                    self.fullResponse = response
                    self.isLoading = false
                    self.userInput = ""
                }
            }
        }
    }
    
    private func trimmedChatName(from response: String) -> String {
        if response.count > 50 {
            let index = response.index(response.startIndex, offsetBy: 50)
            return String(response[..<index]) + "..."
        } else {
            return response
        }
    }
}
