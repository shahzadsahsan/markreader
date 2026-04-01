# MarkScout iOS Companion App — Build Prompt

Read the design spec at `docs/superpowers/specs/2026-03-29-ios-companion-app-design.md` first. That is the authoritative source for architecture, models, services, screens, themes, zoom, and offline behavior.

## Context

MarkScout is a macOS Tauri desktop app that watches directories for `.md` files and provides a reading experience. The desktop app already syncs filtered `.md` files + a `manifest.json` to `iCloud Drive > MarkScout/`. You are building the iOS companion app that reads from this iCloud folder.

The desktop Tauri app lives at the repo root (`src-tauri/` for Rust backend, `src/` for React frontend). The iOS app lives at `ios/`. They share the same git repo.

## Task

Build a SwiftUI iOS app (iOS 17+, iPhone + iPad) as an Xcode project at `ios/MarkScout.xcodeproj`. The app reads from the MarkScout iCloud Drive folder and provides an offline-capable markdown reading experience.

**Tech stack:** SwiftUI, WKWebView (via UIViewRepresentable), no external Swift dependencies. Bundle marked.js (~50KB) and highlight.js as JavaScript resources for client-side markdown rendering.

**Read the design spec** for full details on all of the following. Here is a summary:

### Architecture

- **Models:** `SyncManifest` (Codable matching manifest.json), `AppState` (@Observable)
- **Services:** `SyncFolderManager` (security-scoped bookmark + folder access), `LocalCacheManager` (offline cache to app sandbox), `MarkdownRenderer` (WKWebView wrapper)
- **5 screens:** OnboardingView (4-step wizard), FileListView (main list), FileDetailView (markdown reader), FolderBrowserView (tree by project), SettingsView

### iCloud Folder Access

Use `UIDocumentPickerViewController` on first launch to let the user select the `iCloud Drive > MarkScout` folder. Store a security-scoped bookmark in UserDefaults. On subsequent launches, resolve the bookmark and re-prompt if stale. Always bracket reads with `startAccessingSecurityScopedResource()` / `stopAccessingSecurityScopedResource()`.

### Manifest Schema

```json
{
  "version": 1,
  "synced_at": 1711701600000,
  "file_count": 247,
  "total_size": 2048000,
  "files": [{
    "relative_path": "markreader/ARCHITECTURE.md",
    "name": "ARCHITECTURE",
    "project": "markreader",
    "modified_at": 1711701600000,
    "size": 4096,
    "content_hash": "a1b2c3..."
  }],
  "favorites": [{
    "relative_path": "markreader/REQUIREMENTS.md",
    "content_hash": "d4e5f6...",
    "starred_at": 1711701600000
  }]
}
```

All timestamps are Unix epoch milliseconds. `content_hash` is SHA-256 of first 1024 bytes + file size.

### Markdown Rendering

Bundle a standalone `reader.html` in the app with:
- `marked.min.js` for markdown→HTML conversion (client-side)
- `highlight.min.js` + `github-dark.min.css` for code syntax highlighting
- `JetBrainsMono-Regular.woff2` (headings + code) and `SourceSerif4-Regular.woff2` (body prose)
- `reader.css` with all palette CSS variables, typography (Source Serif 4 18px/1.7 body, JetBrains Mono headings)

WKWebView `baseURL` points to app bundle so `@font-face` paths resolve. Markdown content passed via JS bridge: `renderMarkdown(rawMarkdownString)`.

### 16 Theme Palettes

Port all 16 palettes from the desktop (`src/components/MarkdownPreview.tsx` lines 15-196). Each palette is a dictionary of CSS custom property overrides. Categories: Dark Warm (Parchment Dusk, Rosewood, Warm Paper), Dark Cool (Deep Ocean, Nord Frost, Solarized, Dracula, Tokyo Night), Dark Vibrant (Terminal, Monokai, Catppuccin, Synthwave), Light (Daylight, Sepia, Arctic, Sakura).

