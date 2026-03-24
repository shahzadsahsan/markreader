// MarkScout — File Commands
// Ports of /api/files and /api/file from the Next.js version.

use std::collections::HashMap;
use std::path::Path;

use tauri::Manager;

use crate::state::AppStateManager;
use crate::types::{FileContentResponse, FileEntry, FolderNode};
use crate::watcher::FileWatcher;

// ---------------------------------------------------------------------------
// Response envelope — mirrors the Next.js JSON shape
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FilesResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub files: Option<Vec<FileEntry>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub folders: Option<Vec<FolderNode>>,
    pub scan_complete: bool,
    pub total_files: usize,
}

// ---------------------------------------------------------------------------
// get_files — returns sidebar data for the requested view
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn get_files(
    view: Option<String>,
    app_handle: tauri::AppHandle,
) -> Result<FilesResponse, String> {
    let watcher = app_handle.state::<FileWatcher>();
    let state_mgr = app_handle.state::<AppStateManager>();

    let view = view.unwrap_or_else(|| "recents".to_string());

    let scan_complete = watcher.is_scan_complete();
    let total_files = watcher.total_files();

    match view.as_str() {
        "recents" => {
            let files = watcher.get_all_files_sorted_by_modified();
            Ok(FilesResponse {
                files: Some(files),
                folders: None,
                scan_complete,
                total_files,
            })
        }

        "folders" => {
            let all_files = watcher.get_all_files();
            let watched_dirs = watcher.get_watched_dirs();
            let folders = build_folder_tree(&all_files, &watched_dirs);
            Ok(FilesResponse {
                files: None,
                folders: Some(folders),
                scan_complete,
                total_files,
            })
        }

        "favorites" => {
            let favorites = state_mgr.get_favorites().await;
            let mut files: Vec<FileEntry> = Vec::new();
            for fav in &favorites {
                if let Some(entry) = watcher.get_entry(&fav.path) {
                    files.push(entry);
                }
            }
            Ok(FilesResponse {
                files: Some(files),
                folders: None,
                scan_complete,
                total_files,
            })
        }

        "history" => {
            let history = state_mgr.get_history().await;
            let mut files: Vec<FileEntry> = Vec::new();
            for h in &history {
                if let Some(entry) = watcher.get_entry(&h.path) {
                    // Clone and attach lastOpenedAt as a modified field for ordering
                    files.push(entry);
                }
            }
            Ok(FilesResponse {
                files: Some(files),
                folders: None,
                scan_complete,
                total_files,
            })
        }

        _ => {
            // Fall back to recents
            let files = watcher.get_all_files_sorted_by_modified();
            Ok(FilesResponse {
                files: Some(files),
                folders: None,
                scan_complete,
                total_files,
            })
        }
    }
}

// ---------------------------------------------------------------------------
// build_folder_tree — port of the TypeScript buildFolderTree
// ---------------------------------------------------------------------------

fn build_folder_tree(files: &[FileEntry], watched_dirs: &[String]) -> Vec<FolderNode> {
    let home_dir = dirs::home_dir()
        .map(|h| h.to_string_lossy().to_string())
        .unwrap_or_default();

    // node_map: absolute path -> FolderNode (mutable via index into a vec)
    // We use a HashMap of indices into a flat Vec for easy mutation.
    let mut nodes: Vec<FolderNode> = Vec::new();
    let mut path_to_idx: HashMap<String, usize> = HashMap::new();

    // Create root nodes for each watched dir
    for dir in watched_dirs {
        let display_name = if dir.starts_with(&home_dir) {
            format!("~{}", &dir[home_dir.len()..])
        } else {
            dir.clone()
        };
        let idx = nodes.len();
        nodes.push(FolderNode {
            name: display_name,
            path: dir.clone(),
            files: Vec::new(),
            children: Vec::new(),
            file_count: 0,
        });
        path_to_idx.insert(dir.clone(), idx);
    }

    for file in files {
        // Find the deepest watch dir that contains this file
        let watch_dir = watched_dirs
            .iter()
            .filter(|d| {
                file.path.starts_with(&format!("{}/", d)) || file.path.starts_with(&format!("{}/", d))
            })
            .max_by_key(|d| d.len());

        let watch_dir = match watch_dir {
            Some(d) => d.clone(),
            None => continue,
        };

        let rel = &file.path[watch_dir.len() + 1..];
        let parts: Vec<&str> = rel.split('/').collect();

        // Increment root file_count
        if let Some(&root_idx) = path_to_idx.get(&watch_dir) {
            nodes[root_idx].file_count += 1;
        }

        let mut current_path = watch_dir.clone();

        // Walk / create intermediate directory nodes
        for i in 0..parts.len().saturating_sub(1) {
            let child_path = format!("{}/{}", current_path, parts[i]);

            if !path_to_idx.contains_key(&child_path) {
                let child_idx = nodes.len();
                nodes.push(FolderNode {
                    name: parts[i].to_string(),
                    path: child_path.clone(),
                    files: Vec::new(),
                    children: Vec::new(),
                    file_count: 0,
                });
                path_to_idx.insert(child_path.clone(), child_idx);

                // Add child index to parent's children (we'll resolve later)
            }

            if let Some(&idx) = path_to_idx.get(&child_path) {
                nodes[idx].file_count += 1;
            }

            current_path = child_path;
        }

        // Add file to the leaf directory node
        if let Some(&idx) = path_to_idx.get(&current_path) {
            nodes[idx].files.push(file.clone());
        }
    }

    // Now build parent-child relationships by re-walking
    // We need to rebuild children vecs. Clear them first.
    for node in nodes.iter_mut() {
        node.children.clear();
    }

    // Collect all non-root paths and figure out their parents
    let all_paths: Vec<String> = path_to_idx.keys().cloned().collect();
    for p in &all_paths {
        if watched_dirs.contains(p) {
            continue; // root nodes have no parent
        }
        // parent path = everything before the last '/'
        if let Some(last_slash) = p.rfind('/') {
            let parent_path = &p[..last_slash];
            if let (Some(&parent_idx), Some(&child_idx)) =
                (path_to_idx.get(parent_path), path_to_idx.get(p.as_str()))
            {
                let child_clone = nodes[child_idx].clone();
                nodes[parent_idx].children.push(child_clone);
            }
        }
    }

    // Sort children and files alphabetically in every node
    fn sort_node(node: &mut FolderNode) {
        node.children.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        node.files.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        for child in node.children.iter_mut() {
            sort_node(child);
        }
    }

    // Extract root nodes, filter to those with content, sort
    let mut roots: Vec<FolderNode> = watched_dirs
        .iter()
        .filter_map(|d| path_to_idx.get(d).map(|&idx| nodes[idx].clone()))
        .filter(|n| n.file_count > 0)
        .collect();

    for root in roots.iter_mut() {
        sort_node(root);
    }
    roots.sort_by(|a, b| a.name.cmp(&b.name));

    roots
}

