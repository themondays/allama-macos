import Foundation
import SwiftUI

@MainActor
class ModelManagementViewModel: ObservableObject {
    @Published var models: [Model] = []
    let apiUrlHost: String

    init(apiUrlHost: String) {
        self.apiUrlHost = apiUrlHost
        Task {
            await fetchModels()
        }
    }

    func fetchModels() async {
        APIService.fetchModels(apiUrlHost: apiUrlHost) { [weak self] models in
            DispatchQueue.main.async {
                self?.models = models
            }
        }
    }

    func deleteModel(named modelName: String) async {
        APIService.deleteModel(apiUrlHost: apiUrlHost, modelName: modelName) { success in
            if success {
                Task {
                    await self.fetchModels()
                }
            } else {
                print("Failed to delete model: \(modelName)")
            }
        }
    }
}
