---
session: 53554451-60c6-467d-bde4-1e9b4c28611e
operation: problem_solve
date: 2026-03-27 02:53
rounds: 8
---

# Plan v0.7 beta for MarkScout (Tauri markdown reader). Need to implement ~10 features on a beta branch, build as "MarkScout Beta" so it can run alongside the production app.

Features requested:
1. Folder color indicators in sidebar — visual grouping by folder WITHOUT changing recency sort order. Test 2-3 visual approaches.
2. Reading position memory — remember scroll position per file, restore on return
3. Related files — show other files in same folder at bottom of document
4. Recent searches — remember last 10 searches
5. Most-edited sort option in Recents
6. Auto-update banner (skeleton — already have check_for_update Rust command)
7. Keyboard navigation audit and improvements
8. Performance improvements (600+ file sidebar, large doc rendering)
9. Source maps in release builds for better crash debugging

Context from scope answers:
- Build 2-3 sidebar indicator variants to test
- All features in one beta
- Auto-update = banner only (not signed yet)
- App must be named "MarkScout Beta" with separate bundle ID so both can run simultaneously

## Summary
Analysis completed over 8 rounds. Final commitment with specificity:

## Key Findings
- Full orientation with verified facts from code inspection:
- Deep analysis with verified data:
- Addressing the remaining constraint and deepening the analysis:
- Failure mode analysis — three scenarios where this beta goes wrong:
- Four distinct implementation approaches for the full v0.7 beta, including the uncomfortable one:
- Systematic evaluation of the top 2 approaches against criteria:
- Pre-mortem — three strongest objections to the current plan:
- Post-mortem projection: if this beta fails, what does the root cause analysis say?
- Final commitment with specificity:
