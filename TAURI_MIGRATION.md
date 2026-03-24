# MarkScout — Tauri 2.0 Migration Plan & Progress

## Current Status

**Branch:** `tauri-rewrite` (off `main`)
**Phase:** 7 of 7 — BUILD COMPLETE
**Last updated:** 2026-03-24

### Build Results
- **DMG:** 11 MB (was 160 MB with Electron — 93% reduction)
- **App:** 18 MB (was ~500 MB with Electron — 96% reduction)
- **Rust compilation:** 0 errors (11 warnings for unused helper methods)
- **TypeScript compilation:** 0 errors
- **Output:** `src-tauri/target/release/bundle/dmg/MarkScout_1.0.0_aarch64.dmg`

---

## What's Done

### Phase 1 (partial): Tauri scaffold created

Files created in `src-tauri/`:

```
src-tauri/
├── Cargo.toml              ✅ All crates declared (tauri 2, notify 7, serde, sha2, dashmap, etc.)
├── build.rs                ✅ tauri_build::build()
├── tauri.conf.json         ✅ Window config (1200x800, #0d0d0d bg), bundle targets (dmg, app)
├── capabilities/default.json ✅ core:default, shell:allow-open, dialog:allow-open
└── src/
    ├── main.rs             ✅ Entry point → markscout_lib::run()
    ├── lib.rs              ✅ Full command registration (19 commands), plugin init, setup hook
    └── commands/           ✅ Directory created (empty — commands not yet implemented)
```

### What's NOT done yet in Phase 1

- [ ] `vite.config.ts` — Vite + React + Tauri plugin config
- [ ] `index.html` — Vite entry HTML
- [ ] `src/main.tsx` — React entry point
- [ ] `src/App.tsx` — Root component
- [ ] `postcss.config.mjs` — Tailwind CSS 4 setup
- [ ] `tsconfig.json` — needs updating for Vite (remove Next.js paths)
- [ ] `package.json` — needs Vite deps, Tauri CLI, remove Next.js deps
- [ ] `public/fonts/` — download JetBrains Mono + Source Serif 4 woff2 files
- [ ] `src/styles/globals.css` — copy from current, replace next/font vars with @font-face
- [ ] Tauri app icons in `src-tauri/icons/`
- [ ] Verify `npm run tauri dev` launches a styled blank window

---

## What's NOT Done (Phases 2–7)

### Phase 2: Rust Core — Types + State + Filters + Hash

Create these Rust modules matching the existing TypeScript exactly:

- [ ] `src-tauri/src/types.rs` — All types with `#[serde(rename_all = "camelCase")]`
  - `FileEntry`, `FavoriteEntry`, `HistoryEntry`, `FolderNode`
  - `AppState` (version 2), `FilterConfig`, `FilterPreset`, `PreferencesState`
  - `SidebarView`, `FilterPresetId`, `SSEEvent` variants
  - `SearchResult`, `FileContentResponse`
  - Must produce identical JSON to existing `~/.markscout/state.json`

- [ ] `src-tauri/src/state.rs` — `AppStateManager`
  - Load/save `~/.markscout/state.json`
  - `tokio::sync::Mutex<AppState>` (replaces JS write queue)
  - Atomic writes via `.tmp` file + rename
  - All operations: toggle_favorite, record_open, save_sidebar_view, save_sidebar_width, etc.
  - Move tracking: `reconcile_paths()`, `check_live_move()`
  - History limit: 50 entries

- [ ] `src-tauri/src/filters.rs`
  - `IGNORED_PATHS` as compiled `RegexSet`
  - `DEFAULT_EXCLUDED_FILENAMES` as regex patterns
  - `is_excluded_file()`, `is_excluded_path()`
  - Preset matching: `matches_active_preset()`

- [ ] `src-tauri/src/hash.rs`
  - SHA-256 of first 1024 bytes + file size string
  - Must produce identical hex output to the JS version in `src/lib/hash.ts`

**Reference files:**
- `src/lib/types.ts` (138 lines)
- `src/lib/state.ts` (439 lines)
- `src/lib/filters.ts` (91 lines)
- `src/lib/presets.ts` (148 lines)
- `src/lib/hash.ts` (33 lines)

### Phase 3: Rust File Watcher

- [ ] `src-tauri/src/watcher.rs`
  - `notify` 7 + `notify-debouncer-full` 0.4 with 100ms debounce
  - File registry: `DashMap<String, FileEntry>`
  - Default watch dirs: `~/.claude/`, `~/Documents/` + custom from state
  - Event emission: `app_handle.emit("file-event", payload)`
  - Events: file-added, file-changed, file-removed, scan-complete
  - Initial scan: walk dirs → filter → build entries → emit scan-complete
  - Move tracking on startup + on file-added
  - Dynamic add/remove watch directories
  - Init in Tauri `setup()` hook

