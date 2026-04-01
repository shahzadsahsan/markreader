import Foundation

struct SyncManifest: Codable {
    let version: Int
    let syncedAt: UInt64
    let fileCount: Int
    let totalSize: UInt64
    let files: [FileEntry]
    let favorites: [FavoriteEntry]

    enum CodingKeys: String, CodingKey {
        case version
        case syncedAt = "synced_at"
        case fileCount = "file_count"
        case totalSize = "total_size"
        case files, favorites
    }
}

struct FileEntry: Codable, Identifiable, Hashable {
    let relativePath: String
    let name: String
    let project: String
    let modifiedAt: UInt64
    let size: UInt64
    let contentHash: String

    var id: String { relativePath }

    enum CodingKeys: String, CodingKey {
        case relativePath = "relative_path"
        case name, project
        case modifiedAt = "modified_at"
        case size
        case contentHash = "content_hash"
    }

    var modifiedDate: Date {
        Date(timeIntervalSince1970: Double(modifiedAt) / 1000.0)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var wordCount: Int? { nil }

    var readingTimeMinutes: Int? { nil }
}

struct FavoriteEntry: Codable {
    let relativePath: String
    let contentHash: String
    let starredAt: UInt64

    enum CodingKeys: String, CodingKey {
        case relativePath = "relative_path"
        case contentHash = "content_hash"
        case starredAt = "starred_at"
    }
}