// ---------------------------------------------------------------------------
// get_file_content — returns rendered markdown content + metadata
// ---------------------------------------------------------------------------

const WORDS_PER_MINUTE: u32 = 200;

#[tauri::command]
pub async fn get_file_content(
    path: String,
    app_handle: tauri::AppHandle,
) -> Result<FileContentResponse, String> {
    let watcher = app_handle.state::<FileWatcher>();
    let state_mgr = app_handle.state::<AppStateManager>();

    // Security: resolve and validate the path is under a watched directory
    let resolved = std::fs::canonicalize(&path)
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_else(|_| path.clone());

    if !watcher.is_valid_path(&resolved) {
        return Err("Access denied: path is not under a watched directory".to_string());
    }

    // Read file content
    let content = tokio::fs::read_to_string(&resolved)
        .await
        .map_err(|e| format!("File not found: {}", e))?;

    // Word count and reading time
    let word_count = content
        .split_whitespace()
        .filter(|w| !w.is_empty())
        .count() as u32;
    let reading_time = std::cmp::max(1, (word_count + WORDS_PER_MINUTE - 1) / WORDS_PER_MINUTE);

    // Get entry from registry if available
    let entry = watcher.get_entry(&resolved).or_else(|| watcher.get_entry(&path));

    // Check if favorite
    let is_favorite = state_mgr.is_favorite(&resolved).await;

    // Get file metadata
    let metadata = tokio::fs::metadata(&resolved).await.ok();
    let size = metadata
        .as_ref()
        .map(|m| m.len())
        .unwrap_or(content.len() as u64);
    let modified_at = metadata
        .and_then(|m| {
            m.modified().ok().and_then(|t| {
                t.duration_since(std::time::UNIX_EPOCH)
                    .ok()
                    .map(|d| d.as_millis() as u64)
            })
        })
        .unwrap_or(0);

    let watched_dirs = watcher.get_watched_dirs();
    let file_name = Path::new(&resolved)
        .file_stem()
        .map(|s| s.to_string_lossy().to_string())
        .unwrap_or_default();

    Ok(FileContentResponse {
        path: resolved.clone(),
        content,
        name: entry.as_ref().map(|e| e.name.clone()).unwrap_or(file_name),
        project: entry
            .as_ref()
            .map(|e| e.project.clone())
            .unwrap_or_else(|| FileWatcher::project_for_path(&resolved, &watched_dirs)),
        relative_path: entry
            .as_ref()
            .map(|e| e.relative_path.clone())
            .unwrap_or_else(|| FileWatcher::relative_path_for(&resolved, &watched_dirs)),
        modified_at: entry.as_ref().map(|e| e.modified_at).unwrap_or(modified_at),
        size: entry.as_ref().map(|e| e.size).unwrap_or(size),
        word_count,
        reading_time,
        is_favorite,
        content_hash: entry.as_ref().map(|e| e.content_hash.clone()).unwrap_or_default(),
    })
}
