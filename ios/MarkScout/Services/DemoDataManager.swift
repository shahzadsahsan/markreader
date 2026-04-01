import Foundation

/// Provides bundled sample data for testing in the simulator where iCloud Drive is unavailable.
class DemoDataManager {
    static let shared = DemoDataManager()

    private var sampleDataDir: URL? {
        Bundle.main.url(forResource: "SampleData", withExtension: nil)
    }

    var isAvailable: Bool { sampleDataDir != nil }

    func loadManifest() throws -> SyncManifest {
        guard let dir = sampleDataDir else { throw SyncError.manifestNotFound }
        let manifestURL = dir.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode(SyncManifest.self, from: data)
    }

    func readFileContent(relativePath: String) throws -> String {
        guard let dir = sampleDataDir else { throw SyncError.fileNotFound(relativePath) }
        let fileURL = dir.appendingPathComponent("files").appendingPathComponent(relativePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    func activate() {
        UserDefaults.standard.set(true, forKey: "demoMode")
    }

    var isActive: Bool {
        UserDefaults.standard.bool(forKey: "demoMode")
    }

    func deactivate() {
        UserDefaults.standard.removeObject(forKey: "demoMode")
    }
}
