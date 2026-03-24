// MarkScout — Smart File Filtering (Rust port of src/lib/filters.ts + presets.ts)

use std::sync::LazyLock;

use regex::{Regex, RegexSet};

use crate::types::{FilterConfig, FilterPreset, FilterPresetId};

// ---------------------------------------------------------------------------
// Chokidar-level ignored directories (path segments to skip entirely)
// ---------------------------------------------------------------------------

pub static IGNORED_DIRS: &[&str] = &[
    "node_modules",
    ".next",
    ".vercel",
    ".git",
    "dist",
    "build",
    "out",
    "venv",
    ".venv",
    ".pytest_cache",
    "site-packages",
    ".dist-info",
    "coverage",
    "__pycache__",
];

/// Additional `.claude/` sub-paths that are always ignored.
pub static IGNORED_CLAUDE_SUBPATHS: &[&str] = &[
    ".claude/plugins/cache",
    ".claude/shell-snapshots",
    ".claude/session-env",
    ".claude/debug",
    ".claude/telemetry",
    ".claude/todos",
    ".claude/orchestration",
    ".claude/worktrees",
];

// ---------------------------------------------------------------------------
// Post-discovery filename exclusions (compiled regex set)
// ---------------------------------------------------------------------------

static EXCLUDED_FILENAME_PATTERNS: &[&str] = &[
    r"(?i)^LICENSE\.md$",
    r"(?i)^LICENCE\.md$",
    r"(?i)^CHANGELOG\.md$",
    r"(?i)^CHANGES\.md$",
    r"(?i)^HISTORY\.md$",
    r"(?i)^CODE_OF_CONDUCT\.md$",
    r"(?i)^SECURITY\.md$",
    r"(?i)^CONTRIBUTING\.md$",
    r"^\.project-description\.md$",
    r"^99-harvest\.md$",
    r"^0[0-3]-(enter|orient|scope-).*\.md$",
];

static EXCLUDED_FILENAMES: LazyLock<RegexSet> = LazyLock::new(|| {
    RegexSet::new(EXCLUDED_FILENAME_PATTERNS).expect("Invalid excluded filename regex")
});

// ---------------------------------------------------------------------------
// Filter Presets (port of presets.ts)
// ---------------------------------------------------------------------------

pub static DEFAULT_PRESETS: LazyLock<Vec<FilterPreset>> = LazyLock::new(|| {
    vec![
        // --- Generic presets ---
        FilterPreset {
            id: FilterPresetId::ReadmeFiles,
            category: "general".into(),
            label: "README files".into(),
            description: "Hide README.md files across all projects".into(),
            match_count: None,
            path_patterns: vec![],
            name_patterns: vec![r"^README\.md$".into()],
        },
        FilterPreset {
            id: FilterPresetId::LicenseFiles,
            category: "general".into(),
            label: "License & contributing".into(),
            description: "Hide LICENSE, LICENSE.md, CONTRIBUTING.md".into(),
            match_count: None,
            path_patterns: vec![],
            name_patterns: vec![r"^(LICENSE|CONTRIBUTING)(\.md)?$".into()],
        },
        FilterPreset {
            id: FilterPresetId::ChangelogFiles,
            category: "general".into(),
            label: "Changelogs".into(),
            description: "Hide CHANGELOG, CHANGES files".into(),
            match_count: None,
            path_patterns: vec![],
            name_patterns: vec![r"^(CHANGELOG|CHANGES)(\.md)?$".into()],
        },
        FilterPreset {
            id: FilterPresetId::DotfileConfigs,
            category: "general".into(),
            label: "Dotfile configs".into(),
            description: "Hide dotfile config markdown like .github/*.md".into(),
            match_count: None,
            path_patterns: vec![".github/".into()],
            name_patterns: vec![],
        },
        // --- Claude Code presets ---
        FilterPreset {
            id: FilterPresetId::ClaudePlugins,
            category: "claude".into(),
            label: "Plugin & agent docs".into(),
            description: "Reference docs, skills, and configs inside plugins/ and agents/".into(),
            match_count: None,
            path_patterns: vec!["plugins/".into(), "agents/".into()],
            name_patterns: vec![],
        },
        FilterPreset {
            id: FilterPresetId::ClaudeSkills,
            category: "claude".into(),
            label: "Skill definitions".into(),
            description: "SKILL.md files used by Claude Code commands".into(),
            match_count: None,
            path_patterns: vec![],
            name_patterns: vec![r"^SKILL\.md$".into()],
        },
        FilterPreset {
            id: FilterPresetId::ClaudeSessions,
            category: "claude".into(),
            label: "RVRY deepthink sessions".into(),
            description: "Session logs from /deepthink, /think, /challenge in .rvry/".into(),
            match_count: None,
            path_patterns: vec![".rvry/sessions/".into(), ".rvry/".into()],
            name_patterns: vec![],
        },
        FilterPreset {
            id: FilterPresetId::ClaudePipeline,
            category: "claude".into(),
            label: "GSD pipeline artifacts".into(),
            description: "Planning, verification, and UAT files in .planning/ directories".into(),
            match_count: None,
            path_patterns: vec![".planning/".into()],
            name_patterns: vec![],
        },
        FilterPreset {
            id: FilterPresetId::ClaudeMemory,
            category: "claude".into(),
            label: "Claude project memory".into(),
            description: "MEMORY.md and memory/ folder files Claude uses for context".into(),
            match_count: None,
            path_patterns: vec!["/memory/".into()],
            name_patterns: vec![r"^MEMORY\.md$".into()],
        },
        FilterPreset {
            id: FilterPresetId::ClaudePlans,
            category: "claude".into(),
            label: "Claude plan files".into(),
            description: "Temporary plan files in .claude/plans/".into(),
            match_count: None,
            path_patterns: vec!["plans/".into()],
            name_patterns: vec![],
        },
        FilterPreset {
            id: FilterPresetId::ClaudeCognition,
            category: "claude".into(),
            label: "Claude cognition & tasks".into(),
            description: "Scheduled tasks, cognition sessions, and worktree artifacts".into(),
            match_count: None,
            path_patterns: vec![
                ".claude/scheduled-tasks/".into(),
                ".claude/cognition/".into(),
            ],
            name_patterns: vec![],
        },
    ]
});

