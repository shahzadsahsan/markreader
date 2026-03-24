# MarkScout

**See what your AI agent just built.**

![macOS](https://img.shields.io/badge/platform-macOS-black) ![Next.js](https://img.shields.io/badge/Next.js-16-black) ![Electron](https://img.shields.io/badge/Electron-34-black) ![License](https://img.shields.io/badge/license-MIT-black)

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

### First Launch — Bypassing macOS Gatekeeper

The app is unsigned (code signing coming soon). macOS will block it on first open. Here's how to get past that:

1. **Open the DMG** and drag MarkScout to `/Applications`
2. **Double-click MarkScout.app** — macOS will show "MarkScout can't be opened because Apple cannot check it for malicious software"
3. **Click "Done"** (not "Move to Trash")
4. **Open System Settings → Privacy & Security** — scroll down and you'll see a message: *"MarkScout was blocked from use because it is not from an identified developer"*
5. **Click "Open Anyway"** — enter your password when prompted
6. A final dialog asks if you're sure — **click "Open"**
7. MarkScout launches. You only need to do this once.

> **Shortcut**: Right-click (or Control-click) MarkScout.app → "Open" → click "Open" in the dialog. This sometimes works without the System Settings step.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1` `2` `3` | Switch sidebar view (Recents, Folders, Favorites) |
| `j` / `k` | Navigate files up / down |
| `s` | Toggle star on current file |
| `/` | Focus search |
| `Esc` | Clear search |
| `Cmd + S` | Toggle sidebar |
| `Cmd + Shift + F` | Toggle fill screen |
| `Cmd + =` / `Cmd + -` | Zoom in / out |
| `Cmd + 0` | Reset zoom |
| `Cmd + ,` | Preferences |
| `?` | Show shortcut help |

## Roadmap

### v0.4 — Session Intelligence
- **"What's New" launch view** — files modified since your last session, grouped by project
- **Change badges** — NEW / UPDATED indicators in the sidebar
- **Staleness indicators** — recently active files pop, old files fade
- **Drag-to-watch** — drop a folder on the app to start watching it

### v0.5 — Workflow Awareness
- **Project clusters** — auto-group related files (PLAN + ARCHITECTURE + REQUIREMENTS)
- **Smart collections** — "All Plans", "All Architecture Docs", "All Memory Files"
- **File relationship graph** — visualize which markdown files link to each other
- **First-run onboarding** — configure watch folders for your workflow (dev, writing, business)

### v1.0 — Tauri Rewrite
- **~30MB app** (down from ~500MB) via Tauri 2.0 migration
- **Code signing + notarization** — no more Gatekeeper warnings
- **Homebrew cask** — `brew install --cask markscout`
- **Windows + Linux** support

## Development

```bash
# Install dependencies
npm install

# Run the web app
npm run dev

# Run inside Electron
cd macos
npm install
npm run dev
```

## Building the macOS App

```bash
cd macos
npm run make
```

Builds Next.js, prunes to production dependencies, packages with Electron Forge. Output in `macos/out/make/` (DMG + ZIP). App: ~470MB, DMG: ~160MB.

## Stack

- **Next.js 16** — App Router, TypeScript, Tailwind CSS
- **chokidar** — file system watching via `instrumentation.ts`
- **markdown-it** — rendering with anchor links and syntax highlighting
- **highlight.js** — code block syntax highlighting (github-dark theme)
- **Electron 34** — native macOS wrapper with Forge packaging
- **JetBrains Mono** — sidebar, headings, code
- **Source Serif 4** — prose body text

## Architecture

Local Next.js server watches configured directories. Electron spawns the server on a random port and loads it in a BrowserWindow. State persists to `~/.markscout/state.json`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

## Privacy

MarkScout does not collect, transmit, or store any data outside your machine. No analytics, no accounts. The only network call is an optional update check to the GitHub Releases API on launch.

## License

MIT
