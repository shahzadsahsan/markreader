// MarkScout — Search Command
// Port of /api/search from the Next.js version.
// Case-insensitive substring search across filename and file content.

use tauri::Manager;

use crate::types::SearchResult;
use crate::watcher::FileWatcher;

const MAX_FILE_SIZE: u64 = 500 * 1024; // Skip files > 500KB
const DEFAULT_LIMIT: u32 = 30;
const SNIPPET_CONTEXT: usize = 60; // chars of context on each side of match

// ---------------------------------------------------------------------------
// Response envelope
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchResponse {
    pub results: Vec<SearchResult>,
    pub query: String,
}

// ---------------------------------------------------------------------------
// search_files
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn search_files(
    query: String,
    limit: Option<u32>,
    app_handle: tauri::AppHandle,
) -> Result<SearchResponse, String> {
    let q = query.trim().to_string();
    if q.len() < 2 {
        return Ok(SearchResponse {
            results: vec![],
            query: q,
        });
    }

    let limit = std::cmp::min(limit.unwrap_or(DEFAULT_LIMIT), 100) as usize;
    let watcher = app_handle.state::<FileWatcher>();

    // Get all files sorted by modified time (most recent first), skip large files
    let mut files = watcher.get_all_files_sorted_by_modified();
    files.retain(|f| f.size <= MAX_FILE_SIZE);

    let query_lower = q.to_lowercase();
    let q_clone = q.clone();

    // Do the search in a blocking task since it reads many files from disk
    let results = tokio::task::spawn_blocking(move || {
        let mut results: Vec<SearchResult> = Vec::new();

        for file in &files {
            if results.len() >= limit {
                break;
            }

            // Read file content
            let content = match std::fs::read_to_string(&file.path) {
                Ok(c) => c,
                Err(_) => continue,
            };

            let content_lower = content.to_lowercase();

            // Check if content contains the query
            if !content_lower.contains(&query_lower) {
                continue;
            }

            // Build snippet and count matches
            let (snippet, line_number, match_count) =
                build_snippet(&content, &q_clone, &query_lower);

            if match_count == 0 {
                continue;
            }

            results.push(SearchResult {
                file: file.clone(),
                snippet,
                line_number,
                match_count,
            });
        }

        results
    })
    .await
    .map_err(|e| format!("Search task failed: {}", e))?;

    Ok(SearchResponse {
        results,
        query: q,
    })
}

// ---------------------------------------------------------------------------
// build_snippet — extract context around first match
// ---------------------------------------------------------------------------

fn build_snippet(content: &str, query: &str, query_lower: &str) -> (String, u32, u32) {
    let content_lower = content.to_lowercase();

    let first_idx = match content_lower.find(query_lower) {
        Some(idx) => idx,
        None => return (String::new(), 0, 0),
    };

    // Count all matches
    let mut match_count: u32 = 0;
    let mut search_from = 0;
    loop {
        match content_lower[search_from..].find(query_lower) {
            Some(relative_idx) => {
                match_count += 1;
                search_from += relative_idx + query_lower.len();
            }
            None => break,
        }
    }

    // Line number of first match
    let line_number = content[..first_idx].matches('\n').count() as u32 + 1;

    // Build snippet around first match
    let start = first_idx.saturating_sub(SNIPPET_CONTEXT);
    let end = std::cmp::min(content.len(), first_idx + query.len() + SNIPPET_CONTEXT);
    let mut snippet = content[start..end]
        .replace('\n', " ")
        .split_whitespace()
        .collect::<Vec<&str>>()
        .join(" ");

    if start > 0 {
        snippet = format!("...{}", snippet);
    }
    if end < content.len() {
        snippet = format!("{}...", snippet);
    }

    (snippet, line_number, match_count)
}
