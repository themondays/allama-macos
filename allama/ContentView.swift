import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var modelManagementViewModel = ModelManagementViewModel(apiUrlHost: "http://localhost:11434")
    @State private var showingModelManagement = false

    var body: some View {
        GeometryReader { geometry in
            HStack {
                SidebarView(chatViewModel: chatViewModel)
                    .frame(width: geometry.size.width * 0.3)
                Divider()
                MainContentView(chatViewModel: chatViewModel)
                    .frame(width: geometry.size.width * 0.7)
            }
        }
        .onAppear {
            chatViewModel.checkServer()
            chatViewModel.loadChats()
        }
        .onDisappear {
            chatViewModel.timer?.invalidate()
        }
        .sheet(isPresented: $settingsViewModel.showingSettings) {
            SettingsView(viewModel: settingsViewModel)
        }
        .sheet(isPresented: $showingModelManagement) {
            ModelManagementView(viewModel: modelManagementViewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Text("Active Model: \(chatViewModel.selectedModel)")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingModelManagement.toggle()
                }) {
                    Image(systemName: "list.bullet")
                }
                Button(action: {
                    settingsViewModel.showingSettings.toggle()
                }) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
    }
}
