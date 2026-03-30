// MarkScout — iCloud Drive Sync Module
// One-way mirror: copies ingested .md files + manifest.json to iCloud Drive.
// The iOS companion app reads from this folder for offline browsing.

use std::collections::HashSet;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use serde::{Deserialize, Serialize};
use tokio::sync::Mutex;

use crate::state::AppStateManager;
use crate::types::FileEntry;
use crate::watcher::FileWatcher;

// ---------------------------------------------------------------------------
// Manifest types (the contract between desktop and iOS)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncManifest {
    pub version: u32,
    pub synced_at: u64,
    pub file_count: u32,
    pub total_size: u64,
    pub files: Vec<SyncFileEntry>,
    pub favorites: Vec<SyncFavoriteEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncFileEntry {
    pub relative_path: String,
    pub name: String,
    pub project: String,
    pub modified_at: u64,
    pub size: u64,
    pub content_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncFavoriteEntry {
    pub relative_path: String,
    pub content_hash: String,
    pub starred_at: u64,
}

// ---------------------------------------------------------------------------
// Sync status (returned to frontend)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SyncStatus {
    pub enabled: bool,
    pub available: bool,
    pub last_synced_at: Option<u64>,
    pub file_count: u32,
    pub total_size: u64,
    pub icloud_path: String,
    pub error: Option<String>,
}

// ---------------------------------------------------------------------------
// SyncManager
// ---------------------------------------------------------------------------

pub struct SyncManager {
    syncing: Mutex<bool>,
}

impl SyncManager {
    pub fn new() -> Self {
        Self {
            syncing: Mutex::new(false),
        }
    }

    /// Check if iCloud Drive is available on this Mac.
    pub fn is_icloud_available() -> bool {
        icloud_drive_dir().is_some()
    }

    /// Get the MarkScout sync directory inside iCloud Drive.
    fn sync_dir() -> Option<PathBuf> {
        icloud_drive_dir().map(|d| d.join("MarkScout"))
    }

    /// Get the files subdirectory inside the sync dir.
    fn files_dir() -> Option<PathBuf> {
        Self::sync_dir().map(|d| d.join("files"))
    }

    /// Run a full sync: copy all registry files to iCloud, write manifest, prune orphans.
    pub async fn full_sync(
        &self,
        watcher: &FileWatcher,
        state_mgr: &AppStateManager,
    ) -> Result<SyncStatus, String> {
        // Prevent concurrent syncs
        let mut lock = self.syncing.lock().await;
        if *lock {
            return Err("Sync already in progress".into());
        }
        *lock = true;
        let result = self.do_sync(watcher, state_mgr).await;
        *lock = false;
        result
    }

