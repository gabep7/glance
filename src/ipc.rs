use serde::{Deserialize, Serialize};

/// messages sent from editor to daemon
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum EditorCommand {
    /// open a new file in the preview
    #[serde(rename = "open")]
    Open { path: String },
    /// update cursor position (line, column)
    #[serde(rename = "cursor")]
    Cursor { line: usize, col: usize },
    /// update scroll position
    #[serde(rename = "scroll")]
    Scroll { top_line: usize },
    /// close a preview
    #[serde(rename = "close")]
    Close,
}

/// messages sent from daemon back to editor
#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum DaemonResponse {
    /// preview window is ready
    #[serde(rename = "ready")]
    Ready { id: String },
    /// user clicked in preview, editor should navigate to line
    #[serde(rename = "navigate")]
    Navigate { line: usize },
    /// something went wrong
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
