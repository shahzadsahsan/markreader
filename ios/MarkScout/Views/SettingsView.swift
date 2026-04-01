import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    let folderManager: SyncFolderManager
    let cacheManager: LocalCacheManager

    @State private var showClearConfirm = false
    @State private var showFolderPicker = false
    @State private var pickerCoordinator: FolderPickerCoordinator?

    var body: some View {
        List {
            // Sync Folder
            Section {
                HStack {
                    Label("Sync Folder", systemImage: "folder")
                        .foregroundStyle(Color.msText)
                    Spacer()
                    Text("iCloud/MarkScout")
                        .font(.caption)
                        .foregroundStyle(Color.msMuted)
                }
                .listRowBackground(Color.msSurface)

                Button("Change Sync Folder") {
                    changeSyncFolder()
                }
                .foregroundStyle(Color.amber)
                .listRowBackground(Color.msSurface)
            } header: {
                Text("Sync")
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
