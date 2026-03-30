# MarkScout iOS Companion App — Design Spec

## Overview

A SwiftUI iOS app (iOS 17+, iPhone + iPad) that reads from the MarkScout iCloud Drive folder and provides an offline-capable markdown reading experience. The desktop Tauri app syncs filtered `.md` files and a `manifest.json` to `iCloud Drive > MarkScout/`. The iOS app is a **read-only companion** — it never writes to iCloud Drive.

**Location:** `ios/` directory inside the existing `markreader` repo.

**Tech stack:** SwiftUI, WKWebView (via UIViewRepresentable), no external dependencies.

**Deployment target:** iOS 17+, iPhone + iPad.

---

## iCloud Folder Contract

The desktop app writes to:

```
~/Library/Mobile Documents/com~apple~CloudDocs/MarkScout/
├── manifest.json          # Index of all synced files + favorites
└── files/                 # Mirror of filtered .md files
    ├── markreader/
    │   ├── ARCHITECTURE.md
    │   └── REQUIREMENTS.md
    └── .claude/
        └── memory/
            └── project-context.md
```

### manifest.json Schema

```json
{
  "version": 1,
  "synced_at": 1711701600000,
  "file_count": 247,
  "total_size": 2048000,
  "files": [
    {
      "relative_path": "markreader/ARCHITECTURE.md",
      "name": "ARCHITECTURE",
      "project": "markreader",
      "modified_at": 1711701600000,
      "size": 4096,
      "content_hash": "a1b2c3..."
    }
  ],
  "favorites": [
    {
      "relative_path": "markreader/REQUIREMENTS.md",
      "content_hash": "d4e5f6...",
      "starred_at": 1711701600000
    }
  ]
}
```

All timestamps are Unix epoch milliseconds. `content_hash` is SHA-256 of first 1024 bytes + file size. The desktop already filters files by a size threshold (default 512KB), so everything in `files/` is guaranteed to be under that limit.

---

## Xcode Project Structure

```
ios/
├── MarkScout.xcodeproj
├── MarkScout/
│   ├── App/
│   │   ├── MarkScoutApp.swift           # @main, onboarding gate, state init
│   │   └── ContentView.swift            # Root: onboarding or main app
│   ├── Models/
│   │   ├── SyncManifest.swift           # Codable structs matching manifest.json
│   │   └── AppState.swift               # @Observable, holds manifest, selection, cache status
│   ├── Services/
│   │   ├── SyncFolderManager.swift      # Security-scoped bookmark, folder access, file enumeration
│   │   ├── MarkdownRenderer.swift       # WKWebView wrapper, CSS/font injection, theme support
│   │   └── LocalCacheManager.swift      # Copies iCloud files to app sandbox for offline
│   ├── Views/
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift     # 4-step onboarding wizard
│   │   ├── FileListView.swift           # Main file list with search + segments
│   │   ├── FileDetailView.swift         # Markdown reader with toolbar
│   │   ├── FolderBrowserView.swift      # Tree view grouped by project
│   │   └── SettingsView.swift           # Sync folder, cache, app version
│   └── Resources/
│       ├── reader.html                  # Standalone HTML template for WKWebView
│       ├── reader.css                   # Full reader stylesheet with palette variables
│       ├── JetBrainsMono-Regular.woff2  # Heading + code font
│       ├── SourceSerif4-Regular.woff2   # Body prose font
│       ├── highlight.min.js             # Code syntax highlighting
│       └── github-dark.min.css          # highlight.js theme
└── MarkScoutTests/
    └── SyncManifestTests.swift          # Manifest parsing tests
```

---

## Models

### SyncManifest.swift

Codable structs matching the manifest.json schema. All field names use `snake_case` with `CodingKeys` or `keyDecodingStrategy = .convertFromSnakeCase`.

```swift
struct SyncManifest: Codable {
    let version: Int
    let syncedAt: UInt64
    let fileCount: Int
    let totalSize: UInt64
    let files: [FileEntry]
    let favorites: [FavoriteEntry]
}

struct FileEntry: Codable, Identifiable {
    let relativePath: String
    let name: String
    let project: String
    let modifiedAt: UInt64
    let size: UInt64
    let contentHash: String

    var id: String { relativePath }
}

struct FavoriteEntry: Codable {
    let relativePath: String
    let contentHash: String
    let starredAt: UInt64
}
```