**Reference file:** `src/lib/watcher.ts` (332 lines)

### Phase 4: Rust IPC Commands

Create `src-tauri/src/commands/` modules:

- [ ] `mod.rs` — re-exports
- [ ] `files.rs`
  - `get_files(view: String)` → returns `FileEntry[]` or `FolderNode[]`
  - `get_file_content(path: String)` → reads file, computes word count, reading time
  - `build_folder_tree()` — same algorithm as current `src/app/api/files/route.ts`
  - Path validation (must be under watched dir)

- [ ] `search.rs`
  - `search_files(query: String, limit: Option<u32>)` → `SearchResult[]`
  - Max 500KB per file, batched reads via `spawn_blocking`
  - Case-insensitive substring match, 60-char snippet context

- [ ] `state_cmds.rs`
  - `get_ui_state()` → full UI state + favorites + excluded paths + first_run flag
  - `save_ui_state(partial)` → update any UI field
  - `toggle_favorite(path)` → returns `{ path, isFavorite }`
  - `toggle_folder_star(path)` → returns `{ path, isFavorite }`
  - `record_history(path)` → records file open
  - `get_history()` → returns history list

- [ ] `preferences.rs`
  - `get_preferences()` → presets with match counts, active presets, watch dirs
  - `toggle_preset(preset_id)` → toggle and refresh watcher
  - `add_watch_dir(path)` / `remove_watch_dir(path)` → dynamic watcher update
  - `set_min_file_length(bytes)`
  - `update_filter(action, path)` → exclude/include folder
  - `get_filters()` → excluded paths list

- [ ] `system.rs`
  - `reveal_in_finder(path)` → `open -R <path>` via Command
  - `check_for_update()` → GitHub API latest release check
  - `open_external(url)` → open URL in default browser

**Reference files:** all `src/app/api/*/route.ts` files (10 routes)

### Phase 5: Port Frontend

- [ ] Copy React components from `src/app/components/` → `src/components/`
  - AppShell.tsx → App.tsx (HEAVY changes: ~40 fetch→invoke, EventSource→listen)
  - Sidebar.tsx (no changes)
  - RecentsView.tsx (no changes)
  - FoldersView.tsx (no changes)
  - FavoritesView.tsx (no changes)
  - HistoryView.tsx (no changes)
  - FileItem.tsx (no changes)
  - MarkdownPreview.tsx (1 fetch→invoke change)
  - StatusBar.tsx (no changes)
  - PreferencesPanel.tsx (MODERATE: ~8 fetch→invoke, dialog plugin)

- [ ] Create `src/lib/api.ts` — typed invoke() wrappers:
  ```typescript
  import { invoke } from '@tauri-apps/api/core';
  export const api = {
    getFiles: (view: string) => invoke('get_files', { view }),
    getFileContent: (path: string) => invoke('get_file_content', { path }),
    searchFiles: (query: string, limit?: number) => invoke('search_files', { query, limit }),
    toggleFavorite: (path: string) => invoke('toggle_favorite', { path }),
    // ... etc
  };
  ```

- [ ] Replace `new EventSource('/api/events')` with:
  ```typescript
  import { listen } from '@tauri-apps/api/event';
  listen('file-event', (event) => { /* handle */ });
  ```

- [ ] Remove all `window.electron` bridge references
- [ ] Port keyboard shortcuts (pure DOM, no changes needed)
- [ ] Markdown rendering stays as-is (markdown-it + highlight.js client-side)

**Key mapping — every fetch() call to its Tauri replacement:**

| Frontend Location | Current | Tauri Replacement |
|---|---|---|
| AppShell: initial load | `fetch('/api/ui')` | `invoke('get_ui_state')` |
| AppShell: file list | `fetch('/api/files?view=X')` | `invoke('get_files', { view })` |
| AppShell: file content | `fetch('/api/file?path=X')` | `invoke('get_file_content', { path })` |
| AppShell: search | `fetch('/api/search?q=X')` | `invoke('search_files', { query })` |
| AppShell: star | `fetch('/api/star', POST)` | `invoke('toggle_favorite', { path })` |
| AppShell: history | `fetch('/api/history', POST)` | `invoke('record_history', { path })` |
| AppShell: all UI saves | `fetch('/api/ui', POST)` | `invoke('save_ui_state', { ... })` |
| AppShell: folder star | `fetch('/api/ui', POST)` | `invoke('toggle_folder_star', { path })` |
| AppShell: exclude folder | `fetch('/api/filter', POST)` | `invoke('update_filter', { action, path })` |
| AppShell: watch dirs | `fetch('/api/preferences', POST)` | `invoke('add_watch_dir')`/`invoke('remove_watch_dir')` |
| AppShell: SSE events | `new EventSource('/api/events')` | `listen('file-event', cb)` |
| PreferencesPanel: load | `fetch('/api/preferences')` | `invoke('get_preferences')` |
| PreferencesPanel: toggle | `fetch('/api/preferences', POST)` | `invoke('toggle_preset', { presetId })` |
| PreferencesPanel: min len | `fetch('/api/preferences', POST)` | `invoke('set_min_file_length', { bytes })` |
| PreferencesPanel: folder | `electron.selectFolder()` | `open()` from `@tauri-apps/plugin-dialog` |
| MarkdownPreview: reveal | `fetch('/api/reveal', POST)` | `invoke('reveal_in_finder', { path })` |
| StatusBar: update | `electron.openExternal(url)` | `invoke('open_external', { url })` |

