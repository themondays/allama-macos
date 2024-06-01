import SwiftUI

struct ModelManagementView: View {
    @ObservedObject var viewModel: ModelManagementViewModel
    @State private var selectedModel: Model?

    var body: some View {
        NavigationView {
            FirstColumnView(models: viewModel.models, selectedModel: $selectedModel, refreshModels: viewModel.fetchModels, deleteModel: viewModel.deleteModel)
            if let selectedModel = selectedModel {
                ModelDetailsView(model: selectedModel, deleteModel: {
                    Task {
                        await viewModel.deleteModel(named: selectedModel.name)
                        self.selectedModel = nil
                    }
                })
            } else {
                ModelDetailsPlaceholderView()
            }
        }
        .frame(minWidth: 600, minHeight: 500) // Adjust the frame to ensure details are fully visible
        .onAppear {
            Task {
                await viewModel.fetchModels()
            }
        }
    }
}

struct FirstColumnView: View {
    let models: [Model]
    @Binding var selectedModel: Model?
    let refreshModels: () async -> Void
    let deleteModel: (String) async -> Void

    var body: some View {
        List {
            ForEach(models, id: \.name) { model in
                HStack {
                    VStack(alignment: .leading) {
                        Text(model.name)
                            .font(.headline)
                        Text(model.model)
                            .font(.subheadline)
                        Text("Modified: \(model.modified_at)")
                            .font(.caption)
                        Text("Size: \(model.sizeInGigabytes)")                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(10)
                .background(selectedModel?.name == model.name ? Color.blue.opacity(0.2) : Color.clear)
                .contentShape(Rectangle()) // Make the entire row clickable
                .onTapGesture {
                    selectedModel = model
                }
            }
        }
        .navigationTitle("Models")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task {
                        await refreshModels()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct ModelDetailsView: View {
    let model: Model
    let deleteModel: () async -> Void

    var body: some View {
        ScrollView { // Make the details view scrollable
            VStack(alignment: .leading, spacing: 10) {
                Text("Model Details")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                Text("Name: \(model.name)")
                    .font(.headline)
                Text("Model: \(model.model)")
                    .font(.subheadline)
                Text("Modified: \(model.modified_at)")
                    .font(.caption)
                Text("Size: \(model.size) bytes")
                    .font(.caption)
                Text("Digest: \(model.digest)")
                    .font(.caption)
                Text("Expires at: \(model.expires_at)")
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Details:")
                        .font(.headline)
                    Text("Parent Model: \(model.details.parent_model)")
                        .font(.caption)
                    Text("Format: \(model.details.format)")
                        .font(.caption)
                    Text("Family: \(model.details.family)")
                        .font(.caption)
                    Text("Families: \(model.details.families?.joined(separator: ", ") ?? "N/A")")
                        .font(.caption)
                    Text("Parameter Size: \(model.details.parameter_size)")
                        .font(.caption)
                    Text("Quantization Level: \(model.details.quantization_level)")
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await deleteModel()
                    }
                }) {
                    Text("Delete Model")
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ModelDetailsPlaceholderView: View {
    var body: some View {
        Text("Select a model to see details")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModelManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ModelManagementView(viewModel: ModelManagementViewModel(apiUrlHost: "http://localhost:11434"))
    }
}
