# MarkScout Project Context

## Overview
MarkScout is a local-only markdown reader built with Tauri (Rust + React).

## Architecture
- **Frontend:** React + TypeScript + Tailwind CSS
- **Backend:** Rust (Tauri 2.0)
- **Rendering:** markdown-it with anchor plugin + highlight.js

## Key Design Decisions
- Dark theme only for V1
- 16 color palettes ported from IDE themes
- JetBrains Mono for headings/code, Source Serif 4 for prose
