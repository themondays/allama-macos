import SwiftUI

struct MainContentView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            if !chatViewModel.serverRunning {
                Button(action: {
                    chatViewModel.startServer()
                }) {
                    Text("Start Ollama Server")
                        .padding()
                        .buttonStyle(PlainButtonStyle())
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                VStack(alignment: .leading) {
                    if chatViewModel.isLoadingModels {
                        Text("Loading models...")
                            .padding()
                    } else if chatViewModel.models.isEmpty {
                        Text("No models available")
                            .padding()
                    } else {
                        Picker("Select Model", selection: $chatViewModel.selectedModel) {
                            ForEach(chatViewModel.models, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                }
                
                ScrollView {
                    ChatView(chatViewModel: chatViewModel)
                }
                
                HStack(spacing: 0) {
                    TextField("Type your message...", text: $chatViewModel.userInput, onCommit: chatViewModel.sendMessage)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(0)
                        .background(Color.clear)
                        .cornerRadius(10)
                        .frame(height: 25)
                        .border(Color.clear, width: 0)
                    
                    Button(action: chatViewModel.sendMessage) {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                            .padding()
                            .foregroundColor(chatViewModel.isLoading ? Color.gray : Color.blue)
                            .cornerRadius(10)
                            .frame(height: 15)
                    }
                    .frame(height: 15)
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.clear)
                    .disabled(chatViewModel.isLoading)
                }
                .cornerRadius(10)
                .padding(10)
                .frame(height: 40)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .edgesIgnoringSafeArea(.all)
    }
}
