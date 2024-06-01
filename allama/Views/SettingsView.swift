import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .padding(.top, 20)
            
            Form {
                Section(header: Text("API Settings")) {
                    TextField("API URL Host", text: $viewModel.apiUrlHost)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Server Control")) {
                    if viewModel.serverRunning {
                        Text("Server is running")
                            .foregroundColor(.green)
                    } else {
                        Text("Server is stopped")
                            .foregroundColor(.red)
                    }
                    Button(action: {
                        viewModel.startServer()
                    }) {
                        Text(viewModel.serverRunning ? "Restart Server" : "Start Server")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("Model Management")) {
                    Button(action: {
                        viewModel.fetchModels()
                    }) {
                        Text("Reload Models")
                            .foregroundColor(.blue)
                    }
                    if viewModel.models.isEmpty {
                        Text("No models available")
                            .foregroundColor(.red)
                    } else {
                        Picker("Select Model", selection: $viewModel.selectedModel) {
                            ForEach(viewModel.models, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    TextField("Model to Pull", text: $viewModel.modelNameToPull)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isPullingModel)
                    
                    Button(action: {
                        viewModel.pullModel()
                    }) {
                        Text("Pull Model")
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.isPullingModel)
                    
                    if viewModel.downloadProgress > 0 {
                        ProgressView(value: viewModel.downloadProgress)
                            .padding()
                    }
                    
                    if let error = viewModel.downloadError {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}
