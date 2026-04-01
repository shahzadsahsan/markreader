# MarkScout — Mac App Store Connect Metadata

## App Name
MarkScout

## Subtitle (30 chars max)
Beautiful Markdown Reader

## Category
Primary: Developer Tools
Secondary: Productivity

## Price
Free

## Privacy Policy URL
https://markscout-privacy.vercel.app

---

## Description (4000 chars max)

MarkScout is a beautiful, distraction-free markdown reader built for developers who use AI coding assistants.

If you use Claude Code, Cursor, Codex, Windsurf, or Aider, your projects are full of .md artifacts -- plans, specs, architecture docs, memory files, research notes -- scattered across dozens of folders. MarkScout watches your directories, filters out framework noise, and presents your documents with proper typography and warm color palettes.

**Reading experience:**

- 16 color palettes -- Obsidian, Synthwave, Dracula, Tokyo Night, Nord, Solarized, Catppuccin, and more
- 5 typography presets -- Classic (serif), Modern (sans), Literary (elegant), Developer (mono), Accessible (large text)
- Syntax-highlighted code blocks with github-dark theme
- Tables, task lists, and full GitHub-flavored markdown
- Fill-screen mode for immersive reading
- 5 zoom levels (85% to 200%)
- Section tracking -- current heading shows in the header as you scroll
- Reading position memory -- scroll position saved per file

**Built for developer workflows:**

- Live folder watching -- Rust-powered file watcher updates the sidebar instantly
- Smart noise filtering -- hides node_modules, build artifacts, changelogs, and 11 toggleable filter categories
- Full-text search with highlighted snippets and line numbers
- Keyboard-driven -- j/k navigation, / to search, ? for the full shortcuts panel
- Move tracking -- favorites and history follow renamed files via content hashing
- Related files -- see sibling files from the same folder at the bottom of each document

**Companion iOS app:**

Enable iCloud sync to read your docs on your iPhone with the free MarkScout iOS companion app.

**Privacy-first:**

MarkScout is completely local. No accounts, no analytics, no tracking, no data collection. Your files stay on your device. 11 MB download, opens in under a second.

## Keywords (100 chars max, comma-separated)
markdown,reader,developer,documentation,notes,code,dark-mode,syntax,icloud,ai

## What's New in This Version
Initial Mac App Store release. A beautiful markdown reader for AI-assisted developers -- 16 color palettes, 5 typography presets, live folder watching, full-text search, and iCloud sync with the iOS companion app.

## Support URL
https://markscout-privacy.vercel.app

## Marketing URL (optional)
https://github.com/shahzadsahsan/markscout

---

## App Review Notes

**Demo credentials:** Not applicable -- MarkScout does not require login.

**How to test:**
On first launch, click "Add Folder" in the sidebar or Settings to select any folder containing .md files. The app will scan the directory and display all markdown files in the sidebar. Click any file to read it in the preview pane.

**How the app works:**
MarkScout reads markdown files from user-selected directories on disk. It is read-only and never modifies any files. Users can star favorites, search file contents, and customize the reading experience with color palettes and typography presets. All state is stored locally in the app container.

**iCloud sync (optional):** When enabled, MarkScout copies .md files to a folder in iCloud Drive so the companion iOS app can read them. This is off by default and controlled via Settings.

**Required:** macOS 12.0 (Monterey) or later.

---

## Age Rating
4+ (no objectionable content)

## Copyright
2026 Shahzad Ahsan

---

## Screenshots Order (for App Store Connect)

Required: MacBook Pro 16-inch (2880x1800)

1. `01-file-browser.png` -- Sidebar with file list + markdown preview
2. `02-reader-view.png` -- Full prose rendering with syntax highlighting
3. `03-themes.png` -- Settings showing palette picker (Synthwave/Dracula active)
4. `04-search.png` -- Full-text search results with highlighted snippets
5. `05-palettes.png` -- Collage showing multiple color palettes

### Screenshot Text Overlays

| # | Headline | Subheadline |
|---|----------|-------------|
| 1 | Your Markdown, Beautiful | 16 palettes. 5 typography presets. Zero distractions. |
| 2 | Read, Don't Edit | Syntax highlighting, tables, task lists -- all rendered perfectly. |
| 3 | Every Theme You Want | Obsidian, Synthwave, Dracula, Nord, and 12 more. |
| 4 | Find Anything Instantly | Full-text search across all your files with highlighted results. |
| 5 | Built for AI Developers | Watches your folders. Filters the noise. Shows what matters. |

---

## App Store Connect Checklist

- [ ] Create App ID (com.markscout.app) in Apple Developer Portal
- [ ] Create Apple Distribution certificate
- [ ] Create Mac Installer Distribution certificate
- [ ] Create Mac App Store provisioning profile
- [ ] Build universal binary with `--features mas`
- [ ] Sign .app with Apple Distribution certificate
- [ ] Create signed .pkg with Mac Installer certificate
- [ ] Validate with `xcrun altool --validate-app`
- [ ] Create app in App Store Connect
- [ ] Upload screenshots (5 framed images at 2880x1800)
- [ ] Fill all metadata fields
- [ ] Upload build via Transporter or `xcrun altool`
- [ ] Submit for review
