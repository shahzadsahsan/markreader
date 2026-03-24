# DeepThink Harvest: MarkScout Roadmap

## Summary
MarkScout's moat is NOT being another markdown editor — it's being the companion app for AI-assisted work. The tagline should shift from "browse your markdown files" to "See what your AI agent just built." Three releases: v0.4 (session intelligence), v0.5 (workflow awareness), v1.0 (Tauri rewrite + broad audience).

## Roadmap

### v0.4 — Session Intelligence (next release)
**Theme: "What changed since I was last here?"**

1. **Launch dashboard / "What's New" view** — on app open, show files modified since last session close. Grouped by project. This is the killer feature that no markdown reader has.
2. **Staleness indicators** — files not modified in 7+ days get a subtle muted treatment. 30+ days = "archive" styling. Active files pop visually.
3. **Session tracking** — record app open/close timestamps in state.json. Use this to compute "since last session" deltas.
4. **File change badges** — NEW (created since last session), UPDATED (modified since last session), visible in all sidebar views.
5. **Quick-watch from Finder** — drag a folder onto the dock icon or app window to add it as a watched folder instantly.

### v0.5 — Workflow Awareness
**Theme: "MarkScout knows which files belong together."**

1. **Project clusters** — auto-detect related files in the same directory (PLAN.md, ARCHITECTURE.md, REQUIREMENTS.md, CLAUDE.md = a "project"). Show them as a linked group, not isolated files.
2. **Agent session detection** — parse `.claude/` memory and session files to show which Claude Code sessions generated which files. Timeline view: "Session at 2:30pm → created 4 files."
3. **File relationship graph** — if a markdown file links to another markdown file (via `[text](./other.md)`), show those connections. Click to navigate.
4. **Smart collections** — auto-generated collections: "All Plans", "All Architecture Docs", "All Memory Files", "All READMEs". Pattern-matched on filename conventions.
5. **Non-coder onboarding** — first-run wizard that asks "What do you use AI tools for?" and pre-configures watch folders (~/Documents for writers, ~/Projects for devs, custom for business users).

### v1.0 — Tauri Rewrite + Public Release
**Theme: "A real app, not a web page in a frame."**

1. **Tauri 2.0 migration** — Rust backend replaces Node.js. App drops from 500MB to ~30MB. Instant launch. Native file dialogs. Proper macOS integration.
2. **Code signing + notarization** — Apple Developer certificate. No more Gatekeeper warnings.
3. **Homebrew cask** — `brew install --cask markscout` for easy install/update.
4. **Auto-update via Sparkle** — native macOS update framework, no more GitHub release polling.
5. **Windows + Linux** — Tauri is cross-platform. Ship for all three.

## Key Findings

- **The "AI workflow companion" positioning is the moat.** Obsidian is for writers who write markdown. Typora is for editing markdown. MarkScout is for people who GENERATE markdown via AI tools and need to review what got built.
- **Session awareness is the highest-impact feature.** "What changed?" is the first question anyone asks when returning to a project. No file browser answers this well.
- **Tauri is the right migration target.** Swift/AppKit would be faster and smaller but locks to macOS. Tauri keeps the web UI (so most of the current code survives) and adds Windows/Linux for free. ~30MB vs ~500MB.
- **The non-coder audience is real but narrow.** Business users who run Claude Code for research, strategy docs, and writing DO generate markdown. But they won't find MarkScout on their own — they need to be told about it in context (e.g., Claude Code could suggest it).

## Open Questions
- Should v0.4 include the Tauri exploration as a spike, or wait until v1.0?
- Is Homebrew cask worth pursuing before code signing?
- Should MarkScout eventually support non-.md files (e.g., .txt, .rst)?

## Follow-ups
- /deepthink "Tauri 2.0 migration plan for MarkScout — what survives, what gets rewritten" — for v1.0 planning
- /problem-solve "Should MarkScout detect and parse .claude/ session files for agent timeline?" — privacy/complexity tradeoff
