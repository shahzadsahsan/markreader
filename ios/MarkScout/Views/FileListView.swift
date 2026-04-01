import SwiftUI

struct FileListView: View {
    @Bindable var appState: AppState
    let folderManager: SyncFolderManager
    let cacheManager: LocalCacheManager

    @State private var isRefreshing = false

    var body: some View {
        List {
            if appState.filteredFiles.isEmpty {
                emptyState
            } else {
                ForEach(appState.filteredFiles) { file in
                    NavigationLink(value: file) {
                        FileRow(file: file, isFavorite: appState.isFavorite(file.relativePath))
                    }
                    .listRowBackground(Color.msSurface)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.msBackground)
        .searchable(text: $appState.searchQuery, prompt: "Search files")
        .refreshable {
            await refreshManifest()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                syncStatusView
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    NavigationLink(value: "folders") {
                        Image(systemName: "folder")
                            .foregroundStyle(Color.msMuted)
                    }
                    NavigationLink(value: "settings") {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.msMuted)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            segmentPicker
        }
    }

    private var segmentPicker: some View {
        Picker("", selection: $appState.activeSegment) {
            ForEach(FileSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.msBackground)
    }

    private var syncStatusView: some View {
        Group {
            if appState.isOffline {
                Label("Offline — cached data", systemImage: "wifi.slash")
                    .font(.caption)
                    .foregroundStyle(Color.msMuted)
            } else if let lastSync = appState.lastSyncCheck {
                Text("Synced \(lastSync, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(Color.msMuted)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(Color.msMuted)
            Text("No files synced yet")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(Color.msText)
            Text("Make sure sync is enabled on your Mac in MarkScout Preferences.")
                .foregroundStyle(Color.msMuted)
                .multilineTextAlignment(.center)
                .font(.callout)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func refreshManifest() async {
        do {
            let manifest = try folderManager.readManifest()
            appState.manifest = manifest
            appState.isOffline = false
            appState.lastSyncCheck = Date()
            await cacheManager.cacheAllFiles(manifest: manifest, folderManager: folderManager)
            appState.cacheStatus = .cached
        } catch {
            appState.isOffline = true
        }
    }
}

struct FileRow: View {
    let file: FileEntry
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(file.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.msText)
                    .lineLimit(1)
                Spacer()
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Color.amber)
                }
            }
            HStack(spacing: 8) {
                Text(file.project)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.amber.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.amber.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Text(file.modifiedDate, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(Color.msMuted)

                Spacer()

                Text(file.formattedSize)
                    .font(.caption2)
                    .foregroundStyle(Color.msMuted)
            }
        }
        .padding(.vertical, 4)
    }
}
