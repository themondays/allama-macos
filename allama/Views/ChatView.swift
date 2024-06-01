import SwiftUI
import MarkdownUI
import AVFoundation

struct ChatView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if chatViewModel.chatHistory.isEmpty {
                ChatPlaceholderView()
            } else {
                ForEach(chatViewModel.chatHistory[chatViewModel.currentChatIndex].indices, id: \.self) { index in
                    Group {
                        if chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].starts(with: "[user]") {
                            Text(chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].replacingOccurrences(of: "[user] ", with: ""))
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            VStack(alignment: .leading) {
                                Markdown(chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].replacingOccurrences(of: "[assistant] ", with: ""))
                                    .padding()
                                
                                HStack {
                                    Button(action: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].replacingOccurrences(of: "[assistant] ", with: ""), forType: .string)
                                    }) {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .background(Color.clear)
                                    .padding(.leading)
                                    
                                    Button(action: {
                                        let utterance = AVSpeechUtterance(string: chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].replacingOccurrences(of: "[assistant] ", with: ""))
                                        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                        let synthesizer = AVSpeechSynthesizer()
                                        synthesizer.speak(utterance)
                                    }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                    }
                                    .background(Color.clear)
                                    .padding(.leading)
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Spacer()
                                }
                                .padding(.bottom, 10)
                            }
                            .contextMenu {
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].replacingOccurrences(of: "[assistant] ", with: ""), forType: .string)
                                }) {
                                    Text("Copy to Clipboard")
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(PlainButtonStyle())
                                .background(Color.clear)
                                
                                Button(action: {
                                    let utterance = AVSpeechUtterance(string: chatViewModel.chatHistory[chatViewModel.currentChatIndex][index].replacingOccurrences(of: "[assistant] ", with: ""))
                                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                    let synthesizer = AVSpeechSynthesizer()
                                    synthesizer.speak(utterance)
                                }) {
                                    Text("Speak")
                                    Image(systemName: "speaker.wave.2.fill")
                                }
                                .buttonStyle(PlainButtonStyle())
                                .background(Color.clear)
                            }
                        }
                    }
                }
                if chatViewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
        }
        .padding()
    }
}
struct ChatPlaceholderView: View {
    var body: some View {
        Text("Nothing here yet")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
