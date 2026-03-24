# Scope Questions

## Q1: What does "understands your workflow" mean concretely?
- **Option A (Recommended)**: Session-aware file intelligence — detect which files changed since last open, group related files (e.g., PLAN.md + ARCHITECTURE.md + REQUIREMENTS.md in same project), show staleness indicators, surface "what's new" on launch
- **Option B**: AI-powered — use a local LLM or API to categorize, summarize, and relate files semantically

## Q2: Should we migrate away from Electron?
- **Option A (Recommended)**: Tauri migration in v1.0 — keep Electron for v0.4-v0.5, plan Tauri rewrite for v1.0 (cuts app from 500MB to ~30MB, keeps web UI)
- **Option B**: Stay Electron — it works, the size is acceptable, and a rewrite is risky

## Q3: Who is the real audience?
- **Option A (Recommended)**: AI power users — anyone using Claude Code, Codex, Cursor, Windsurf, Aider, etc. who generates .md artifacts. This includes non-coders who use these tools for writing, research, and business planning.
- **Option B**: Developers only — keep the focus narrow on people with ~/code/ directories and node_modules
