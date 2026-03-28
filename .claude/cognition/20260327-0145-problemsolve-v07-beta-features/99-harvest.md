# ProblemSolve Harvest: v0.7 Beta Plan

## Summary
Build all 10 features incrementally on a `v0.7-beta` branch, with source maps as commit #1 (highest-leverage single change). Use shared state.json with `#[serde(default)]` on new fields — no separate state file needed. Build as "MarkScout Beta" with separate bundle ID so both apps coexist. Folder indicators use Approach A (colored left border) only — evaluation showed it clearly wins over dot and background tint.

## Decision
Incremental implementation on beta branch with per-commit build testing. Confidence: 0.85

## Key Risks
- State.json schema change could break production deserialization → mitigated by `#[serde(default)]` on all new fields
- Scroll position restore fires before content renders → mitigated by waiting one frame after HTML injection
- Folder color border confused with selection indicator → mitigated by using muted/desaturated colors at 2px width vs full-width selection highlight

## Alternatives Considered
- **Ship only 3 features (scope cut)** — eliminated because user explicitly listed all features and this is a beta where stability matters less
- **All features in one big commit** — eliminated because untestable and unrevertable
- **Feature flags behind settings toggles** — eliminated as over-engineering for a beta
- **Separate state file for beta** — reversed mid-analysis because it breaks watch directory sharing

## Open Questions
- "Most edited" vs "most viewed" — implemented as "most viewed" using existing history data; true edit counting deferred to v0.8

## Follow-ups
- /problem-solve "v1.0 test suite strategy" — the app has zero tests, acceptable for beta but blocks production
