# Scope Answers (auto-mode — recommended defaults)

## Q1: "Understands your workflow" → **Option A: Session-aware file intelligence**
No AI/LLM needed. Detect changes since last open, group related files by project context (same-directory PLAN + ARCH + REQUIREMENTS = a "project cluster"), show staleness (last modified 30+ days = faded), surface "what changed" on launch. This is achievable with filesystem metadata alone.

## Q2: Migration → **Option A: Tauri in v1.0**
Keep Electron for v0.4-v0.5 (don't break what works). Plan Tauri migration for v1.0. This cuts the app from 500MB → ~30MB while keeping the web UI layer (React/TypeScript). The backend moves from Node.js to Rust (file watching, state management). This is a significant rewrite but the UI stays mostly intact.

## Q3: Audience → **Option A: AI power users broadly**
Not just coders. Anyone using Claude Code, Codex, Cursor, Windsurf for writing, research, business planning, content creation. These people generate .md artifacts but don't care about node_modules. The filter system already handles this — we just need to message it differently and add watch patterns that make sense for non-code directories (~/Documents, ~/Desktop).