// ---------------------------------------------------------------------------
// Path-level exclusion checks
// ---------------------------------------------------------------------------

/// Check if a path contains an ignored directory segment.
pub fn is_excluded_path(path: &str) -> bool {
    for dir in IGNORED_DIRS {
        // Check for /dir/ or path starting with dir/
        let segment = format!("/{}/", dir);
        if path.contains(&segment) {
            return true;
        }
        let prefix = format!("{}/", dir);
        if path.starts_with(&prefix) {
            return true;
        }
    }

    // Check .claude sub-paths
    for subpath in IGNORED_CLAUDE_SUBPATHS {
        if path.contains(subpath) {
            return true;
        }
    }

    false
}

/// Check if a path matches user-configured path exclusions (simple glob).
pub fn is_user_excluded_path(path: &str, user_filters: &FilterConfig) -> bool {
    for glob in &user_filters.excluded_paths {
        if let Some(re) = glob_to_regex(glob) {
            if re.is_match(path) {
                return true;
            }
        }
    }
    false
}

/// Convert a simple glob pattern to a regex.
fn glob_to_regex(glob: &str) -> Option<Regex> {
    let mut pattern = regex::escape(glob);
    pattern = pattern.replace(r"\*\*", ".*");
    pattern = pattern.replace(r"\*", "[^/]*");
    pattern = pattern.replace(r"\?", "[^/]");
    Regex::new(&pattern).ok()
}

// ---------------------------------------------------------------------------
// Filename-level exclusion checks
// ---------------------------------------------------------------------------

/// Check if a filename matches default excluded patterns.
pub fn is_excluded_file(filename: &str) -> bool {
    EXCLUDED_FILENAMES.is_match(filename)
}

/// Check if a filename matches user-configured name exclusions.
pub fn is_user_excluded_file(filename: &str, user_filters: &FilterConfig) -> bool {
    for pattern in &user_filters.excluded_names {
        if let Ok(re) = Regex::new(pattern) {
            if re.is_match(filename) {
                return true;
            }
        }
    }
    false
}

// ---------------------------------------------------------------------------
// Preset matching
// ---------------------------------------------------------------------------

/// Check if a file matches a specific preset's patterns.
pub fn matches_preset(path: &str, filename: &str, preset: &FilterPreset) -> bool {
    // Check path patterns (substring match)
    for pattern in &preset.path_patterns {
        if path.contains(pattern.as_str()) {
            return true;
        }
    }

    // Check name patterns (regex)
    for pattern in &preset.name_patterns {
        if let Ok(re) = Regex::new(pattern) {
            if re.is_match(filename) {
                return true;
            }
        }
    }

    false
}

/// Check if a file matches any active preset. Returns the matching preset ID or None.
pub fn matches_active_preset(
    path: &str,
    filename: &str,
    active_presets: &[FilterPresetId],
) -> Option<FilterPresetId> {
    for preset_id in active_presets {
        if let Some(preset) = DEFAULT_PRESETS.iter().find(|p| &p.id == preset_id) {
            if matches_preset(path, filename, preset) {
                return Some(preset_id.clone());
            }
        }
    }
    None
}

// ---------------------------------------------------------------------------
// Combined inclusion check
// ---------------------------------------------------------------------------

/// Determine whether a file should be included in the file list.
///
/// A file is **excluded** if any of the following are true:
/// 1. Its path traverses an ignored directory
/// 2. Its filename matches a default exclusion pattern
/// 3. Its path matches a user-configured path exclusion
/// 4. Its filename matches a user-configured name exclusion
/// 5. It matches an active filter preset
/// 6. Its size is below the configured minimum
/// 7. Its path is inside an excluded folder
pub fn should_include_file(
    path: &str,
    filename: &str,
    active_presets: &[FilterPresetId],
    user_filters: &FilterConfig,
    min_size: u64,
    file_size: u64,
    excluded_folders: &[String],
) -> bool {
    // 1. Ignored directory
    if is_excluded_path(path) {
        return false;
    }

    // 2. Default filename exclusion
    if is_excluded_file(filename) {
        return false;
    }

    // 3. User path exclusion
    if is_user_excluded_path(path, user_filters) {
        return false;
    }

    // 4. User filename exclusion
    if is_user_excluded_file(filename, user_filters) {
        return false;
    }

    // 5. Active preset match
    if matches_active_preset(path, filename, active_presets).is_some() {
        return false;
    }

    // 6. Minimum file size
    if min_size > 0 && file_size < min_size {
        return false;
    }

    // 7. Excluded folders
    for folder in excluded_folders {
        if path.starts_with(folder.as_str()) {
            return false;
        }
    }

    true
}

/// Count how many files each preset would match from a file list.
pub fn count_preset_matches(
    files: &[(String, String)], // (path, filename) pairs
) -> std::collections::HashMap<FilterPresetId, u32> {
    let mut counts = std::collections::HashMap::new();
    for preset in DEFAULT_PRESETS.iter() {
        let mut count = 0u32;
        for (path, name) in files {
            if matches_preset(path, name, preset) {
                count += 1;
            }
        }
        counts.insert(preset.id.clone(), count);
    }
    counts
}
