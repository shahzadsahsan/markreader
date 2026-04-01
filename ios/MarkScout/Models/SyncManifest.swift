import Foundation

struct SyncManifest: Codable {
    let version: Int
    let syncedAt: UInt64
    let fileCount: Int
    let totalSize: UInt64
    let files: [FileEntry]
    let favorites: [FavoriteEntry]
}

struct FileEntry: Codable, Identifiable, Hashable {
    let relativePath: String
    let name: String
    let project: String
    let modifiedAt: UInt64
    let size: UInt64
    let contentHash: String

    var id: String { relativePath }

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
}
