import SwiftUI

struct SidebarView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Chats")
                .font(.title2)
                .bold()
                .padding(.top, 40)
                .padding(.leading, 20)
                .foregroundColor(.white)
            if chatViewModel.chatNames.isEmpty {
                ChatsListPlaceholderView()
            } else {
                List {
                    ForEach(chatViewModel.chatNames.indices, id: \.self) { index in
                        HStack {
                            Button(action: {
                                chatViewModel.isLoading ? nil : chatViewModel.switchChat(to: index)
                            }) {
                                Text(chatViewModel.chatNames[index].1)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(SidebarButtonStyle(selected: chatViewModel.currentChatIndex == index))
                            Button(action: {
                                chatViewModel.removeChat(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                            .buttonStyle(DeleteButtonStyle())
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 25)
                    }
                }
                .listStyle(SidebarListStyle())
            }
            Button(action: {
                chatViewModel.isLoading ? nil : chatViewModel.startNewChat()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Chat")
                        .bold()
                }
                .opacity(chatViewModel.isLoading ? 0.2 : 1)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            Spacer()
        }
        .background(Color.black.opacity(0.9))
        .foregroundColor(.white)
    }
}

struct ChatsListPlaceholderView: View {
    var body: some View {
        Text("Add new chat to start")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
