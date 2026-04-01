import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState
    let folderManager: SyncFolderManager
    let cacheManager: LocalCacheManager

    @State private var hasLoadedManifest = false

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView(folderManager: folderManager) { manifest in
                    appState.manifest = manifest
                    appState.lastSyncCheck = Date()
                    appState.markOnboardingComplete()
                    hasLoadedManifest = true
                    Task {
                        appState.cacheStatus = .caching(current: 0, total: manifest.fileCount)
                        await cacheManager.cacheAllFiles(manifest: manifest, folderManager: folderManager) { current, total in
                            appState.cacheStatus = .caching(current: current, total: total)
                        }
                        appState.cacheStatus = .cached
                    }
                }
            } else {
                mainApp
            }
        }
        .task {
            // Auto-activate demo mode on simulator if no bookmark exists
            #if targetEnvironment(simulator)
            if !appState.hasCompletedOnboarding && DemoDataManager.shared.isAvailable {
                let demo = DemoDataManager.shared
                if let manifest = try? demo.loadManifest() {
                    demo.activate()
                    appState.manifest = manifest
                    appState.lastSyncCheck = Date()
                    appState.cacheStatus = .cached
                    appState.markOnboardingComplete()
                    hasLoadedManifest = true
                    return
                }
            }
            #endif
            guard appState.hasCompletedOnboarding, !hasLoadedManifest else { return }
            await loadManifest()
        }
    }

    @ViewBuilder
    private var mainApp: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadLayout
        } else {
            iPhoneLayout
        }
    }

    private var iPhoneLayout: some View {
        NavigationStack {
            FileListView(appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                .navigationDestination(for: FileEntry.self) { file in
                    FileDetailView(file: file, appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                        .onAppear {
                            appState.selectedFile = file
                            appState.currentFileIndex = appState.filteredFiles.firstIndex(of: file)
                            appState.navigationFileList = appState.filteredFiles
                        }
                }
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "folders":
                        FolderBrowserView(appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                            .navigationDestination(for: FileEntry.self) { file in
                                FileDetailView(file: file, appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                            }
                    case "settings":
                        SettingsView(appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                    default:
                        EmptyView()
                    }
                }
        }
        .tint(Color.amber)
        .overlay {
            cachingOverlay
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            FileListView(appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "folders":
                        FolderBrowserView(appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                    case "settings":
                        SettingsView(appState: appState, folderManager: folderManager, cacheManager: cacheManager)
                    default:
                        EmptyView()
                    }
                }
        } detail: {
            if let file = appState.selectedFile {
                FileDetailView(file: file, appState: appState, folderManager: folderManager, cacheManager: cacheManager)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.msMuted)
                    Text("Select a file to read")
                        .font(.system(.title3, design: .monospaced))
                        .foregroundStyle(Color.msMuted)
                }
            }
        }
        .tint(Color.amber)
        .overlay {
            cachingOverlay
        }
    }

    @ViewBuilder
    private var cachingOverlay: some View {
        if case .caching(let current, let total) = appState.cacheStatus {
            VStack(spacing: 12) {
                ProgressView(value: Double(current), total: Double(total))
                    .tint(Color.amber)
                Text("Caching files for offline use... \(current)/\(total)")
                    .font(.caption)
                    .foregroundStyle(Color.msMuted)
            }
            .padding(24)
            .background(Color.msSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 20)
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func loadManifest() async {
        if DemoDataManager.shared.isActive {
            if let manifest = try? DemoDataManager.shared.loadManifest() {
                appState.manifest = manifest
                appState.lastSyncCheck = Date()
                appState.cacheStatus = .cached
            }
            hasLoadedManifest = true
            return
        }
        do {
            let manifest = try await folderManager.readManifest()
            appState.manifest = manifest
            appState.isOffline = false
            appState.lastSyncCheck = Date()
            hasLoadedManifest = true
            await cacheManager.cacheAllFiles(manifest: manifest, folderManager: folderManager)
            appState.cacheStatus = .cached
        } catch {
            appState.isOffline = true
            hasLoadedManifest = true
        }
    }
}
