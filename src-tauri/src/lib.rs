mod commands;
mod filters;
mod hash;
mod state;
mod sync;
mod types;
mod watcher;

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use tauri::menu::{MenuBuilder, MenuItemBuilder, PredefinedMenuItem, SubmenuBuilder};
use tauri::{Emitter, Manager};

use state::AppStateManager;
use sync::SyncManager;
use watcher::FileWatcher;

// --- Window state persistence ---

#[derive(Debug, Serialize, Deserialize, Clone)]
struct WindowState {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    maximized: bool,
}

impl Default for WindowState {
    fn default() -> Self {
        Self {
            x: 100,
            y: 100,
            width: 1200,
            height: 800,
            maximized: false,
        }
    }
}

fn window_state_path() -> PathBuf {
    #[cfg(feature = "mas")]
    {
        dirs::data_local_dir()
            .unwrap_or_default()
            .join("com.markscout.app")
            .join("window-state.json")
    }
    #[cfg(not(feature = "mas"))]
    {
        dirs::home_dir()
            .unwrap_or_default()
            .join(".markscout")
            .join("window-state.json")
    }
}

fn load_window_state() -> Option<WindowState> {
    let path = window_state_path();
    let data = fs::read_to_string(&path).ok()?;
    serde_json::from_str(&data).ok()
}

fn save_window_state(state: &WindowState) {
    let path = window_state_path();
    if let Some(parent) = path.parent() {
        let _ = fs::create_dir_all(parent);
    }
    if let Ok(json) = serde_json::to_string_pretty(state) {
        let _ = fs::write(&path, json);
    }
}

// --- Menu building ---