### AppState.swift

`@Observable` class (iOS 17 Observation framework). Holds the current manifest, selected file, navigation context, and user preferences.

```swift
@Observable
class AppState {
    var manifest: SyncManifest?
    var selectedFile: FileEntry?
    var searchQuery: String = ""
    var activeSegment: FileSegment = .allFiles  // .allFiles | .favorites
    var lastSyncCheck: Date?
    var isOffline: Bool = false
    var cacheStatus: CacheStatus = .idle

    // Reader preferences (persisted in UserDefaults)
    var activePalette: PaletteId = .parchmentDusk
    var zoomLevel: Double = 1.0

    // Navigation context for swipe-to-next
    var navigationFileList: [FileEntry] = []
    var currentFileIndex: Int?

    // Computed
    var isFavorite: (String) -> Bool  // checks manifest.favorites by relativePath
    var filteredFiles: [FileEntry]    // applies searchQuery + segment filter
}
```

---

## Services

### SyncFolderManager

Handles the security-scoped bookmark lifecycle and all file access to the iCloud Drive folder.

**Responsibilities:**
- Present `UIDocumentPickerViewController` (folder mode) for initial folder selection
- Create a minimal security-scoped bookmark from the selected URL, store in UserDefaults
- On app launch: resolve bookmark, check `isStale`, re-prompt if needed
- Always bracket file reads with `url.startAccessingSecurityScopedResource()` / `url.stopAccessingSecurityScopedResource()`
- Read and decode `manifest.json`
- Read individual `.md` file content by `relativePath`
- Check folder accessibility (for offline detection)

**Key API:**
```swift
class SyncFolderManager {
    var hasSavedBookmark: Bool
    func presentFolderPicker() -> URL?
    func saveBookmark(for url: URL) throws
    func resolveBookmark() throws -> URL  // re-prompts if stale
    func readManifest() throws -> SyncManifest
    func readFileContent(relativePath: String) throws -> String
    func isAccessible() -> Bool
}
```

### LocalCacheManager

Copies downloaded iCloud files to the app's `Documents/cache/` directory for offline reading.

**Responsibilities:**
- On first manifest load: cache all files from `files/` to app sandbox
- Store a local index mapping `relativePath → contentHash` for change detection
- On refresh: compare manifest `contentHash` against cached hash, re-download changed files
- Provide `readCachedContent(relativePath:)` for offline reads
- Calculate total cache size for Settings display
- Clear cache on demand

**Key API:**
```swift
class LocalCacheManager {
    func cacheAllFiles(manifest: SyncManifest, folderManager: SyncFolderManager) async
    func readCachedContent(relativePath: String) -> String?
    func isFileCached(relativePath: String, contentHash: String) -> Bool
    func totalCacheSize() -> UInt64
    func clearCache() throws
}
```

### MarkdownRenderer

UIViewRepresentable wrapping WKWebView. Loads markdown content into the bundled `reader.html` template with fonts and syntax highlighting.

**Responsibilities:**
- Create WKWebView with `baseURL` pointing to app bundle (so `@font-face` paths resolve)
- Load `reader.html` template, inject markdown content as pre-rendered HTML (using a lightweight Swift markdown→HTML conversion, or passing raw markdown and letting a bundled JS lib handle it)
- Apply active palette by setting CSS custom properties via JavaScript
- Apply zoom level by setting `font-size` on the root element
- Disable WKWebView's native link navigation (open links in Safari instead)
- Disable bouncing/overscroll to not interfere with swipe gestures

**Markdown rendering approach:** Bundle a small JavaScript markdown parser (marked.js, ~50KB) in the app resources alongside highlight.js. The `reader.html` template receives raw markdown via a JS bridge call, parses it client-side, and renders into the styled container. This avoids needing a Swift-side markdown library.

**Key API:**
```swift
struct MarkdownWebView: UIViewRepresentable {
    let markdownContent: String
    let palette: Palette
    let zoomLevel: Double
    func makeUIView(context:) -> WKWebView
    func updateUIView(_ webView:, context:)
}
```

---

## Screens

### 1. OnboardingView (first launch only)

4-step wizard shown only when no security-scoped bookmark exists in UserDefaults.

