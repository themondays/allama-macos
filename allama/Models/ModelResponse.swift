import Foundation

struct ModelResponse: Codable {
    let models: [Model]
}

struct Model: Codable {
    let name: String
    let model: String
    let modified_at: String
    let size: Int
    let digest: String
    let details: ModelDetails
    let expires_at: String
}

struct ModelDetails: Codable {
    let parent_model: String
    let format: String
    let family: String
    let families: [String]?
    let parameter_size: String
    let quantization_level: String
}

extension Model {
    var sizeInGigabytes: String {
        let gigabytes = Double(size) / pow(1024.0, 3.0)
        return String(format: "%.2f GB", floor(gigabytes * 100) / 100)
    }
}
