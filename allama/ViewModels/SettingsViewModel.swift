import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var apiUrlHost: String = "http://localhost:11434"
    @Published var serverRunning = false
    @Published var models: [String] = []
    @Published var selectedModel = ""
    @Published var showingSettings = false
    @Published var isPullingModel: Bool = false
    @Published var modelNameToPull: String = ""
    @Published var downloadProgress: Double = 0.0
    @Published var downloadError: String?
    
    func startServer() {
        ServerService.startServer { [weak self] in
            self?.serverRunning = true
            self?.fetchModels()
        }
    }
    
    func fetchModels() {
        ServerService.fetchModelNames(apiUrlHost: apiUrlHost) { [weak self] models in
            self?.models = models
            self?.selectedModel = models.first ?? ""
        }
    }
    
    func pullModel() {
        ServerService.pullModel(modelName: modelNameToPull, apiUrlHost: apiUrlHost, progressHandler: { [weak self] progress in
            self?.downloadProgress = progress
        }, completionHandler: { [weak self] error in
            if let error = error {
                self?.downloadError = error.localizedDescription
            } else {
                self?.isPullingModel = false
            }
        })
    }
}
