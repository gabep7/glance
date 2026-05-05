use serde::{Deserialize, Serialize};

/// Messages sent from editor to daemon.
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum EditorCommand {
    /// Open a new file in the preview.
    #[serde(rename = "open")]
    Open { path: String },
    /// Update cursor position (line, column).
    #[serde(rename = "cursor")]
    Cursor { line: usize, col: usize },
    /// Update scroll position.
    #[serde(rename = "scroll")]
    Scroll { top_line: usize },
    /// Close a preview.
    #[serde(rename = "close")]
    Close,
}

/// Messages sent from daemon back to editor.
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum DaemonResponse {
    /// Preview is ready.
    #[serde(rename = "ready")]
    Ready { id: String },
    /// User clicked in preview, editor should navigate.
    #[serde(rename = "navigate")]
    Navigate { line: usize },
    /// Error response.
    #[serde(rename = "error")]
    Error { message: String },
}

pub fn socket_path() -> std::path::PathBuf {
    let dir = directories::BaseDirs::new()
        .map(|d| d.data_local_dir().join("glance"))
        .unwrap_or_else(|| std::path::PathBuf::from("/tmp/glance"));
    std::fs::create_dir_all(&dir).ok();
    dir.join("sock")
}
