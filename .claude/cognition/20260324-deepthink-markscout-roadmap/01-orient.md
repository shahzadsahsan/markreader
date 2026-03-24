# Orient

## What I Know

- MarkScout is ~506MB as an Electron app wrapping Next.js. DMG is ~160MB after pruning. This is large for what it does.
- The app currently: watches folders, filters noise, renders markdown, has themes, search, favorites, keyboard nav, auto-update from GitHub.
- The user's actual workflow: Claude Code and similar AI agents generate dozens of .md files — plans, specs, memory, research, architecture docs — scattered across project folders. MarkScout surfaces the human-readable ones.
- The user builds apps by vibe-coding with Claude — rapid iteration, not traditional dev. The tool should reflect this.
- Current tech: Electron 34 + Next.js 16 + chokidar + markdown-it. Heavy stack for a file reader.
- State persists to ~/.markscout/state.json. No cloud, no auth.
- The promise "understands your workflow" is aspirational — right now it's a filtered file browser, not a workflow-aware tool.

## What I'm Uncertain About

1. **Tauri vs Swift vs staying Electron**: Tauri would cut size dramatically (WebView + Rust backend, ~15-30MB) but means rewriting the backend. Swift/SwiftUI would be fully native but means rewriting everything. Electron works but is bloated.
2. **What "understands your workflow" actually means in practice**: Is it file grouping? Timeline awareness? Session detection? Git integration? This is vague and could go many directions.
3. **Non-coder audience**: Writers and business users don't have `~/Vibe Coding/` with node_modules. Their .md files are simpler. What do they actually need that's different from Obsidian or Typora?
4. **Competitive landscape**: Obsidian, Typora, MacDown, Marked 2 all exist. What's MarkScout's actual moat?
5. **Whether full-text search was the right call**: It adds complexity. Is filename + folder browsing sufficient for 610 files?

## What I'm Avoiding

- The uncomfortable truth that Electron + Next.js is massive overkill for a markdown reader and the "right" answer might be a full rewrite in Swift/AppKit.
- The possibility that the non-coder audience doesn't exist — people who use Claude Code ARE coders, and business users won't touch a terminal-generated markdown reader.
- That "understands your workflow" might require actual AI integration (LLM calls to categorize/summarize files) which contradicts the "local only, no API calls" constraint.