    async fn do_sync(
        &self,
        watcher: &FileWatcher,
        state_mgr: &AppStateManager,
    ) -> Result<SyncStatus, String> {
        let sync_dir = Self::sync_dir()
            .ok_or("iCloud Drive not available")?;
        let files_dir = Self::files_dir()
            .ok_or("iCloud Drive not available")?;

        // Ensure directories exist
        std::fs::create_dir_all(&files_dir)
            .map_err(|e| format!("Failed to create sync directory: {}", e))?;

        let prefs = state_mgr.get_preferences().await;
        let threshold = prefs.sync_size_threshold.unwrap_or(512_000);
        let watched_dirs = prefs.watch_dirs.clone();

        // Get all files from registry
        let all_files = watcher.get_all_files();

        // Filter by size threshold and build sync entries
        let mut sync_files: Vec<(FileEntry, String)> = Vec::new(); // (entry, relative_path)
        let mut total_size: u64 = 0;

        for file in &all_files {
            if file.size > threshold {
                continue;
            }

            let rel = build_sync_relative_path(&file.path, &file.project, &watched_dirs);
            sync_files.push((file.clone(), rel));
            total_size += file.size;
        }

        // Copy files to iCloud mirror
        let mut synced_paths: HashSet<String> = HashSet::new();

        for (file, rel_path) in &sync_files {
            let dest = files_dir.join(rel_path);

            // Create parent directories
            if let Some(parent) = dest.parent() {
                let _ = std::fs::create_dir_all(parent);
            }

            // Only copy if source is newer or file doesn't exist
            let should_copy = if dest.exists() {
                let dest_mtime = std::fs::metadata(&dest)
                    .and_then(|m| m.modified())
                    .ok()
                    .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
                    .map(|d| d.as_millis() as u64)
                    .unwrap_or(0);
                file.modified_at > dest_mtime
            } else {
                true
            };

            if should_copy {
                if let Err(e) = std::fs::copy(&file.path, &dest) {
                    log::warn!("[Sync] Failed to copy {}: {}", file.path, e);
                    continue;
                }
            }

            synced_paths.insert(rel_path.clone());
        }

        // Prune orphan files from iCloud mirror
        prune_orphans(&files_dir, &synced_paths);

        // Build manifest
        let favorites = state_mgr.get_favorites().await;
        let manifest = SyncManifest {
            version: 1,
            synced_at: now_millis(),
            file_count: sync_files.len() as u32,
            total_size,
            files: sync_files.iter().map(|(f, rel)| SyncFileEntry {
                relative_path: rel.clone(),
                name: f.name.clone(),
                project: f.project.clone(),
                modified_at: f.modified_at,
                size: f.size,
                content_hash: f.content_hash.clone(),
            }).collect(),
            favorites: favorites.iter().filter_map(|fav| {
                // Find the file in sync_files by path to get the relative_path
                sync_files.iter()
                    .find(|(f, _)| f.path == fav.path)
                    .map(|(_, rel)| SyncFavoriteEntry {
                        relative_path: rel.clone(),
                        content_hash: fav.content_hash.clone(),
                        starred_at: fav.starred_at,
                    })
            }).collect(),
        };

        // Write manifest atomically
        let manifest_path = sync_dir.join("manifest.json");
        let tmp_path = sync_dir.join("manifest.json.tmp");
        let json = serde_json::to_string_pretty(&manifest)
            .map_err(|e| format!("Failed to serialize manifest: {}", e))?;
        std::fs::write(&tmp_path, &json)
            .map_err(|e| format!("Failed to write manifest tmp: {}", e))?;
        std::fs::rename(&tmp_path, &manifest_path)
            .map_err(|e| format!("Failed to rename manifest: {}", e))?;

        let status = SyncStatus {
            enabled: true,
            available: true,
            last_synced_at: Some(manifest.synced_at),
            file_count: manifest.file_count,
            total_size: manifest.total_size,
            icloud_path: sync_dir.to_string_lossy().to_string(),
            error: None,
        };

        log::info!(
            "[Sync] Complete: {} files, {} bytes synced to iCloud",
            status.file_count, status.total_size
        );

        Ok(status)
    }

    /// Incremental sync: handle a single file add/change/remove.
    pub async fn incremental_sync(
        &self,
        event_type: &str,
        file_path: &str,
        watcher: &FileWatcher,
        state_mgr: &AppStateManager,
    ) -> Result<(), String> {
        let prefs = state_mgr.get_preferences().await;
        if !prefs.sync_enabled.unwrap_or(false) {
            return Ok(());
        }

        let files_dir = match Self::files_dir() {
            Some(d) => d,
            None => return Ok(()), // iCloud not available, silently skip
        };

        let watched_dirs = prefs.watch_dirs.clone();
        let threshold = prefs.sync_size_threshold.unwrap_or(512_000);

        match event_type {
            "file-added" | "file-changed" => {
                if let Some(entry) = watcher.get_entry(file_path) {
                    if entry.size > threshold {
                        return Ok(());
                    }

                    let rel = build_sync_relative_path(&entry.path, &entry.project, &watched_dirs);
                    let dest = files_dir.join(&rel);

                    if let Some(parent) = dest.parent() {
                        let _ = std::fs::create_dir_all(parent);
                    }

                    std::fs::copy(&entry.path, &dest)
                        .map_err(|e| format!("Sync copy failed: {}", e))?;
                }
            }
            "file-removed" => {
                // Find and remove the mirrored file
                // Walk the files_dir to find any file matching this path
                if let Some(entry) = find_mirror_for_source(&files_dir, file_path, &watched_dirs) {
                    let _ = std::fs::remove_file(&entry);
                    // Clean up empty parent dirs
                    if let Some(parent) = entry.parent() {
                        let _ = remove_empty_parents(parent, &files_dir);
                    }
                }
            }
            _ => {}
        }

        // Re-write manifest after incremental changes
        // (debounced by the caller — watcher already debounces at 100ms)
        self.write_manifest(watcher, state_mgr).await?;

        Ok(())
    }

