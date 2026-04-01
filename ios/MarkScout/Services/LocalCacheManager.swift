import Foundation
import CoreSpotlight
import MobileCoreServices

class LocalCacheManager {
    private let cacheDir: URL
    private let indexURL: URL
    private var index: [String: String] = [:] // relativePath → contentHash

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDir = docs.appendingPathComponent("cache")
        indexURL = cacheDir.appendingPathComponent("index.json")

        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        loadIndex()
    }

    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        index = decoded
    }

    private func saveIndex() {
        if let data = try? JSONEncoder().encode(index) {
            try? data.write(to: indexURL)
        }
    }

    private func cacheURL(for relativePath: String) -> URL {
        cacheDir.appendingPathComponent("files").appendingPathComponent(relativePath)
    }

    func cacheAllFiles(manifest: SyncManifest, folderManager: SyncFolderManager, progress: ((Int, Int) -> Void)? = nil) async {
        let total = manifest.files.count
        for (i, file) in manifest.files.enumerated() {
            progress?(i + 1, total)
            if isFileCached(relativePath: file.relativePath, contentHash: file.contentHash) { continue }
            do {
                let content = try await folderManager.readFileContent(relativePath: file.relativePath)
                let url = cacheURL(for: file.relativePath)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try content.write(to: url, atomically: true, encoding: .utf8)
                index[file.relativePath] = file.contentHash
            } catch {
                // Skip files that fail to cache
            }
        }
        // Prune files no longer in manifest
        let currentPaths = Set(manifest.files.map(\.relativePath))
        let removedPaths = Set(index.keys).subtracting(currentPaths)
        for path in removedPaths {
            try? FileManager.default.removeItem(at: cacheURL(for: path))
            index.removeValue(forKey: path)
        }
        saveIndex()

        // Index for Spotlight
        await indexForSpotlight(manifest: manifest, folderManager: folderManager)
    }

    func readCachedContent(relativePath: String) -> String? {
        try? String(contentsOf: cacheURL(for: relativePath), encoding: .utf8)
    }

    func isFileCached(relativePath: String, contentHash: String) -> Bool {
        index[relativePath] == contentHash
    }

    func totalCacheSize() -> UInt64 {
        let filesDir = cacheDir.appendingPathComponent("files")
        guard let enumerator = FileManager.default.enumerator(at: filesDir, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: UInt64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += UInt64(size)
            }
        }
        return total
    }

    func clearCache() throws {
        let filesDir = cacheDir.appendingPathComponent("files")
        try? FileManager.default.removeItem(at: filesDir)
        try FileManager.default.createDirectory(at: filesDir, withIntermediateDirectories: true)
        index = [:]
        saveIndex()
        CSSearchableIndex.default().deleteAllSearchableItems(completionHandler: nil)
    }

    var cachedFileCount: Int { index.count }

    var formattedCacheSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(totalCacheSize()), countStyle: .file)
    }

    // MARK: - Core Spotlight

    private func indexForSpotlight(manifest: SyncManifest, folderManager: SyncFolderManager) async {
        var items: [CSSearchableItem] = []
        for file in manifest.files {
            let content = readCachedContent(relativePath: file.relativePath) ?? ""
            let firstParagraph = String(content.prefix(200))

            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = file.name
            attributeSet.contentDescription = firstParagraph
            attributeSet.keywords = [file.project, "markdown", file.name]

            let item = CSSearchableItem(
                uniqueIdentifier: file.relativePath,
                domainIdentifier: "com.markscout.files",
                attributeSet: attributeSet
            )
            items.append(item)
        }
        try? await CSSearchableIndex.default().indexSearchableItems(items)

        // Remove items no longer in manifest
        let currentIds = Set(manifest.files.map(\.relativePath))
        let cachedIds = Set(index.keys)
        let removedIds = Array(cachedIds.subtracting(currentIds))
        if !removedIds.isEmpty {
            CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: removedIds, completionHandler: nil)
        }
    }
}
