# MarkScout

**A beautiful markdown reader for AI-assisted developers.**

![macOS](https://img.shields.io/badge/platform-macOS-black) ![Tauri](https://img.shields.io/badge/Tauri-2.0-black) ![Rust](https://img.shields.io/badge/Rust-backend-black) ![v0.5.0](https://img.shields.io/badge/version-0.5.0-d4a04a) ![License](https://img.shields.io/badge/license-MIT-black)

<img width="412" height="416" alt="markscout app icon" src="https://github.com/user-attachments/assets/469278db-01ba-4a43-b9db-ffe0e9e2d679" />

MarkScout turns the scattered markdown files from your AI coding sessions into a calm, focused reading experience. Plans, specs, architecture docs, memory files, research notes — all surfaced instantly, beautifully rendered, with the noise hidden.

If you use Claude Code, Codex, Cursor, Windsurf, or Aider, your projects are full of `.md` artifacts you never actually read. MarkScout fixes that. It watches your folders, filters out framework junk, and presents your documents the way they deserve to be read — with proper typography, warm color palettes, and zero distractions.

**11 MB download. Opens in under a second. Completely local.**

## The Reading Experience

MarkScout is designed for reading, not editing. Every detail serves that goal:

- **5 typography presets** — Classic (serif), Modern (system sans), Literary (elegant serif), Developer (monospace), and Accessible (larger text, wider spacing, optimized for readability)
- **12 color palettes** — 9 dark (Parchment Dusk, Deep Ocean, Rosewood, Terminal, Warm Paper, Nord Frost, Monokai, Solarized, Catppuccin) + 3 light (Daylight, Sepia, Arctic)
- **Antialiased text rendering** with proper font hierarchy — serif for prose, sans for UI, monospace for code
- **Fill-screen mode** — expand prose to 90% width for immersive reading
- **Zoom controls** — 5 zoom levels (85% to 200%)
- **Code syntax highlighting** — github-dark theme via highlight.js
- **Ambient glow** — subtle animated background that shifts between warm and cool tones

## Features

### Core
- **Live folder watching** — Rust-powered file watcher updates the sidebar instantly when files change
- **Smart noise filtering** — hides node_modules, build artifacts, changelogs, license files, and 11 toggleable filter presets for Claude Code artifacts
- **Full-text search** — searches inside file content (not just names) with highlighted snippets and line numbers
- **Keyboard-driven** — `j`/`k` navigation, `/` search, `?` shortcuts panel

### Sidebar Views
- **What's New** — files changed since your last session, grouped by project, with NEW/UPDATED badges
- **Recents** — all files sorted by last modified, with staleness indicators (active files pop, old files fade)
- **Folders** — collapsible tree with real directory hierarchy
- **Favorites** — starred files and folders

### Smart Collections (v0.5)
Auto-groups your files by document type — Plans, Architecture, Requirements, Memory, Research, READMEs, Guides, Changelogs. Click a collection to browse its files across all projects.

### File Intelligence
- **Related files** — detects markdown cross-references and shows clickable link pills below the file header
- **Move tracking** — if you rename or move a file, your favorites and history follow it via content hashing
- **Session tracking** — remembers when you last used the app so "What's New" shows exactly what changed

### Native macOS
- **11 MB app** — Tauri 2.0 with Rust backend (96% smaller than Electron)
- **Native menu bar** with keyboard shortcuts
- **Window state persistence** — remembers position and size between sessions
- **Reveal in Finder** — one click to open any file's location

## Download

Grab the latest `.dmg` from [**Releases**](https://github.com/shahzadsahsan/markscout/releases).

### First Launch

The app is unsigned (code signing coming soon). On first launch:

1. Drag MarkScout to `/Applications`
2. Right-click → "Open" → click "Open" in the dialog
3. Or: System Settings → Privacy & Security → "Open Anyway"

You only need to do this once.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1` `2` `3` `4` | Switch view (What's New, Recents, Folders, Favorites) |
| `j` / `k` | Navigate files |
| `s` | Star / unstar file |
| `/` | Focus search |
| `Esc` | Clear search |
| `Cmd + B` | Toggle sidebar |
| `Cmd + Shift + F` | Toggle fill screen |
| `Cmd + =` / `-` / `0` | Zoom in / out / reset |
| `Cmd + ,` | Preferences |
| `?` | Shortcut help |

## Roadmap

### v0.6 — Polish
- Code signing + notarization (no more Gatekeeper warnings)
- Homebrew cask (`brew install --cask markscout`)
- Auto-updater via Tauri updater plugin

### v1.0 — Cross-Platform
- Windows + Linux support
- Tauri auto-updater with code signing
- Plugin system for custom filters

## Development

```bash
npm install
npm run tauri dev    # Vite + Tauri hot reload
npm run tauri build  # Release DMG
```

Requires [Rust toolchain](https://rustup.rs/) and Xcode Command Line Tools.

## Stack

- **Tauri 2.0** — Rust backend, native WebView frontend
- **Vite + React 19** — fast frontend bundler
- **Rust** — file watching (notify), state management, content hashing, search, collections
- **markdown-it + highlight.js** — rendering with syntax highlighting
- **Tailwind CSS 4** — styling
- **Source Serif 4** — prose typography
- **JetBrains Mono** — code and metadata
- **System fonts** — UI chrome (SF Pro on macOS)

## Privacy

Everything is local. No analytics, no accounts, no telemetry. The only network call is an optional update check to GitHub Releases on launch.

## License

MIT
