# Orient

## What I Know
- MarkScout is a local-only Tauri 2.0 markdown reader for AI-assisted developers
- Successfully migrated from Electron (500MB) to Tauri (18MB) — shipping as macOS-only
- Core value: surfaces ~610 human-readable .md files from 9,200+ across Vibe Coding/ and .claude/
- v0.6 shipped, v0.7-beta in progress with folder groups, sort buttons, periodic rescan, theme picker fixes
- Intelligence features planned (related files, session awareness, cross-reference detection) but user is skeptical
- Tauri 2.0 theoretically supports Windows/Linux/iOS/Android but iOS support is experimental
- User wants to understand cross-platform complexity, especially iOS with iCloud file sync
- No clear persona definitions exist — the app targets "AI vibe coders" loosely

## What I'm Uncertain About
1. Which v0.7 intelligence features actually landed vs. were cut — need to check codebase
2. Whether Tauri's iOS support is production-ready in 2026 or still alpha
3. What the actual user base looks like beyond the developer/creator
4. Whether iCloud file sync with Tauri on iOS is even feasible vs. needing a native Swift app
5. How much cleanup debt exists from the Electron→Tauri migration

## What I'm Avoiding
- The possibility that "intelligence features" are fundamentally wrong for a reader app — that the app should stay simple
- That iOS might require a completely separate Swift/SwiftUI app rather than a Tauri port
- That Windows users who vibe-code might have fundamentally different workflows
- That the app might be too niche for cross-platform investment
