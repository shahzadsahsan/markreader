# MarkScout

**See what your AI agent just built.**

![macOS](https://img.shields.io/badge/platform-macOS-black) ![Tauri](https://img.shields.io/badge/Tauri-2.0-black) ![Rust](https://img.shields.io/badge/Rust-backend-black) ![License](https://img.shields.io/badge/license-MIT-black)

<img width="412" height="416" alt="markscout app icon" src="https://github.com/user-attachments/assets/469278db-01ba-4a43-b9db-ffe0e9e2d679" />

MarkScout watches your project folders and surfaces the markdown files that matter — plans, specs, architecture docs, memory files, research notes — while hiding the thousands of framework-generated files you never want to read.

Built for anyone who works with AI coding agents (Claude Code, Codex, Cursor, Windsurf, Aider). If your workflow generates dozens of `.md` artifacts scattered across nested project folders, MarkScout gives you a fast, distraction-free way to review what got built.

## Features

- **Live folder watching** — monitors any directory for `.md` files, updates instantly on changes
- **Smart noise filtering** — hides `node_modules`, build artifacts, changelogs, license files, agent workflow files
- **Full-text search** — search inside all files (not just filenames) with highlighted match snippets
- **Three sidebar views**: Recents, Folders, Favorites
- **Resizable sidebar** with real folder hierarchy — expand/collapse project by project
- **Star files and folders** — starred folders appear in Favorites with their contents
- **12 color themes**: 9 dark + 3 light (Daylight, Sepia, Arctic) — theme applies everywhere
- **Linked file navigation** — click between markdown files that reference each other
- **Fill-screen mode** for focused reading
- **Keyboard-driven**: `j`/`k` navigation, `/` search, `?` shortcuts
- **Reveal in Finder** with one click
- **Manage watch folders** through Preferences — add, disable, or remove
- **Auto-update checker** — checks GitHub Releases on launch, download updates in-app

## What It Does Not Do

- Edit files. This is a reader.
- Phone home. Everything is local (except the optional update check to GitHub).
- Slow down. Files load in single-digit milliseconds.

## Download

Grab the latest `.dmg` from [**Releases**](https://github.com/shahzadsahsan/markscout/releases).

**v0.4.0**: 11 MB DMG, 18 MB app (down from 160 MB / 500 MB with Electron).

### First Launch — Bypassing macOS Gatekeeper

The app is unsigned (code signing coming soon). macOS will block it on first open:

1. **Open the DMG** and drag MarkScout to `/Applications`
2. **Double-click MarkScout.app** — macOS will block it
3. **Open System Settings → Privacy & Security** — click "Open Anyway"
4. MarkScout launches. You only need to do this once.

> **Shortcut**: Right-click MarkScout.app → "Open" → click "Open" in the dialog.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1` `2` `3` | Switch sidebar view (Recents, Folders, Favorites) |
| `j` / `k` | Navigate files up / down |
| `s` | Toggle star on current file |
| `/` | Focus search |
| `Esc` | Clear search |
| `Cmd + B` | Toggle sidebar |
| `Cmd + Shift + R` | Toggle reader mode |
| `Cmd + Shift + F` | Toggle fill screen |
| `Cmd + =` / `Cmd + -` | Zoom in / out |
| `Cmd + 0` | Reset zoom |
| `Cmd + ,` | Preferences |
| `?` | Show shortcut help |

## Roadmap

### v0.5 — Session Intelligence
- **"What's New" launch view** — files modified since your last session, grouped by project
- **Change badges** — NEW / UPDATED indicators in the sidebar
- **Staleness indicators** — recently active files pop, old files fade
- **Drag-to-watch** — drop a folder on the app to start watching it
- **First-run onboarding** — configure watch folders for your workflow

### v0.6 — Workflow Awareness
- **Project clusters** — auto-group related files (PLAN + ARCHITECTURE + REQUIREMENTS)
- **Smart collections** — "All Plans", "All Architecture Docs", "All Memory Files"
- **File relationship graph** — visualize which markdown files link to each other

### v1.0 — Distribution
- **Code signing + notarization** — no more Gatekeeper warnings
- **Homebrew cask** — `brew install --cask markscout`
- **Auto-updater** — in-app updates via Tauri updater plugin
- **Windows + Linux** support (Tauri already supports both)

## Development

```bash
# Install dependencies
npm install

# Run in development (Vite + Tauri hot reload)
npm run tauri dev

# Build release DMG
npm run tauri build
```

Requires [Rust toolchain](https://rustup.rs/) and Xcode Command Line Tools.

## Stack

- **Tauri 2.0** — Rust backend, native WebView frontend
- **Vite** — frontend bundler with React plugin
- **React 19** — UI components
- **Rust** — file watching (notify crate), state management, content hashing, search
- **markdown-it** — rendering with anchor links and syntax highlighting
- **highlight.js** — code block syntax highlighting (github-dark theme)
- **Tailwind CSS 4** — styling
- **JetBrains Mono** — sidebar, headings, code
- **Source Serif 4** — prose body text

## Architecture

Rust backend watches configured directories, maintains a file registry in a `DashMap`, and serves 19 IPC commands to the React frontend. State persists to `~/.markscout/state.json` with atomic writes. File events are emitted via Tauri's event system.

See [ARCHITECTURE.md](ARCHITECTURE.md) and [TAURI_MIGRATION.md](TAURI_MIGRATION.md) for details.

## Privacy

MarkScout does not collect, transmit, or store any data outside your machine. No analytics, no accounts. The only network call is an optional update check to the GitHub Releases API on launch.

## License

MIT
