# MarkReader

A local macOS app for browsing and reading markdown files. Watches your folders, smart-filters out framework noise, and provides a pleasant dark-theme reading experience with customizable palettes.

![macOS](https://img.shields.io/badge/platform-macOS-black) ![Next.js](https://img.shields.io/badge/Next.js-15-black) ![Electron](https://img.shields.io/badge/Electron-34-black)

## Features

- **Folder watching** — monitors directories for `.md` files with live updates via SSE
- **Smart filtering** — excludes `node_modules`, build artifacts, LICENSE, CHANGELOG, and agent workflow files (~610 human-readable files from ~8,600 total)
- **4 sidebar views** — Recents, Folders, Favorites, History
- **First-run setup** — native macOS folder picker to choose what to watch
- **9 color palettes** — Parchment Dusk, Deep Ocean, Rosewood, Terminal Green, and more
- **Reader mode** — distraction-free reading with zoom controls
- **Native macOS app** — Electron wrapper with menu bar integration, window state persistence, Reveal in Finder
- **Keyboard-driven** — `1-4` for views, `j/k` for navigation, `s` to star, `/` to search, `Cmd+.` for focus mode

## Download

Grab the latest `.dmg` from [Releases](https://github.com/shahzadsahsan/markreader/releases).

> The app is unsigned. Right-click → Open on first launch to bypass Gatekeeper.

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
# Build Next.js first
npm run build

# Build and package the Electron app
cd macos
npm run make
```

Artifacts land in `macos/out/make/` (DMG + ZIP).

## Stack

- **Next.js 15** — App Router, TypeScript, Tailwind CSS
- **chokidar** — file system watching
- **markdown-it** — rendering with anchor links and syntax highlighting
- **highlight.js** — code block syntax highlighting (github-dark theme)
- **Electron 34** — native macOS wrapper with Forge packaging
- **JetBrains Mono** — sidebar, headings, code
- **Source Serif 4** — prose body text

## Architecture

The app runs a local Next.js server that watches configured directories. The Electron wrapper spawns this server on a random port and loads it in a BrowserWindow. State persists to `~/.markreader/state.json`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed implementation notes.
