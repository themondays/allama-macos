import Foundation

struct ChatResponse: Codable {
    let model: String
    let created_at: String
    let message: ChatMessage
    let done: Bool
}
