import Foundation
import UIKit
import UniformTypeIdentifiers

class SyncFolderManager {
    private let bookmarkKey = "syncFolderBookmark"

    var hasSavedBookmark: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    func saveBookmark(for url: URL) throws {
        let data = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    func resolveBookmark() throws -> URL {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else {
            throw SyncError.noBookmark
        }
        var isStale = false
        let url = try URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        if isStale {
            throw SyncError.staleBookmark
        }
        return url
    }

    func readManifest() async throws -> SyncManifest {
        let folderURL = try resolveBookmark()
        guard folderURL.startAccessingSecurityScopedResource() else {
            throw SyncError.accessDenied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let manifestURL = folderURL.appendingPathComponent("manifest.json")
        try await ensureDownloaded(manifestURL)
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode(SyncManifest.self, from: data)
    }

    func readFileContent(relativePath: String) async throws -> String {
        let folderURL = try resolveBookmark()
        guard folderURL.startAccessingSecurityScopedResource() else {
            throw SyncError.accessDenied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileURL = folderURL.appendingPathComponent("files").appendingPathComponent(relativePath)
        try await ensureDownloaded(fileURL)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    /// Triggers download of an iCloud-evicted file and waits until it's available.
    private func ensureDownloaded(_ url: URL) async throws {
        let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
        if let status = values?.ubiquitousItemDownloadingStatus, status == .current {
            return
        }
        if FileManager.default.isReadableFile(atPath: url.path) {
            if let data = try? Data(contentsOf: url), !data.isEmpty { return }
        }
        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
        // Poll until available (up to 30s)
        for _ in 0..<60 {
            if FileManager.default.isReadableFile(atPath: url.path),
               let data = try? Data(contentsOf: url), !data.isEmpty {
                return
            }
            try await Task.sleep(for: .milliseconds(500))
        }
        throw SyncError.fileNotFound(url.lastPathComponent)
    }

    func isAccessible() -> Bool {
        guard let url = try? resolveBookmark() else { return false }
        guard url.startAccessingSecurityScopedResource() else { return false }
        defer { url.stopAccessingSecurityScopedResource() }
        let manifestURL = url.appendingPathComponent("manifest.json")
        return FileManager.default.fileExists(atPath: manifestURL.path)
    }

    func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }
}

enum SyncError: LocalizedError {
    case noBookmark
    case staleBookmark
    case accessDenied
    case manifestNotFound
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .noBookmark: return "No sync folder configured"
        case .staleBookmark: return "Sync folder access expired. Please re-select the folder."
        case .accessDenied: return "Cannot access sync folder"
        case .manifestNotFound: return "No manifest.json found in sync folder"
        case .fileNotFound(let path): return "File not found: \(path)"
        }
    }
}

// MARK: - Document Picker Coordinator

struct FolderPickerResult {
    let url: URL
    let manifest: SyncManifest
}

class FolderPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    let completion: (Result<FolderPickerResult, Error>) -> Void
    private let folderManager: SyncFolderManager

    init(folderManager: SyncFolderManager, completion: @escaping (Result<FolderPickerResult, Error>) -> Void) {
        self.folderManager = folderManager
        self.completion = completion
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        do {
            try folderManager.saveBookmark(for: url)
        } catch {
            completion(.failure(error))
            return
        }
        Task {
            do {
                let manifest = try await folderManager.readManifest()
                await MainActor.run {
                    completion(.success(FolderPickerResult(url: url, manifest: manifest)))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion(.failure(SyncError.noBookmark))
    }
}