    /// Write just the manifest (without re-copying files).
    async fn write_manifest(
        &self,
        watcher: &FileWatcher,
        state_mgr: &AppStateManager,
    ) -> Result<(), String> {
        let sync_dir = match Self::sync_dir() {
            Some(d) => d,
            None => return Ok(()),
        };

        let prefs = state_mgr.get_preferences().await;
        let threshold = prefs.sync_size_threshold.unwrap_or(512_000);
        let watched_dirs = prefs.watch_dirs.clone();

        let all_files = watcher.get_all_files();
        let sync_files: Vec<(FileEntry, String)> = all_files.iter()
            .filter(|f| f.size <= threshold)
            .map(|f| {
                let rel = build_sync_relative_path(&f.path, &f.project, &watched_dirs);
                (f.clone(), rel)
            })
            .collect();

        let total_size: u64 = sync_files.iter().map(|(f, _)| f.size).sum();
        let favorites = state_mgr.get_favorites().await;

        let manifest = SyncManifest {
            version: 1,
            synced_at: now_millis(),
            file_count: sync_files.len() as u32,
            total_size,
            files: sync_files.iter().map(|(f, rel)| SyncFileEntry {
                relative_path: rel.clone(),
                name: f.name.clone(),
                project: f.project.clone(),
                modified_at: f.modified_at,
                size: f.size,
                content_hash: f.content_hash.clone(),
            }).collect(),
            favorites: favorites.iter().filter_map(|fav| {
                sync_files.iter()
                    .find(|(f, _)| f.path == fav.path)
                    .map(|(_, rel)| SyncFavoriteEntry {
                        relative_path: rel.clone(),
                        content_hash: fav.content_hash.clone(),
                        starred_at: fav.starred_at,
                    })
            }).collect(),
        };

        let manifest_path = sync_dir.join("manifest.json");
        let tmp_path = sync_dir.join("manifest.json.tmp");
        let json = serde_json::to_string_pretty(&manifest)
            .map_err(|e| format!("Failed to serialize manifest: {}", e))?;
        std::fs::write(&tmp_path, &json)
            .map_err(|e| format!("Failed to write manifest: {}", e))?;
        std::fs::rename(&tmp_path, &manifest_path)
            .map_err(|e| format!("Failed to rename manifest: {}", e))?;

        Ok(())
    }

    /// Get current sync status for the frontend.
    pub async fn get_status(&self, state_mgr: &AppStateManager) -> SyncStatus {
        let prefs = state_mgr.get_preferences().await;
        let enabled = prefs.sync_enabled.unwrap_or(false);
        let available = Self::is_icloud_available();

        if !enabled || !available {
            return SyncStatus {
                enabled,
                available,
                last_synced_at: None,
                file_count: 0,
                total_size: 0,
                icloud_path: Self::sync_dir()
                    .map(|p| p.to_string_lossy().to_string())
                    .unwrap_or_default(),
                error: if !available {
                    Some("iCloud Drive is not enabled. Enable it in System Settings > Apple ID > iCloud > iCloud Drive.".into())
                } else {
                    None
                },
            };
        }

        // Read manifest to get last sync info
        if let Some(sync_dir) = Self::sync_dir() {
            let manifest_path = sync_dir.join("manifest.json");
            if let Ok(data) = std::fs::read_to_string(&manifest_path) {
                if let Ok(manifest) = serde_json::from_str::<SyncManifest>(&data) {
                    return SyncStatus {
                        enabled,
                        available,
                        last_synced_at: Some(manifest.synced_at),
                        file_count: manifest.file_count,
                        total_size: manifest.total_size,
                        icloud_path: sync_dir.to_string_lossy().to_string(),
                        error: None,
                    };
                }
            }
        }

        SyncStatus {
            enabled,
            available,
            last_synced_at: None,
            file_count: 0,
            total_size: 0,
            icloud_path: Self::sync_dir()
                .map(|p| p.to_string_lossy().to_string())
                .unwrap_or_default(),
            error: None,
        }
    }