fn build_menu(app: &tauri::App) -> tauri::Result<tauri::menu::Menu<tauri::Wry>> {
    let handle = app.handle();

    // App menu (MarkScout)
    let settings_item = MenuItemBuilder::with_id("settings", "Settings")
        .accelerator("CmdOrCtrl+,")
        .build(handle)?;

    let app_menu = SubmenuBuilder::new(handle, "MarkScout")
        .about(None)
        .separator()
        .item(&settings_item)
        .separator()
        .hide()
        .hide_others()
        .show_all()
        .separator()
        .quit()
        .build()?;

    // File menu
    let file_menu = SubmenuBuilder::new(handle, "File")
        .close_window()
        .build()?;

    // Edit menu
    let edit_menu = SubmenuBuilder::new(handle, "Edit")
        .undo()
        .redo()
        .separator()
        .cut()
        .copy()
        .paste()
        .select_all()
        .build()?;

    // View menu
    let toggle_sidebar = MenuItemBuilder::with_id("toggle-sidebar", "Toggle Sidebar")
        .accelerator("CmdOrCtrl+B")
        .build(handle)?;
    let toggle_reader = MenuItemBuilder::with_id("toggle-reader-mode", "Toggle Reader Mode")
        .accelerator("CmdOrCtrl+Shift+R")
        .build(handle)?;
    let zoom_in = MenuItemBuilder::with_id("zoom-in", "Zoom In")
        .accelerator("CmdOrCtrl+=")
        .build(handle)?;
    let zoom_out = MenuItemBuilder::with_id("zoom-out", "Zoom Out")
        .accelerator("CmdOrCtrl+-")
        .build(handle)?;
    let zoom_reset = MenuItemBuilder::with_id("zoom-reset", "Reset Zoom")
        .accelerator("CmdOrCtrl+0")
        .build(handle)?;

    let view_menu = SubmenuBuilder::new(handle, "View")
        .item(&toggle_sidebar)
        .item(&toggle_reader)
        .item(&PredefinedMenuItem::separator(handle)?)
        .item(&zoom_in)
        .item(&zoom_out)
        .item(&zoom_reset)
        .build()?;

    // Help menu
    let check_updates = MenuItemBuilder::with_id("check-updates", "Check for Updates")
        .build(handle)?;
    let github_repo = MenuItemBuilder::with_id("github-repo", "GitHub Repository")
        .build(handle)?;

    let help_menu = SubmenuBuilder::new(handle, "Help")
        .item(&check_updates)
        .separator()
        .item(&github_repo)
        .build()?;

    // Build the full menu bar
    let menu = MenuBuilder::new(handle)
        .item(&app_menu)
        .item(&file_menu)
        .item(&edit_menu)
        .item(&view_menu)
        .item(&help_menu)
        .build()?;

    Ok(menu)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            // Initialize state manager
            let state_manager = AppStateManager::new()?;
            app.manage(state_manager);

            // Initialize file watcher
            let watcher = FileWatcher::new(app.handle().clone())?;
            app.manage(watcher);

            // Initialize sync manager
            let sync_manager = SyncManager::new();
            app.manage(sync_manager);

            // Sync-on-launch: if sync is enabled, kick off a full_sync in the
            // background after the initial scan so files mirror to iCloud on
            // every app launch without needing a file change or manual click.
            let sync_handle = app.handle().clone();
            tauri::async_runtime::spawn(async move {
                let state_mgr: tauri::State<'_, AppStateManager> = sync_handle.state();
                if !state_mgr.is_sync_enabled().await {
                    return;
                }
                if !SyncManager::is_icloud_available() {
                    eprintln!("[MarkScout] sync-on-launch skipped: iCloud not available");
                    return;
                }
                let sync_mgr: tauri::State<'_, SyncManager> = sync_handle.state();
                let watcher: tauri::State<'_, FileWatcher> = sync_handle.state();
                eprintln!("[MarkScout] sync-on-launch: starting full_sync");
                match sync_mgr.full_sync(&watcher, &state_mgr).await {
                    Ok(status) => {
                        eprintln!(
                            "[MarkScout] sync-on-launch: done, {} files, {} bytes",
                            status.file_count, status.total_size
                        );
                    }
                    Err(e) => {
                        eprintln!("[MarkScout] sync-on-launch failed: {}", e);
                    }
                }
            });

            // Build and set the application menu
            let menu = build_menu(app)?;
            app.set_menu(menu)?;

            // Restore window state
            if let Some(window) = app.get_webview_window("main") {
                if let Some(ws) = load_window_state() {
                    use tauri::{LogicalPosition, LogicalSize};
                    // Clamp to reasonable bounds so a corrupted state file can
                    // never explode the window across multiple displays. Most
                    // screens top out around 2560 logical px wide.
                    let width = (ws.width as f64).clamp(800.0, 2560.0);
                    let height = (ws.height as f64).clamp(600.0, 1600.0);
                    let _ = window.set_size(LogicalSize::new(width, height));
                    let _ = window.set_position(LogicalPosition::new(ws.x as f64, ws.y as f64));
                    if ws.maximized {
                        let _ = window.maximize();
                    }
                }

                // Window event logging + state save
                let window_clone = window.clone();
                window.on_window_event(move |event| {
                    match event {
                        tauri::WindowEvent::CloseRequested { .. } => {
                            eprintln!("[MarkScout] window CloseRequested");
                            let mut ws = WindowState::default();
                            // Scale factor lets us persist *logical* pixels so
                            // the next launch restores at the same visual size
                            // regardless of display DPI.
                            let scale = window_clone.scale_factor().unwrap_or(1.0);
                            if let Ok(pos) = window_clone.outer_position() {
                                ws.x = (pos.x as f64 / scale) as i32;
                                ws.y = (pos.y as f64 / scale) as i32;
                            }
                            if let Ok(size) = window_clone.outer_size() {
                                ws.width = ((size.width as f64) / scale) as u32;
                                ws.height = ((size.height as f64) / scale) as u32;
                            }
                            if let Ok(maximized) = window_clone.is_maximized() {
                                ws.maximized = maximized;
                            }
                            save_window_state(&ws);
                        }
                        tauri::WindowEvent::Focused(focused) => {
                            eprintln!("[MarkScout] window Focused={}", focused);
                        }
                        tauri::WindowEvent::Moved(_) => {}
                        tauri::WindowEvent::Resized(size) => {
                            eprintln!("[MarkScout] window Resized={}x{}", size.width, size.height);
                        }
                        tauri::WindowEvent::Destroyed => {
                            eprintln!("[MarkScout] window Destroyed");
                        }
                        _ => {}
                    }
                });
            }

            Ok(())
        })
        .on_menu_event(|app_handle, event| {
            let action = match event.id().as_ref() {
                "toggle-sidebar" => Some("toggle-sidebar"),
                "toggle-reader-mode" => Some("toggle-reader-mode"),
                "zoom-in" => Some("zoom-in"),
                "zoom-out" => Some("zoom-out"),
                "zoom-reset" => Some("zoom-reset"),
                "settings" => Some("open-settings"),
                "check-updates" => Some("check-updates"),
                "github-repo" => Some("github-repo"),
                _ => None,
            };
            if let Some(action) = action {
                let _ = app_handle.emit("menu-event", serde_json::json!({ "action": action }));
            }
        })
        .invoke_handler(tauri::generate_handler![
            commands::files::get_files,
            commands::files::get_file_content,
            commands::search::search_files,
            commands::state_cmds::get_ui_state,
            commands::state_cmds::save_ui_state,
            commands::state_cmds::toggle_favorite,
            commands::state_cmds::toggle_folder_star,
            commands::state_cmds::record_history,
            commands::state_cmds::get_history,
            commands::preferences::get_preferences,
            commands::preferences::toggle_preset,
            commands::preferences::add_watch_dir,
            commands::preferences::remove_watch_dir,
            commands::preferences::set_min_file_length,
            commands::preferences::update_filter,
            commands::preferences::get_filters,
            commands::system::reveal_in_finder,
            commands::system::check_for_update,
            commands::system::open_external,
            commands::system::write_crash_log,
            commands::session::get_whats_new,
            commands::session::record_session_start,
            commands::sync_cmds::get_sync_status,
            commands::sync_cmds::enable_sync,
            commands::sync_cmds::disable_sync,
            commands::sync_cmds::trigger_full_sync,
            commands::sync_cmds::set_sync_size_threshold,
            commands::sync_cmds::wipe_icloud_mirror,
        ])
        .run(tauri::generate_context!())
        .expect("error while running MarkScout");
}