**Step 1 — Welcome:**
- App icon centered
- "MarkScout for iOS"
- "A companion for your desktop markdown browser"
- "Next" button (amber)

**Step 2 — Enable Sync:**
- Sync icon
- "Enable Sync on Your Mac"
- Step-by-step instructions:
  1. Open MarkScout on your Mac
  2. Go to Preferences
  3. Enable iCloud Sync
- "Next" button

**Step 3 — Select Folder:**
- Folder icon
- "Select Your Sync Folder"
- "Select Folder" button → opens `UIDocumentPickerViewController` for `.folder` content type
- User navigates to `iCloud Drive > MarkScout` and selects it
- On selection: create security-scoped bookmark, store in UserDefaults
- If manifest.json is not found in selected folder: show inline error "No manifest.json found. Make sure sync is enabled on your Mac."

**Step 4 — Complete:**
- Checkmark icon
- "You're Set!"
- Shows file count from manifest: "Found 247 files"
- "Open MarkScout" button → dismisses onboarding, enters main app

**Design:** Dark background (#0d0d0d), amber accent buttons, centered layout. `TabView` with `.tabViewStyle(.page)` for swipeable steps.

### 2. FileListView (main screen)

The primary screen after onboarding. Shows all synced files.

**Layout:**
- **iPad:** `NavigationSplitView` — FileListView as sidebar, FileDetailView as detail pane
- **iPhone:** `NavigationStack` — FileListView pushes to FileDetailView

**Toolbar:**
- Search field (filters by file name, case-insensitive)
- Sync status: "Synced 2m ago" or "Offline — showing cached data"
- Folder icon → navigates to FolderBrowserView
- Gear icon → navigates to SettingsView

**Segmented control:** `All Files` | `Favorites`
- All Files: every file from manifest, sorted by `modifiedAt` descending
- Favorites: only files whose `relativePath` appears in `manifest.favorites`, sorted by `starredAt` descending

**File rows:**
- File name (bold)
- Project badge (tinted, e.g., "markreader" in green)
- Relative time ("2m ago", "1h ago", "3d ago")
- Star indicator (amber ★) if favorited

**Pull-to-refresh:** Re-reads `manifest.json` from iCloud, updates file list and cache.

**Empty state:** "No files synced yet. Make sure sync is enabled on your Mac." with a subtitle explaining the steps.

**Navigation:** Tapping a file row:
- Sets `appState.selectedFile`
- Captures the current filtered/sorted file list into `appState.navigationFileList` (for swipe-to-next)
- Pushes `FileDetailView`

### 3. FileDetailView (markdown reader)

Full-screen markdown reading experience.

**Header (above WKWebView):**
- File name
- Project name · Modified time · Word count · Reading time estimate

**WKWebView (fills remaining space):**
- Loads bundled `reader.html` with markdown content
- Full-width content with comfortable padding (16px iPhone, 24px iPad)
- Active palette applied via CSS custom properties
- Zoom level applied via root `font-size` scaling

**Toolbar buttons:**
- A−/A+ zoom controls (0.8x → 2.0x in 0.1 increments)
- Theme picker button → sheet/popover with palette grid
- Star indicator (amber ★ when favorited — read-only, reflects manifest data, not interactive)
- Share button (shares the `.md` file via `UIActivityViewController`)

**Swipe gestures:**
- **Swipe right** (finger left→right): Native iOS back gesture, pops to FileListView. Handled automatically by NavigationStack.
- **Swipe left** (finger right→left): Advance to next file in `navigationFileList`. Custom `UISwipeGestureRecognizer` on the detail view. Stops at end of list (no wrap).

**Context-aware file order:** The `navigationFileList` is captured at navigation time, so:
- Coming from "All Files" → sorted by `modifiedAt` descending
- Coming from "Favorites" → only favorites, sorted by `starredAt`
- Coming from FolderBrowserView → only files in that project

### 4. FolderBrowserView

Accessible from a toolbar button on FileListView. Tree view of files grouped by project.

**Layout:**
- `List` with `DisclosureGroup` for each project
- Project header: project name + file count badge
- File rows: same design as FileListView rows
- Tapping a file navigates to FileDetailView (with folder-scoped `navigationFileList`)

### 5. SettingsView

Accessible from a toolbar button on FileListView.

**Sections:**
- **Sync Folder:** Current folder path display
- **Change Sync Folder:** Button → re-opens folder picker, updates bookmark
- **Theme:** Current palette name, tappable to open palette picker
- **Cache:** Total cache size (e.g., "12.4 MB") + "Clear Cache" button
- **About:** App version, "MarkScout for iOS v1.0.0"

---

## Theme / Palette System

All 16 desktop palettes are carried over to iOS. Each palette is a dictionary of CSS custom property overrides injected into the WKWebView.

### Palette Registry

```swift
enum PaletteId: String, CaseIterable, Codable {
    case parchmentDusk, deepOcean, rosewood, terminalGreen
    case warmPaper, nordFrost, monokai, solarizedDark
    case catppuccin, synthwave, dracula, tokyoNight
    case daylight, sepiaLight, arctic, sakura
}

struct Palette {
    let id: PaletteId
    let label: String
    let category: String  // "Dark Warm", "Dark Cool", "Dark Vibrant", "Light"
    let vars: [String: String]  // CSS custom property name → value
}
```

### Categories (for grouped picker)

| Category | Palettes |
|----------|----------|
| Dark Warm | Parchment Dusk, Rosewood, Warm Paper |
| Dark Cool | Deep Ocean, Nord Frost, Solarized, Dracula, Tokyo Night |
| Dark Vibrant | Terminal, Monokai, Catppuccin, Synthwave |
| Light | Daylight, Sepia, Arctic, Sakura |

### Palette Picker UI

Presented as a sheet (iPhone) or popover (iPad) from the theme button in the reader toolbar. Grid of palette swatches grouped by category, each showing a small color preview (background + heading color). Active palette has an amber checkmark.

### Application

On WKWebView load and on palette change, inject CSS variables via JavaScript:

```javascript
document.documentElement.style.setProperty('--bg', '#0b1022');
document.documentElement.style.setProperty('--text', '#cdd6e4');
// ... all vars from the palette
```

Selected palette stored in `UserDefaults` under key `"activePalette"`.

---

## Zoom & Readability

**A−/A+ buttons:** Step zoom from 0.8x to 2.0x in 0.1 increments. Applied by setting the WKWebView's root element `font-size` via JavaScript:

```javascript
document.documentElement.style.fontSize = `calc(18px * ${zoomLevel})`;
```

**Pinch-to-zoom:** WKWebView supports this natively. Set `webView.scrollView.minimumZoomScale` / `maximumZoomScale` appropriately. May want to disable to avoid conflict with manual zoom — evaluate during implementation.

**Double-tap:** Toggle between 1.0x and last non-1.0x zoom level. Implemented via `UITapGestureRecognizer` with `numberOfTapsRequired = 2`.

**Zoom persistence:** Current zoom level stored in `UserDefaults` under key `"zoomLevel"`.

**Content width:** Full device width with padding (16px on iPhone, 24px on iPad). No 720px max-width cap — the desktop's fill-screen concept doesn't apply on mobile.

---

## Offline Behavior

### Initial Cache

On first manifest load after onboarding, cache all files:

1. Read `manifest.json` from iCloud
2. For each file in `manifest.files`: read content from `files/{relativePath}`, write to `Documents/cache/{relativePath}`
3. Store a local index at `Documents/cache/index.json` mapping `relativePath → contentHash`
4. Show progress indicator during initial cache ("Caching files for offline use... 142/247")

### Refresh

On pull-to-refresh or app foreground:

1. Attempt to read `manifest.json` from iCloud
2. If successful: compare each file's `contentHash` against cached index
3. Re-download any files with changed hashes
4. Remove cached files no longer in manifest
5. Update `lastSyncCheck` timestamp

### Offline Mode

If iCloud folder is inaccessible (no network, iCloud signed out):

1. Set `appState.isOffline = true`
2. Show "Offline — showing cached data" in the status bar (muted text, not alarming)
3. Load file list from cached index instead of manifest
4. Read all content from local cache
5. Hide pull-to-refresh (or show "Can't refresh while offline")
6. When connectivity returns, auto-refresh on next app foreground

---

## Security-Scoped Bookmark Flow

```
First launch:
1. UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
2. User selects iCloud Drive > MarkScout
3. url.startAccessingSecurityScopedResource()
4. Create bookmark: url.bookmarkData(options: .minimalBookmark)
5. Store bookmark in UserDefaults (key: "syncFolderBookmark")
6. Read manifest.json to validate
7. url.stopAccessingSecurityScopedResource()

Subsequent launches:
1. Read bookmark from UserDefaults
2. URL(resolvingBookmarkData:bookmarkDataIsStale:)
3. If stale: re-prompt with folder picker
4. url.startAccessingSecurityScopedResource()
5. Read manifest, access files
6. url.stopAccessingSecurityScopedResource() when done
```

Always use `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()` pairs. Never leave a scoped resource open longer than needed.

---

## Bundled Resources

### reader.html

A standalone HTML template that receives markdown content and renders it with the desktop's visual style.

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <link rel="stylesheet" href="reader.css">
  <link rel="stylesheet" href="github-dark.min.css">
  <script src="highlight.min.js"></script>
  <script src="marked.min.js"></script>
</head>
<body>
  <article id="content"></article>
  <script>
    function renderMarkdown(raw) {
      document.getElementById('content').innerHTML = marked.parse(raw);
      document.querySelectorAll('pre code').forEach(el => hljs.highlightElement(el));
    }
    function setPalette(vars) {
      for (const [k, v] of Object.entries(vars)) {
        document.documentElement.style.setProperty(k, v);
      }
    }
    function setZoom(level) {
      document.documentElement.style.fontSize = `calc(18px * ${level})`;
    }
  </script>
</body>
</html>
```

### reader.css

Port of the desktop's `globals.css` prose styling:

- Default palette variables (Parchment Dusk as default)
- `@font-face` for JetBrains Mono and Source Serif 4 (referencing bundled `.woff2`)
- Body: Source Serif 4, 18px, line-height 1.7, full-width with padding
- Headings: JetBrains Mono, h1 with amber border-bottom
- Code blocks: `#111` background, 14px JetBrains Mono, rounded corners
- Blockquotes: amber left border, subtle background
- Tables: zebra-striped, sticky headers
- Task lists: custom checkboxes
- Links: amber on hover

### Fonts

- `JetBrainsMono-Regular.woff2` — headings and code
- `SourceSerif4-Regular.woff2` — body prose

### Syntax Highlighting

- `highlight.min.js` — core library (auto-detect common languages)
- `github-dark.min.css` — dark theme (works with light palettes too since code-bg is overridden per palette)

### Markdown Parser

- `marked.min.js` — lightweight client-side markdown parser (~50KB). Handles CommonMark + GFM tables, task lists, fenced code blocks.

---

## Visual Design

Match the desktop aesthetic — same color temperature, same fonts, same reading experience.

**App chrome (non-WKWebView UI):**
- Background: `#0d0d0d`
- Surface (list backgrounds, cards): `#161616`
- Borders: `#2a2a2a`
- Primary text: `#e0e0e0`
- Muted text: `#888`
- Accent: amber `#d4a04a` (stars, active states, buttons)
- Active/selected: `#1e1e1e`

**System appearance:** Force dark mode via `Info.plist` `UIUserInterfaceStyle = Dark`.

**App icon:** Reuse the desktop icon adapted for iOS dimensions.

**Status bar:** Light content (white text on dark background).

---

## Data Flow Summary

```
┌─────────────────┐     iCloud Drive      ┌──────────────────┐
│  macOS Desktop   │ ──── manifest.json ──→ │   iOS App        │
│  (Tauri)         │ ──── files/**/*.md ──→ │   (SwiftUI)      │
│                  │                        │                  │
│  FileWatcher     │                        │  SyncFolderMgr   │
│  SyncManager     │                        │  LocalCacheMgr   │
│  StateManager    │                        │  AppState        │
│                  │                        │  MarkdownRenderer│
└─────────────────┘                        └──────────────────┘
                                                    │
                                            ┌───────┴────────┐
                                            │  App Sandbox   │
                                            │  Documents/    │
                                            │  cache/        │
                                            │  ├── index.json│
                                            │  └── files/    │
                                            └────────────────┘
```

---

## What's NOT In Scope (V1)

- Writing favorites back to iCloud (read-only from manifest)
- Writing history back to iCloud
- Push notifications for new files
- Background app refresh / silent sync
- Search within file content (only filename search)
- Multiple sync folders
- Editing markdown files
- Sharing/collaboration features
- Light mode for app chrome (only the reader supports light palettes)
