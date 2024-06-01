import Foundation


struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRecord: Codable {
    let role: String
    let timestamp: String
    let model: String
    let content: String
}
