import Foundation
import Observation

enum FileSegment: String, CaseIterable {
    case allFiles = "All Files"
    case favorites = "Favorites"
}

enum CacheStatus: Equatable {
    case idle
    case caching(current: Int, total: Int)
    case cached
    case error(String)
}

@Observable
class AppState {
    var manifest: SyncManifest?
    var selectedFile: FileEntry?
    var searchQuery: String = ""
    var activeSegment: FileSegment = .allFiles
    var lastSyncCheck: Date?
    var isOffline: Bool = false
    var cacheStatus: CacheStatus = .idle

    // Reader preferences (persisted)
    var activePalette: PaletteId = {
        if let raw = UserDefaults.standard.string(forKey: "activePalette"),
           let p = PaletteId(rawValue: raw) {
            return p
        }
        return .parchmentDusk
    }() {
        didSet { UserDefaults.standard.set(activePalette.rawValue, forKey: "activePalette") }
    }

    var zoomLevel: Double = UserDefaults.standard.double(forKey: "zoomLevel").clamped(to: 0.8...2.0, default: 1.0) {
        didSet { UserDefaults.standard.set(zoomLevel, forKey: "zoomLevel") }
    }

    // Navigation context for swipe-to-next
    var navigationFileList: [FileEntry] = []
    var currentFileIndex: Int?

    // Reading position memory
    var readingPositions: [String: ReadingPosition] = {
        if let data = UserDefaults.standard.data(forKey: "readingPositions"),
           let positions = try? JSONDecoder().decode([String: ReadingPosition].self, from: data) {
            return positions
        }
        return [:]
    }() {
        didSet {
            if let data = try? JSONEncoder().encode(readingPositions) {
                UserDefaults.standard.set(data, forKey: "readingPositions")
            }
        }
    }

    // Onboarding
    var hasCompletedOnboarding: Bool {
        UserDefaults.standard.data(forKey: "syncFolderBookmark") != nil
    }

    func isFavorite(_ relativePath: String) -> Bool {
        manifest?.favorites.contains { $0.relativePath == relativePath } ?? false
    }

    var filteredFiles: [FileEntry] {
        guard let manifest else { return [] }

        var files: [FileEntry]
        switch activeSegment {
        case .allFiles:
            files = manifest.files.sorted { $0.modifiedAt > $1.modifiedAt }
        case .favorites:
            let favPaths = Set(manifest.favorites.map(\.relativePath))
            let favMap = Dictionary(uniqueKeysWithValues: manifest.favorites.map { ($0.relativePath, $0.starredAt) })
            files = manifest.files
                .filter { favPaths.contains($0.relativePath) }
                .sorted { (favMap[$0.relativePath] ?? 0) > (favMap[$1.relativePath] ?? 0) }
        }

        if !searchQuery.isEmpty {
            files = files.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return files
    }

    func saveReadingPosition(for path: String, percentage: Double, contentHash: String) {
        var positions = readingPositions
        positions[path] = ReadingPosition(percentage: percentage, contentHash: contentHash, lastRead: Date())
        // LRU eviction at 200
        if positions.count > 200 {
            let sorted = positions.sorted { $0.value.lastRead < $1.value.lastRead }
            for (key, _) in sorted.prefix(positions.count - 200) {
                positions.removeValue(forKey: key)
            }
        }
        readingPositions = positions
    }

    func readingPosition(for path: String, contentHash: String) -> Double? {
        guard let pos = readingPositions[path], pos.contentHash == contentHash else { return nil }
        return pos.percentage
    }
}

struct ReadingPosition: Codable {
    let percentage: Double
    let contentHash: String
    let lastRead: Date
}

extension Double {
    func clamped(to range: ClosedRange<Double>, default defaultValue: Double) -> Double {
        if self == 0 { return defaultValue }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
