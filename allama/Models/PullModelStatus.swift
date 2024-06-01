import Foundation

struct PullModelStatus: Codable {
    let status: String
    let digest: String?
    let total: Int?
    let completed: Int?
}