    /// Disable sync: remove the iCloud mirror entirely.
    pub fn cleanup() -> Result<(), String> {
        if let Some(sync_dir) = Self::sync_dir() {
            if sync_dir.exists() {
                std::fs::remove_dir_all(&sync_dir)
                    .map_err(|e| format!("Failed to remove sync directory: {}", e))?;
            }
        }
        Ok(())
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Get the iCloud Drive root directory, if available.
fn icloud_drive_dir() -> Option<PathBuf> {
    let dir = dirs::home_dir()?.join("Library/Mobile Documents/com~apple~CloudDocs");
    if dir.exists() && dir.is_dir() {
        Some(dir)
    } else {
        None
    }
}

fn now_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as u64
}

/// Build a sync-friendly relative path: {project}/{rest_of_relative_path}
/// Falls back to just the filename if path structure is unexpected.
fn build_sync_relative_path(abs_path: &str, project: &str, watched_dirs: &[String]) -> String {
    // Find which watch dir this file is under
    for dir in watched_dirs {
        let prefix = if dir.ends_with('/') { dir.clone() } else { format!("{}/", dir) };
        if abs_path.starts_with(&prefix) {
            let rel = &abs_path[prefix.len()..];
            return rel.to_string();
        }
    }
    // Fallback: project/filename
    let filename = Path::new(abs_path)
        .file_name()
        .map(|f| f.to_string_lossy().to_string())
        .unwrap_or_else(|| "unknown.md".to_string());
    format!("{}/{}", project, filename)
}

/// Find the mirror file for a source path.
fn find_mirror_for_source(files_dir: &Path, source_path: &str, watched_dirs: &[String]) -> Option<PathBuf> {
    for dir in watched_dirs {
        let prefix = if dir.ends_with('/') { dir.clone() } else { format!("{}/", dir) };
        if source_path.starts_with(&prefix) {
            let rel = &source_path[prefix.len()..];
            let mirror = files_dir.join(rel);
            if mirror.exists() {
                return Some(mirror);
            }
        }
    }
    None
}

/// Recursively remove empty parent directories up to (but not including) the stop directory.
fn remove_empty_parents(dir: &Path, stop_at: &Path) -> std::io::Result<()> {
    if dir == stop_at || !dir.starts_with(stop_at) {
        return Ok(());
    }
    if dir.is_dir() {
        if std::fs::read_dir(dir)?.next().is_none() {
            std::fs::remove_dir(dir)?;
            if let Some(parent) = dir.parent() {
                remove_empty_parents(parent, stop_at)?;
            }
        }
    }
    Ok(())
}

/// Walk the files_dir and remove any files not in the synced_paths set.
fn prune_orphans(files_dir: &Path, synced_paths: &HashSet<String>) {
    if !files_dir.exists() {
        return;
    }
    prune_recursive(files_dir, files_dir, synced_paths);
}

fn prune_recursive(current: &Path, root: &Path, synced_paths: &HashSet<String>) {
    let entries = match std::fs::read_dir(current) {
        Ok(e) => e,
        Err(_) => return,
    };

    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            prune_recursive(&path, root, synced_paths);
            // Remove empty dirs after pruning children
            if let Ok(mut entries) = std::fs::read_dir(&path) {
                if entries.next().is_none() {
                    let _ = std::fs::remove_dir(&path);
                }
            }
        } else {
            // Check if this file's relative path is in the synced set
            if let Ok(rel) = path.strip_prefix(root) {
                let rel_str = rel.to_string_lossy().to_string();
                if !synced_paths.contains(&rel_str) {
                    let _ = std::fs::remove_file(&path);
                    log::info!("[Sync] Pruned orphan: {}", rel_str);
                }
            }
        }
    }
}
