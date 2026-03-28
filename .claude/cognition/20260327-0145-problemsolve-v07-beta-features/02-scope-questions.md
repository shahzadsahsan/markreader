# Scope Questions

1. **Sidebar indicator approach**: Should we build 2-3 separate sidebar view variants to test, or design one approach that's clearly best and iterate on it?
   - A) One strong approach (colored left border per folder) — iterate on it
   - B) Build 2-3 tabs to compare — more exploration, more code

2. **Feature batching**: Ship all 10 features in one beta, or split into 2 batches?
   - A) All in one beta — user gets everything to test at once
   - B) Split: UI features first (sidebar, reading position, search), infrastructure second (auto-update, source maps, performance)

3. **Auto-update scope**: Full GitHub release check with download prompt, or just a "new version available" banner?
   - A) Banner only (we already have check_for_update) — minimal new code
   - B) Full download+install flow — significant Tauri plugin work
