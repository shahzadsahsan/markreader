import SwiftUI
import CoreSpotlight

@main
struct MarkScoutApp: App {
    @State private var appState = AppState()
    @State private var folderManager = SyncFolderManager()
    @State private var cacheManager = LocalCacheManager()

    var body: some Scene {
        WindowGroup {
            ContentView(
                appState: appState,
                folderManager: folderManager,
                cacheManager: cacheManager
            )
            .preferredColorScheme(.dark)
            // Core Spotlight continuation
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                    appState.selectedFile = appState.manifest?.files.first { $0.relativePath == identifier }
                }
            }
            // Handoff continuation
            .onContinueUserActivity("com.markscout.viewing") { activity in
                if let path = activity.userInfo?["relativePath"] as? String {
                    appState.selectedFile = appState.manifest?.files.first { $0.relativePath == path }
                }
            }
        }
    }
}
