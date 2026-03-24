# Orientation

## What I Know
- MarkScout is a local Electron + Next.js app, 473MB, watching ~610 markdown files
- Current features are generic file browser features (themes, search, favorites, folders) — nothing AI-workflow-specific
- The user builds fast and discovers by building — not a "write the spec first" person
- The app already has the raw ingredients for workflow awareness: file modification times, chokidar live events, content hashing for move tracking
- Tauri produces ~30MB apps, Swift/SwiftUI would be ~15MB, current Electron is 473MB
- The user wants to broaden beyond coders: writers, business users using Claude Code / Codex
- Three specific features from the /meta session: (1) session awareness, (2) cross-reference detection, (5) agent session timeline

## What I'm Uncertain About
- Would a Tauri migration preserve the fast iteration speed the user values? (Tauri uses Rust for backend — the user works in TypeScript)
- Would Swift be feasible given the user's existing web skillset?
- How do non-coder users (writers, business) actually generate markdown with AI agents? Is it the same folder structure or something different?
- Is the 610-file scale going to grow significantly with broader use cases?
- Can session detection work without git integration, or does it need it?
- Would cross-reference detection need markdown AST parsing or is regex sufficient?

## What I'm Avoiding
- The question of whether MarkScout should remain a side project vs. become a real product (changes the investment calculation dramatically)
- Whether the user should just build a VS Code extension instead (much larger distribution, much less packaging overhead)
- The possibility that Tauri migration would be a multi-week effort that kills momentum
- Whether "business users" is scope creep that dilutes the product identity
