// MarkScout — System Commands
// reveal_in_finder, open_external, check_for_update, write_crash_log

use std::path::Path;

use tauri::Manager;
use tauri_plugin_shell::ShellExt;

use crate::watcher::FileWatcher;

// ---------------------------------------------------------------------------
// reveal_in_finder — open Finder with the file selected (macOS)
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn reveal_in_finder(
    path: String,
    app_handle: tauri::AppHandle,
) -> Result<(), String> {
    // Security: validate path exists
    if !Path::new(&path).exists() {
        return Err("Path does not exist".to_string());
    }

    // Security: validate path is under a watched directory
    let watcher = app_handle.state::<FileWatcher>();
    let watched_dirs = watcher.get_watched_dirs();
    let is_under_watched = watched_dirs.iter().any(|d| path.starts_with(d.as_str()));
    if !is_under_watched {
        return Err("Path not in watched directories".to_string());
    }

    // Use Tauri shell plugin to open via the system (sandbox-safe)
    app_handle
        .shell()
        .open(format!("file://{}", path), None)
        .map_err(|e| format!("Failed to reveal in Finder: {}", e))?;

    Ok(())
}

// ---------------------------------------------------------------------------
// open_external — open a URL in the default browser
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn open_external(
    url: String,
    app_handle: tauri::AppHandle,
) -> Result<(), String> {
    // Use Tauri shell plugin (sandbox-safe)
    app_handle
        .shell()
        .open(&url, None)
        .map_err(|e| format!("Failed to open URL: {}", e))?;

    Ok(())
}

// ---------------------------------------------------------------------------
// write_crash_log — append diagnostic entries to crash.log
// ---------------------------------------------------------------------------

#[tauri::command]
pub async fn write_crash_log(entry: String) -> Result<(), String> {
    use std::io::Write;

    // Use the same state directory as AppStateManager (sandbox-aware)
    let log_path = crate::state::crash_log_path();

    if let Some(parent) = log_path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    let mut file = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&log_path)
        .map_err(|e| format!("Failed to open crash log: {}", e))?;
    writeln!(file, "{}", entry)
        .map_err(|e| format!("Failed to write crash log: {}", e))?;
    Ok(())
}

// ---------------------------------------------------------------------------
// check_for_update — check GitHub releases for a newer version
// (Disabled for Mac App Store builds — Apple handles updates)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateCheckResult {
    pub has_update: bool,
    pub latest_version: String,
    pub download_url: String,
    pub current_version: String,
}

#[tauri::command]
pub async fn check_for_update(
    app_handle: tauri::AppHandle,
) -> Result<UpdateCheckResult, String> {
    let current_version = app_handle.config().version.clone().unwrap_or_else(|| "1.0.0".to_string());

    // Mac App Store builds: Apple handles updates, skip GitHub check
    #[cfg(feature = "mas")]
    {
        return Ok(UpdateCheckResult {
            has_update: false,
            latest_version: current_version.clone(),
            download_url: String::new(),
            current_version,
        });
    }

    // Direct distribution: check GitHub releases
    #[cfg(not(feature = "mas"))]
    {
        let client = reqwest::Client::builder()
            .user_agent("markscout-updater")
            .build()
            .map_err(|e| format!("Failed to create HTTP client: {}", e))?;

        let response = client
            .get("https://api.github.com/repos/shahzadafzal/markscout/releases/latest")
            .send()
            .await
            .map_err(|e| format!("Failed to fetch release info: {}", e))?;

        if !response.status().is_success() {
            return Ok(UpdateCheckResult {
                has_update: false,
                latest_version: current_version.clone(),
                download_url: String::new(),
                current_version,
            });
        }

        let release: serde_json::Value = response
            .json()
            .await
            .map_err(|e| format!("Failed to parse release JSON: {}", e))?;

        let tag_name = release["tag_name"]
            .as_str()
            .unwrap_or("")
            .trim_start_matches('v')
            .to_string();

        let download_url = release["html_url"]
            .as_str()
            .unwrap_or("")
            .to_string();

        let has_update = match (
            semver::Version::parse(&tag_name),
            semver::Version::parse(&current_version),
        ) {
            (Ok(latest), Ok(current)) => latest > current,
            _ => false,
        };

        Ok(UpdateCheckResult {
            has_update,
            latest_version: tag_name,
            download_url,
            current_version,
        })
    }
}
