import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var folderSelected = false
    @State private var fileCount: Int?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingPicker = false

    let folderManager: SyncFolderManager
    let onComplete: (SyncManifest) -> Void

    @State private var pickerCoordinator: FolderPickerCoordinator?
    @State private var manifest: SyncManifest?

    var body: some View {
        TabView(selection: $currentStep) {
            // Step 1: Welcome
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.amber)
                Text("MarkScout for iOS")
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("A companion for your desktop\nmarkdown browser")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.body)
                Spacer()
                amberButton("Next") { currentStep = 1 }
                    .padding(.bottom, 48)
            }
            .tag(0)

            // Step 2: Enable Sync
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.amber)
                Text("Enable Sync on Your Mac")
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 12) {
                    stepRow(1, "Open MarkScout on your Mac")
                    stepRow(2, "Go to Preferences")
                    stepRow(3, "Enable iCloud Sync")
                }
                .padding(.horizontal, 32)
                Spacer()
                amberButton("Next") { currentStep = 2 }
                    .padding(.bottom, 48)
            }
            .tag(1)

            // Step 3: Select Folder
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.amber)
                Text("Select Your Sync Folder")
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("Navigate to iCloud Drive and select the MarkScout folder")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                if showError {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .padding(.horizontal, 32)
                }

                Spacer()
                amberButton("Select Folder") {
                    presentFolderPicker()
                }

                Button {
                    loadDemoData()
                } label: {
                    Text("Use Demo Data (Simulator)")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(Color.msMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .tag(2)

            // Step 4: Complete
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                Text("You're Set!")
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                if let count = fileCount {
                    Text("Found \(count) files")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                Spacer()
                amberButton("Open MarkScout") {
                    if let m = manifest {
                        onComplete(m)
                    }
                }
                .padding(.bottom, 48)
            }
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(Color(hex: "#0d0d0d"))
    }

    private func loadDemoData() {
        let demo = DemoDataManager.shared
        guard demo.isAvailable else {
            errorMessage = "SampleData not found in bundle"
            showError = true
            return
        }
        do {
            let m = try demo.loadManifest()
            demo.activate()
            onComplete(m)
        } catch {
            errorMessage = "Demo error: \(error)"
            showError = true
        }
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(.callout, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Color.amber)
                .clipShape(Circle())
            Text(text)
                .foregroundStyle(.white)
        }
    }

    private func amberButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.amber)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 32)
    }

    private func presentFolderPicker() {
        showError = false
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false

        let coordinator = FolderPickerCoordinator(folderManager: folderManager) { result in
            switch result {
            case .success(let pickerResult):
                manifest = pickerResult.manifest
                fileCount = pickerResult.manifest.fileCount
                folderSelected = true
                currentStep = 3
            case .failure(let error):
                if case SyncError.noBookmark = error {
                    // User cancelled — do nothing
                } else {
                    errorMessage = "No manifest.json found. Make sure sync is enabled on your Mac."
                    showError = true
                }
            }
        }
        picker.delegate = coordinator
        self.pickerCoordinator = coordinator // retain

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(picker, animated: true)
        }
    }
}

// MARK: - Color helpers

extension Color {
    static let amber = Color(hex: "#d4a04a")
    static let msBackground = Color(hex: "#0d0d0d")
    static let msSurface = Color(hex: "#161616")
    static let msBorder = Color(hex: "#2a2a2a")
    static let msText = Color(hex: "#e0e0e0")
    static let msMuted = Color(hex: "#888888")
    static let msActive = Color(hex: "#1e1e1e")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
