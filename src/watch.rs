use std::path::Path;
use std::sync::mpsc::Sender;

use notify::{Event, EventKind, RecursiveMode, Watcher};

/// Starts watching a file for changes. Sends the modified path on the channel
/// when the file changes.
pub fn watch_file(
    path: &Path,
    tx: Sender<std::path::PathBuf>,
) -> notify::Result<impl Watcher> {
    let watch_path = path.to_path_buf();
    let closure_path = watch_path.clone();

    let mut watcher = notify::recommended_watcher(move |res: Result<Event, notify::Error>| {
        if let Ok(event) = res {
            match event.kind {
                EventKind::Modify(_) | EventKind::Create(_) => {
                    let _ = tx.send(closure_path.clone());
                }
                _ => {}
            }
        }
    })?;

    watcher.watch(&watch_path, RecursiveMode::NonRecursive)?;
    Ok(watcher)
}
