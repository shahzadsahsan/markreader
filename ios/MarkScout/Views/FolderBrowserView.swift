import SwiftUI

struct FolderBrowserView: View {
    @Bindable var appState: AppState
    let folderManager: SyncFolderManager
    let cacheManager: LocalCacheManager

    private var projectGroups: [(project: String, files: [FileEntry])] {
        guard let manifest = appState.manifest else { return [] }
        let grouped = Dictionary(grouping: manifest.files, by: \.project)
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        List {
            ForEach(projectGroups, id: \.project) { group in
                DisclosureGroup {
                    ForEach(group.files) { file in
                        NavigationLink(value: file) {
                            FileRow(file: file, isFavorite: appState.isFavorite(file.relativePath))
                        }
                        .listRowBackground(Color.msSurface)
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(Color.amber)
                        Text(group.project)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.msText)
                        Spacer()
                        Text("\(group.files.count)")
                            .font(.caption)
                            .foregroundStyle(Color.msMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.msActive)
                            .clipShape(Capsule())
                    }
                }
                .listRowBackground(Color.msSurface)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.msBackground)
        .navigationTitle("Folders")
        .navigationBarTitleDisplayMode(.inline)
    }
}
