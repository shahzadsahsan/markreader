// MarkScout — Sync Tauri Commands

use tauri::Manager;

use crate::state::AppStateManager;
use crate::sync::{SyncManager, SyncStatus};
use crate::watcher::FileWatcher;

#[tauri::command]
pub async fn get_sync_status(app_handle: tauri::AppHandle) -> Result<SyncStatus, String> {
    let state_mgr: tauri::State<'_, AppStateManager> = app_handle.state();
    let sync_mgr: tauri::State<'_, SyncManager> = app_handle.state();
    Ok(sync_mgr.get_status(&state_mgr).await)
}

#[tauri::command]
pub async fn enable_sync(app_handle: tauri::AppHandle) -> Result<SyncStatus, String> {
    if !SyncManager::is_icloud_available() {
        return Err("iCloud Drive is not enabled. Enable it in System Settings > Apple ID > iCloud > iCloud Drive.".into());
    }

    let state_mgr: tauri::State<'_, AppStateManager> = app_handle.state();
    state_mgr.set_sync_enabled(true).await.map_err(|e| e.to_string())?;

    let sync_mgr: tauri::State<'_, SyncManager> = app_handle.state();
    let watcher: tauri::State<'_, FileWatcher> = app_handle.state();
    sync_mgr.full_sync(&watcher, &state_mgr).await
}

/// Disable sync: flip the flag only. Does NOT delete the iCloud mirror —
/// files stay in place so the user can re-enable or force a refresh without
/// losing their iOS companion's data. Use `wipe_icloud_mirror` for the
/// explicit destructive path.
#[tauri::command]
pub async fn disable_sync(app_handle: tauri::AppHandle) -> Result<(), String> {
    let state_mgr: tauri::State<'_, AppStateManager> = app_handle.state();
    state_mgr.set_sync_enabled(false).await.map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
pub async fn trigger_full_sync(app_handle: tauri::AppHandle) -> Result<SyncStatus, String> {
    let state_mgr: tauri::State<'_, AppStateManager> = app_handle.state();
    if !state_mgr.is_sync_enabled().await {
        return Err("Sync is not enabled".into());
    }

    let sync_mgr: tauri::State<'_, SyncManager> = app_handle.state();
    let watcher: tauri::State<'_, FileWatcher> = app_handle.state();
    sync_mgr.full_sync(&watcher, &state_mgr).await
}

#[tauri::command]
pub async fn set_sync_size_threshold(
    app_handle: tauri::AppHandle,
    bytes: u64,
) -> Result<(), String> {
    let state_mgr: tauri::State<'_, AppStateManager> = app_handle.state();
    state_mgr.set_sync_size_threshold(bytes).await.map_err(|e| e.to_string())
}

/// Explicit, destructive nuke of the iCloud mirror directory. Separate from
/// `disable_sync` so the toggle can be reversible. Call this when the user
/// explicitly wants to clear the mirror.
#[tauri::command]
pub async fn wipe_icloud_mirror(app_handle: tauri::AppHandle) -> Result<(), String> {
    let state_mgr: tauri::State<'_, AppStateManager> = app_handle.state();
    // Flip sync off so the next launch won't immediately re-mirror.
    state_mgr.set_sync_enabled(false).await.map_err(|e| e.to_string())?;
    SyncManager::cleanup()
}
