---
session: aa2d26d3-c819-4c93-a3e4-2c45aeb42aeb
operation: deepthink
date: 2026-03-24 01:27
rounds: 5
---

# MarkScout v2 Roadmap: Build a roadmap for MarkScout, a local macOS markdown file viewer, to evolve from a generic file browser into an AI-workflow-aware reading companion. 

Current state: Electron + Next.js app, 473MB, watches folders for .md files, has 12 themes, full-text search, favorites, folder hierarchy. All features are generic — nothing specific to AI agent workflows.

Scope decisions:
1. Migrate to Tauri or Swift in v2 (not deferred)
2. Primary audience: agent power users (devs, writers, business using Claude Code, Codex, etc.)
3. Ambition: real distribution (Homebrew, Product Hunt)

Three confirmed features for v2:
- Session awareness: group files modified in the same time window
- Cross-reference detection: when PLAN.md mentions ARCHITECTURE.md, show navigable links
- Agent session timeline: visual timeline of file creation/modification

Key questions:
- Tauri (Rust + webview, ~30MB) vs Swift/SwiftUI (~15MB) — which is feasible given a TypeScript-oriented developer?
- What does "AI workflow aware" mean concretely for writers and business users, not just coders?
- What's the gap between current side project and Product Hunt-ready app?
- What else should change in v2 beyond the three confirmed features?

## Summary
Analysis completed over 5 rounds. **Stress-testing the roadmap — three specific failure scenarios:**

## Key Findings
- The codebase is ~4,743 lines of TypeScript frontend/backend + ~860 lines of Electron shell. The frontend (React components, API routes, lib utilities) is the real product. The Electron shell is thin: 
- **Alternative frame — starting from distribution, not features:**
- Phased Roadmap for MarkScout v2
- **Core assumption challenged:** "Tauri migration must happen in v2."
- **Stress-testing the roadmap — three specific failure scenarios:**

## Follow-ups
- Code signing ($99/yr Apple Developer) must be explicitly addressed as a hard prerequisite for non-developer audience expansion, not deferred to "nice to have" — Session reaching harvest. Becomes follow-up question.
