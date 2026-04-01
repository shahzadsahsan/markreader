import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    let folderManager: SyncFolderManager
    let cacheManager: LocalCacheManager

    @State private var showClearConfirm = false
    @State private var showResetConfirm = false
    @State private var showFolderPicker = false
    @State private var pickerCoordinator: FolderPickerCoordinator?
    @State private var isDownloadingAll = false
    @State private var downloadProgress: (current: Int, total: Int) = (0, 0)
    @State private var downloadError: String?

    private var isInDemoMode: Bool { DemoDataManager.shared.isActive }

    var body: some View {
        List {
            // Demo mode banner
            if isInDemoMode {
                Section {
                    HStack {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundStyle(Color.amber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Demo Mode Active")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.msText)
                            Text("Using bundled sample data. Switch to your real iCloud sync folder below.")
                                .font(.caption)
                                .foregroundStyle(Color.msMuted)
                        }
                    }
                    .listRowBackground(Color.amber.opacity(0.1))

                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Switch to Real Sync Folder", systemImage: "icloud.and.arrow.down")
                    }
                    .foregroundStyle(Color.amber)
                    .listRowBackground(Color.msSurface)
                } header: {
                    Text("Mode")
                        .foregroundStyle(Color.msMuted)
                }
            }

            // Sync Folder
            Section {
                HStack {
                    Label("Sync Folder", systemImage: "folder")
                        .foregroundStyle(Color.msText)
                    Spacer()
                    if isInDemoMode {
                        Text("Demo Data")
                            .font(.caption)
                            .foregroundStyle(Color.amber)
                    } else {
                        Text("iCloud/MarkScout")
                            .font(.caption)
                            .foregroundStyle(Color.msMuted)
                    }
                }
                .listRowBackground(Color.msSurface)

                if !isInDemoMode {
                    Button("Change Sync Folder") {
                        changeSyncFolder()
                    }
                    .foregroundStyle(Color.amber)
                    .listRowBackground(Color.msSurface)

                    if isDownloadingAll {
                        HStack {
                            Label("Downloading...", systemImage: "arrow.down.circle")
                                .foregroundStyle(Color.msText)
                            Spacer()
                            if downloadProgress.total > 0 {
                                Text("\(downloadProgress.current)/\(downloadProgress.total)")
                                    .font(.caption)
                                    .foregroundStyle(Color.msMuted)
                            }
                        }
                        .listRowBackground(Color.msSurface)
                        ProgressView(value: Double(downloadProgress.current), total: max(1, Double(downloadProgress.total)))
                            .tint(Color.amber)
                            .listRowBackground(Color.msSurface)
                    } else {
                        Button {
                            downloadAllFiles()
                        } label: {
                            Label("Download All Files", systemImage: "arrow.down.circle")
                        }
                        .foregroundStyle(Color.amber)
                        .listRowBackground(Color.msSurface)
                    }

                    if let error = downloadError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .listRowBackground(Color.msSurface)
                    }
                }

                if let manifest = appState.manifest {
                    HStack {
                        Label("Files", systemImage: "doc.text")
                            .foregroundStyle(Color.msText)
                        Spacer()
                        Text("\(manifest.fileCount) files")
                            .font(.caption)
                            .foregroundStyle(Color.msMuted)
                    }
                    .listRowBackground(Color.msSurface)
                }
            } header: {
                Text("Sync")
                    .foregroundStyle(Color.msMuted)
            }

            // Filters
            Section {
                HStack {
                    Label("File Count", systemImage: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color.msText)
                    Spacer()
                    Text("\(appState.filteredFiles.count) shown")
                        .font(.caption)
                        .foregroundStyle(Color.msMuted)
                }
                .listRowBackground(Color.msSurface)

                if let manifest = appState.manifest {
                    let projects = Set(manifest.files.map(\.project)).sorted()
                    ForEach(projects, id: \.self) { project in
                        let count = manifest.files.filter { $0.project == project }.count
                        HStack {
                            Text(project)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(Color.msText)
                            Spacer()
                            Text("\(count) files")
                                .font(.caption)
                                .foregroundStyle(Color.msMuted)
                        }
                        .listRowBackground(Color.msSurface)
                    }
                }
            } header: {
                Text("Filters")
                    .foregroundStyle(Color.msMuted)
            }

            // Theme
            Section {
                NavigationLink {
                    PalettePickerSheet(selectedPalette: $appState.activePalette)
                } label: {
                    HStack {
                        Label("Theme", systemImage: "paintpalette")
                            .foregroundStyle(Color.msText)
                        Spacer()
                        Text(palette(for: appState.activePalette).label)
                            .font(.caption)
                            .foregroundStyle(Color.msMuted)
                    }
                }
                .listRowBackground(Color.msSurface)
            } header: {
                Text("Appearance")
                    .foregroundStyle(Color.msMuted)
            }

            // Cache
            Section {
                HStack {
                    Label("Cache Size", systemImage: "internaldrive")
                        .foregroundStyle(Color.msText)
                    Spacer()
                    Text(cacheManager.formattedCacheSize)
                        .font(.caption)
                        .foregroundStyle(Color.msMuted)
                }
                .listRowBackground(Color.msSurface)

                HStack {
                    Label("Cached Files", systemImage: "doc.on.doc")
                        .foregroundStyle(Color.msText)
                    Spacer()
                    Text("\(cacheManager.cachedFileCount)")
                        .font(.caption)
                        .foregroundStyle(Color.msMuted)
                }
                .listRowBackground(Color.msSurface)

                Button("Clear Cache") {
                    showClearConfirm = true
                }
                .foregroundStyle(.red)
                .listRowBackground(Color.msSurface)
            } header: {
                Text("Storage")
                    .foregroundStyle(Color.msMuted)
            }

            // About
            Section {
                HStack {
                    Label("Version", systemImage: "info.circle")
                        .foregroundStyle(Color.msText)
                    Spacer()
                    Text("MarkScout for iOS v1.0.0")
                        .font(.caption)
                        .foregroundStyle(Color.msMuted)
                }
                .listRowBackground(Color.msSurface)
            } header: {
                Text("About")
                    .foregroundStyle(Color.msMuted)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.msBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Cache", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                try? cacheManager.clearCache()
            }
        } message: {
            Text("This will remove all cached files. They will be re-downloaded when you refresh.")
        }
        .alert("Switch to Real Sync", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Switch") {
                exitDemoMode()
            }
        } message: {
            Text("This will exit demo mode and take you back to the folder picker so you can select your iCloud MarkScout folder.")
        }
    }

    private func exitDemoMode() {
        DemoDataManager.shared.deactivate()
        folderManager.clearBookmark()
        appState.manifest = nil
        appState.onboardingCompleted = false
    }

    private func downloadAllFiles() {
        guard let manifest = appState.manifest else { return }
        guard !isInDemoMode else {
            downloadError = "Download is not available in demo mode. Switch to a real sync folder first."
            return
        }
        guard folderManager.hasSavedBookmark else {
            downloadError = "No sync folder configured. Please select a folder first."
            return
        }
        isDownloadingAll = true
        downloadError = nil
        downloadProgress = (0, manifest.fileCount)
        Task {
            let downloaded = await folderManager.downloadAllFiles(manifest: manifest) { current, total in
                Task { @MainActor in
                    downloadProgress = (current, total)
                }
            }
            await MainActor.run {
                isDownloadingAll = false
                if downloaded == 0 {
                    downloadError = "Failed to download files. Check your internet connection and make sure iCloud Drive is enabled."
                } else if downloaded < manifest.fileCount {
                    downloadError = "Downloaded \(downloaded)/\(manifest.fileCount) files. Some files may still be syncing."
                } else {
                    downloadError = nil
                    appState.cacheStatus = .cached
                }
            }
            // Also update the local cache
            if downloaded > 0 {
                await cacheManager.cacheAllFiles(manifest: manifest, folderManager: folderManager)
                await MainActor.run {
                    appState.cacheStatus = .cached
                }
            }
        }
    }

    private func changeSyncFolder() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false

        let coordinator = FolderPickerCoordinator(folderManager: folderManager) { result in
            if case .success(let pickerResult) = result {
                appState.manifest = pickerResult.manifest
                appState.lastSyncCheck = Date()
            }
        }
        picker.delegate = coordinator
        self.pickerCoordinator = coordinator

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(picker, animated: true)
        }
    }
}