Applied via JavaScript: `document.documentElement.style.setProperty(name, value)`. Palette picker presented as sheet/popover grouped by category.

### Zoom

- A−/A+ step buttons (0.8x → 2.0x in 0.1 increments) via JS: `document.documentElement.style.fontSize = 'calc(18px * ${level})'`
- Pinch-to-zoom via native WKWebView (evaluate whether to disable to avoid conflict)
- Double-tap: toggle between 1.0x and last zoom level
- Full device width with comfortable padding (16px iPhone, 24px iPad) — no 720px max-width cap

### Swipe Navigation

- **Swipe right** (finger left→right): Native iOS back gesture to file list (free from NavigationStack)
- **Swipe left** (finger right→left): Custom gesture to advance to next file in current sort order. Context-aware — file order matches the list you navigated from (All Files by modifiedAt, Favorites by starredAt, Folder by project scope). Stops at end of list.

### Offline

Cache all files to `Documents/cache/` on first manifest load. Store `index.json` mapping `relativePath → contentHash`. On refresh, compare hashes, re-download changed files, prune removed files. When offline, show "Offline — showing cached data" and read from cache.

### Visual Design

Dark theme matching desktop: background `#0d0d0d`, surface `#161616`, border `#2a2a2a`, text `#e0e0e0`, muted `#888`, accent amber `#d4a04a`. Force dark mode via `Info.plist`. iPad uses `NavigationSplitView`, iPhone uses `NavigationStack`.

---

## Additional Features (beyond the base design spec)

Build these five features in addition to everything in the design spec:

### 1. Reading Position Memory

Save and restore scroll position per file so the user resumes where they left off.

**Implementation:**
- Store a dictionary in UserDefaults: `[relativePath: scrollPercentage]` (Double, 0.0–1.0)
- On file open: after WKWebView finishes loading, restore scroll position via JS: `window.scrollTo(0, document.body.scrollHeight * percentage)`
- On file close / swipe away / app background: read current position via JS: `window.pageYOffset / document.body.scrollHeight` and persist
- Use `WKScriptMessageHandler` to communicate scroll position from JS → Swift
- Add a small "resume" indicator when returning to a previously-read file (e.g., a brief toast "Resuming from where you left off" that fades after 1.5s)
- Cap the stored positions map at 200 entries (LRU eviction by last-read time)
- If `contentHash` has changed since last read, discard the saved position (file was modified)

### 2. Table of Contents Drawer

A slide-out panel listing all headings in the current document for quick navigation.

