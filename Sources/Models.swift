import Foundation

struct RcloneListResponse: Codable {
    let list: [RcloneItem]?
}

struct RcloneItem: Codable, Identifiable {
    let Path: String
    let Name: String
    let Size: Int64
    let MimeType: String
    let IsDir: Bool
    
    var id: String { Path }
}

struct RcloneRemote: Codable, Identifiable, Hashable {
    let name: String
    let type: String
    
    var id: String { name }
}

struct DumpResponse: Codable {
    // The keys are remote names, values are dictionaries with remote config
    // Actually config/dump returns a dictionary of dictionary
    // We'll decode it manually or just use a dynamic dictionary
}
