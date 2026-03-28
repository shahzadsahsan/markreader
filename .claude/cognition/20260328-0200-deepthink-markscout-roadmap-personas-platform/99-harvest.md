# DeepThink Harvest: MarkScout Roadmap, Personas & Cross-Platform Strategy

## Summary
MarkScout's existing intelligence features are mostly practical and worth keeping (related files, move tracking), but ~400 lines of dead code (Smart Collections, File Links parser) should be deleted. The highest-value next features are clickable markdown links and Cmd+P quick open. Windows via Tauri is low-effort/high-value; iOS should be native SwiftUI with iCloud Drive's built-in sync rather than Tauri iOS (which has no App Store track record and requires custom Swift plugins for iCloud access).

## Key Findings
- Smart Collections and File Links parser are dead code — built but never wired to UI
- View count tracking is kept in backend (free) but UI was correctly removed
- iCloud sync for iOS doesn't need a custom export feature — native iCloud Drive sync works, iOS app just needs the filter logic ported to Swift
- Tauri iOS has zero confirmed App Store apps and requires custom Swift plugins for iCloud Drive access
- Three user personas defined: Prolific Builder (primary), Reviewer (secondary), Mobile Reader (aspirational)
- The "platform vs tool" question was tested — tool wins. Keep it simple.

## Open Questions
- How much iCloud storage does ~/Vibe Coding/ require? User needs sufficient iCloud plan.
- Will Windows users' file paths (OneDrive, WSL) cause edge cases with the watcher?
- Do three distinct personas actually exist, or is it one user at different moments?

## Follow-ups
- /deepthink "Design the iOS SwiftUI app architecture — what's the minimum viable reader with iCloud Drive file browsing?" — when ready to build iOS
- /problem-solve "Should we build Windows or iOS first given maintenance burden?" — when ready to commit to cross-platform
