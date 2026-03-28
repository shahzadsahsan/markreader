# Orient

## What is the problem?
v0.7 is a feature release with ~10 items spanning UI, data persistence, performance, and build tooling. The core creative question is how to visually group related files in the sidebar by folder without breaking recency sort. The rest are known features that need implementation.

## What is uncertain?
- **Folder indicator design**: Color dots? Colored left border? Folder name badges? Need to test 2-3 approaches to find the right one.
- **Scope risk**: 10 features in one beta is a lot. Some (auto-update, source maps) are infrastructure; others (related files, reading position) are user-facing. Mixing them risks shipping a buggy beta.
- **Performance meaning**: "Improve performance" is vague — need to identify the actual bottleneck (initial load? large file rendering? sidebar with 600+ files?).

## What am I avoiding?
- Shipping a half-baked beta that crashes like v0.6.0-0.6.3 did. The Tauri event system has proven fragile.
- Acknowledging that some of these features (auto-update without code signing) may be pure skeleton with no real functionality yet.
- The possibility that 2-3 sidebar view experiments is scope creep when one clear approach might emerge from thinking it through.