**Implementation:**
- After `marked.js` renders the markdown, extract all headings via JS: `document.querySelectorAll('h1, h2, h3, h4, h5, h6')` and send the list (text + id + level) to Swift via `WKScriptMessageHandler`
- Display as a half-sheet (iPhone) or side panel (iPad) triggered by a TOC button in the reader toolbar (list icon)
- Indent headings by level (h1 flush left, h2 indented 16px, h3 32px, etc.)
- Tapping a heading scrolls WKWebView to that anchor via JS: `document.getElementById(id).scrollIntoView({ behavior: 'smooth' })`
- Dismiss the drawer on selection
- Style: dark background (#161616), heading text in palette's heading colors, active heading highlighted based on current scroll position
- Track active heading via `IntersectionObserver` in JS, report to Swift which heading is currently visible

### 3. In-File Text Search

Find-in-page functionality within the markdown reader.

**Implementation:**
- Toolbar search icon opens a search bar overlay at the top of FileDetailView (similar to Safari's find-in-page)
- On text input, use WKWebView's built-in find: `webView.find(searchText, configuration: WKFindConfiguration())` (available iOS 16+). This handles highlighting matches, match count, and next/previous navigation natively.
- Display: search text field + match count ("3 of 12") + up/down arrows for prev/next match + X to dismiss
- Keyboard: Enter advances to next match, Shift+Enter goes to previous
- Dismiss search bar on swipe down or X button, which clears highlights
- The search bar should not push the WKWebView content down — overlay it with a translucent dark background

### 4. Core Spotlight Integration

Index file contents so users can find MarkScout files from iOS home screen search.

**Implementation:**
- Add `CoreSpotlight.framework` and `MobileCoreServices.framework`
- After caching files, index each file with `CSSearchableIndex`:
  ```swift
  let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
  attributeSet.title = fileEntry.name
  attributeSet.contentDescription = firstParagraph  // first 200 chars of file content
  attributeSet.keywords = [fileEntry.project, "markdown", fileEntry.name]

  let item = CSSearchableItem(
      uniqueIdentifier: fileEntry.relativePath,
      domainIdentifier: "com.markscout.files",
      attributeSet: attributeSet
  )
  CSSearchableIndex.default().indexSearchableItems([item])
  ```
- On cache refresh: re-index changed files, delete removed files via `deleteSearchableItems(withIdentifiers:)`
- Handle `NSUserActivity` from Spotlight tap in `MarkScoutApp.swift`:
  ```swift
  .onContinueUserActivity(CSSearchableItemActionType) { activity in
      if let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
          appState.selectedFile = manifest.files.first { $0.relativePath == identifier }
      }
  }
  ```
- This opens the app directly to the tapped file's FileDetailView

### 5. Handoff Support

Start reading a file on Mac, pick up on iPhone (and vice versa if the Mac app adds Handoff support later).

**Implementation:**
- Advertise a `NSUserActivity` when reading a file:
  ```swift
  let activity = NSUserActivity(activityType: "com.markscout.viewing")
  activity.title = "Reading \(fileEntry.name)"
  activity.userInfo = ["relativePath": fileEntry.relativePath]
  activity.isEligibleForHandoff = true
  activity.isEligibleForSearch = true  // also makes it show in Siri suggestions
  activity.webpageURL = nil  // local-only, no web fallback
  ```
- Set `activity.becomeCurrent()` when FileDetailView appears, `activity.resignCurrent()` when it disappears
- Register the activity type in `Info.plist` under `NSUserActivityTypes`: `["com.markscout.viewing"]`
- Handle incoming Handoff in `MarkScoutApp.swift`:
  ```swift
  .onContinueUserActivity("com.markscout.viewing") { activity in
      if let path = activity.userInfo?["relativePath"] as? String {
          appState.selectedFile = manifest.files.first { $0.relativePath == path }
      }
  }
  ```
- The desktop Tauri app would need to advertise the same activity type for Mac→iPhone handoff to work. For now, implement the iOS receiving side so it's ready when the desktop adds it.

---

## Key Constraints

- **iOS 17+** minimum deployment target
- **iPhone + iPad** adaptive layout (NavigationSplitView on iPad)
- **No external Swift dependencies** — pure SwiftUI + WKWebView + bundled JS
- **Read-only** — never modify the iCloud Drive files
- **Dark theme** for app chrome (reader supports all 16 palettes including 4 light themes)
- **Free Apple Developer account** works for personal device testing (7-day signing)
- The app is a companion, not a redesign — match the desktop's aesthetic (same fonts, colors, reading experience)

## Implementation Order

1. Create Xcode project at `ios/` with correct bundle ID and deployment target
2. Models: `SyncManifest.swift`, `AppState.swift`
3. Services: `SyncFolderManager.swift` (bookmark flow), `LocalCacheManager.swift` (offline cache)
4. Bundled resources: `reader.html`, `reader.css`, fonts, highlight.js, marked.js
5. `MarkdownRenderer.swift` (WKWebView wrapper with theme + zoom + JS bridge)
6. OnboardingView (4-step wizard with folder picker)
7. FileListView (search, segments, pull-to-refresh)
8. FileDetailView (reader with toolbar, swipe gestures)
9. FolderBrowserView + SettingsView
10. Reading position memory (scroll save/restore)
11. Table of contents drawer (heading extraction + navigation)
12. In-file text search (WKWebView find)
13. Core Spotlight indexing
14. Handoff support
