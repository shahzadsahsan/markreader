# MarkScout v0.7 Beta — Implementation Plan

## Overview

Build 10 features on `v0.7-beta` branch as "MarkScout Beta" (separate bundle ID, coexists with production). Source maps first, incremental commits, one build test per feature.

## Pre-Flight

1. Create `v0.7-beta` branch from `main`
2. Change bundle ID: `com.markscout.app` → `com.markscout.beta` in `src-tauri/tauri.conf.json`
3. Change app name: `MarkScout` → `MarkScout Beta` in `src-tauri/tauri.conf.json`
4. Verify both apps can launch simultaneously
5. Commit: "Beta branch setup — separate bundle ID and app name"

## Implementation Order

### Commit 1: Source Maps
- Add `build: { sourcemap: true }` to `vite.config.ts`
- This is the highest-leverage single change — prevents repeating the v0.6 crash debugging failure (3 wrong guesses because minified stack traces were unreadable)

### Commit 2: Fix Keyboard Navigation
- `src/components/AppShell.tsx` line ~695: `k` is mapped to DOWN, should be UP (Vim convention)
- Swap: `j` = down, `k` = up
- Trivial 1-line fix

### Commit 3: Folder Color Indicators
- **Approach A only** (colored left border) — evaluation showed it clearly beats dot and background tint
- Add 2px left border to `FileItem` component, color derived from deterministic hash of `file.project`
- Use a curated palette of 12 muted, distinct hues (not random hash colors)
- ~20 unique projects exist across 600+ files — top 5 projects account for ~80% of files
- Border must be visually distinct from selected-file highlight (2px edge vs full-width background)
- Add settings toggle to enable/disable folder colors
- **Files**: `src/components/FileItem.tsx`, `src/styles/globals.css`

### Commit 4: Reading Position Memory
- Save `scrollTop` per file path to a `Map<string, number>` in AppShell state
- Persist to state.json via new field on UiState struct (Rust side needs `#[serde(default)]`)
- Restore scroll position AFTER markdown renders (use `requestAnimationFrame` after HTML injection)
- Cap at 200 most recent positions to prevent unbounded growth
- **Files**: `src/components/AppShell.tsx`, `src/components/MarkdownPreview.tsx`, `src-tauri/src/types.rs`, `src-tauri/src/commands/state_cmds.rs`, `src/lib/api.ts`

### Commit 5: Related Files
- Show other `.md` files in the same folder at bottom of document
- Only shown when: document > 20 lines AND folder has 2+ sibling files
- Render inside a collapsible `<details>` element so it doesn't dominate short docs
- Current file shown as disabled/highlighted in the list
- Clicking a related file navigates to it (uses existing `onSelectFile`)
- **Files**: `src/components/MarkdownPreview.tsx`

### Commit 6: Recent Searches
- Store last 10 search queries in `localStorage` (not state.json — simpler)
- Show as dropdown suggestions below the search input when focused and empty
- Clear individual items or clear all
- **Files**: `src/components/Sidebar.tsx`

### Commit 7: "Most Viewed" Sort
- Renamed from "most edited" — edit counting requires persistent counters that reset on restart
- "Most viewed" uses existing history data (view counts already tracked)
- Add sort toggle pill in RecentsView: "Recent" (default) | "Most viewed"
- Only applies when "All" time filter is selected (time-windowed views stay recency-sorted)
- **Files**: `src/components/RecentsView.tsx`, `src/lib/api.ts` (may need history data in files response)

### Commit 8: Auto-Update Banner Improvement
- `check_for_update` command already exists, banner already renders in AppShell
- Make the banner more prominent — sticky at top, with version number and "Download" link
- Banner dismisses permanently for that version (store dismissed version in localStorage)
- **Files**: `src/components/AppShell.tsx`

### Commit 9: Performance
- The sidebar renders all 600+ FileItem components on every state change
- React.memo is used on FileItem but parent AppShell re-renders on every file event
- Fix: batch Tauri file events — accumulate for 500ms before triggering state update (already partially done with pendingFilesRef, but the scan-complete flush re-renders everything)
- Consider: virtualized list (react-window) for sidebar if batching isn't enough
- **Files**: `src/components/AppShell.tsx`, possibly add `react-window` dependency

### Commit 10: Build & Install
- Build with `npx tauri build`
- Clean build cache
- Install to `/Applications/MarkScout Beta.app`
- Verify coexistence with production `MarkScout.app`

## Rust Changes Required

The `UiState` struct in `src-tauri/src/types.rs` needs new fields:

```rust
pub struct UiState {
    // ... existing fields ...
    #[serde(default)]
    pub scroll_positions: HashMap<String, f64>,  // path → scrollTop
}
```

The `save_ui_state` command in `src-tauri/src/commands/state_cmds.rs` needs the new parameter:

```rust
pub async fn save_ui_state(
    // ... existing params ...
    scroll_positions: Option<HashMap<String, f64>>,
) -> Result<(), String> {
```

Both use `#[serde(default)]` so production app ignores these fields gracefully.

## Key Design Decisions

- **One sidebar approach, not three**: Approach A (colored left border) scored 8.9/10 vs dot (8.0) and tint (6.5). Background tint fails on light palettes entirely.
- **Shared state.json**: Beta and production share the same state file. New fields use `#[serde(default)]` — production ignores them, no corruption risk.
- **"Most viewed" not "most edited"**: Edit counting requires persistent counters. View counting already has data via history tracking.
- **Recent searches in localStorage**: Simpler than adding to Rust state, and search history doesn't need to survive app reinstalls.

## Failure Modes & Safeguards

1. **State.json deserialization failure** → `#[serde(default)]` on all new fields
2. **Scroll restore fires before render** → `requestAnimationFrame` delay after HTML injection
3. **Folder color confused with selection** → 2px muted border vs full-width background highlight
4. **Related files dominating short docs** → collapsible `<details>`, min thresholds
5. **Source maps increase bundle size** → acceptable for desktop app (loads from disk, not network)

## Reversal Trigger

If Tier 1 (commits 1-5) produces >2 crash-fix patches, stop and ask user whether to proceed to Tier 2 (commits 6-10) or stabilize first.
