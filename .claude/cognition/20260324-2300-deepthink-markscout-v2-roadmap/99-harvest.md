# DeepThink Harvest: MarkScout v2 Roadmap

## Summary
MarkScout v2 should migrate from Electron+Next.js to Tauri+Vite+React (473MB → ~20MB), add three AI-workflow-aware features (session awareness, cross-references, timeline), and prepare for real distribution (code signing, Homebrew, Product Hunt). The migration is feasible because the frontend is pure React (4,743 lines, zero Next.js-specific features) and the Electron shell is thin (860 lines). Key risk: Rust compile latency in dev loop — mitigate by keeping the Tauri backend paper-thin (Rust for I/O only, all logic in TypeScript).

## Key Findings
- Swift/SwiftUI is NOT feasible for v2 — would require rewriting all 4,743 lines of web UI. Tauri preserves the React frontend.
- The current app has zero Next.js-specific features in components (no next/image, next/link, no server components) — Vite extraction is clean.
- Session detection needs both time AND directory proximity, not just time clustering, to avoid merging unrelated concurrent agent sessions.
- Code signing ($99/yr Apple Developer) is a hard prerequisite for non-developer audiences, not optional.
- The app's identity should shift from "markdown viewer" to "AI output intelligence layer" — the tagline "see what your AI agent just wrote" communicates more value.
- Most dangerous failure mode: dev loop friction from Rust compiles. Keep Rust backend to pure I/O (file read/write/watch), put all logic in TypeScript.

## Open Questions
- Exact Tauri app size with the full React frontend + highlight.js + custom fonts bundled
- Whether macOS WebKit renders markdown/code identically to Chromium (test early in Phase 0)
- Product Hunt launch timing: after session awareness (Phase 2) vs after timeline (Phase 4)

## Follow-ups
- /problem-solve "Should we launch on Product Hunt after Phase 2 (sessions) or Phase 4 (full feature set)?" — timing affects both story and polish
- /deepthink "What does the MarkScout landing page need to communicate to convert a Product Hunt visitor into a download?" — marketing angle