### Phase 6: Native Features

- [ ] Menu via Tauri Menu API (replicating current 5-section menu)
- [ ] Window state persistence (position/size → `~/.markscout/window-state.json`)
- [ ] Update checker (reqwest → GitHub API, same approach as current)
- [ ] App icon: convert existing icons → `src-tauri/icons/` (32x32, 128x128, 128x128@2x, .icns, .ico)
- [ ] Capability permissions for shell, dialog plugins

### Phase 7: Build + Ship

- [ ] `npm run tauri build` → DMG
- [ ] Verify DMG size < 50MB (target: ~15-25MB)
- [ ] Install to /Applications, test all features
- [ ] Merge to main, push, create GitHub release v1.0.0
- [ ] Update README with new architecture + size stats

---

## Architecture Comparison

| Layer | Current (Electron) | Target (Tauri) |
|---|---|---|
| Backend | Next.js 16 server (Node.js) | Rust binary (~5-15MB) |
| File watching | chokidar (JS) | notify crate (Rust) |
| State | fs + write queue (JS) | serde_json + atomic writes (Rust) |
| Frontend | React 19 in Chromium | React 19 in native WebView (WKWebView) |
| Bundler | Turbopack (Next.js) | Vite |
| IPC | fetch() to API routes | invoke() Tauri commands |
| Live events | SSE (EventSource) | Tauri events (app.emit → listen) |
| Menu | Electron Menu API | Tauri Menu API |
| Packaging | electron-forge → DMG | tauri build → DMG |
| Size | ~500MB app / 160MB DMG | ~30-50MB app / 15-25MB DMG |

---

## Rust Crates (already in Cargo.toml)

```toml
tauri = "2"
tauri-plugin-shell = "2"
tauri-plugin-dialog = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
notify = "7"
notify-debouncer-full = "0.4"
sha2 = "0.10"
regex = "1"
uuid = { version = "1", features = ["v4"] }
dirs = "5"
tokio = { version = "1", features = ["full"] }
reqwest = { version = "0.12", features = ["json", "rustls-tls"] }
semver = "1"
dashmap = "6"
log = "0.4"
```

## Frontend Dependencies (need to add)

```json
{
  "dependencies": {
    "react": "^19",
    "react-dom": "^19",
    "markdown-it": "^14",
    "markdown-it-anchor": "^9",
    "highlight.js": "^11",
    "@tauri-apps/api": "^2",
    "@tauri-apps/plugin-shell": "^2",
    "@tauri-apps/plugin-dialog": "^2"
  },
  "devDependencies": {
    "@tauri-apps/cli": "^2",
    "vite": "^6",
    "@vitejs/plugin-react": "^4",
    "@tailwindcss/postcss": "^4",
    "tailwindcss": "^4",
    "typescript": "^5",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "@types/markdown-it": "^14"
  }
}
```

---

## What Stays Unchanged

- All 12 color palettes and theme system
- Keyboard shortcuts (j/k nav, /, ?, Cmd+S toggle star, etc.)
- Markdown rendering (markdown-it + highlight.js runs in WebView)
- State file format (`~/.markscout/state.json` — backward compatible)
- All UI component structure and CSS styling
- globals.css (only font reference changes)

## Key Risks

1. **`notify` vs `chokidar` event differences** — use debouncer, test with real file changes
2. **WebKit rendering** — Tauri on macOS uses WKWebView (Safari engine), not Chromium. Test all CSS.
3. **Font loading** — self-host woff2 files with `@font-face` instead of `next/font`
4. **Tauri updater needs signing** — keep manual GitHub check as fallback
5. **State migration** — same JSON schema, but test round-trip with existing state.json

---

## How to Resume

Start a new Claude Code session in this directory and say:

> Read `TAURI_MIGRATION.md` and continue the Tauri rewrite from where it left off. We're on branch `tauri-rewrite`, Phase 1 is partially done (Rust scaffold exists but Vite/React frontend isn't set up yet). Complete Phase 1, then proceed through the remaining phases.

The existing source files for the current Electron+Next.js app are all still in `src/` — use them as reference when porting to Tauri.
