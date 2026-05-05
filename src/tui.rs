use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::mpsc;

use crate::watch;

fn render_ansi(markdown: &str) -> String {
    let skin = termimad::MadSkin::default();
    skin.term_text(markdown).to_string()
}

/// render a file once to stdout
pub fn render_once(path: &Path) {
    let md = fs::read_to_string(path).unwrap_or_else(|e| format!("error: {e}"));
    let ansi = render_ansi(&md);
    let mut stdout = io::stdout().lock();
    let _ = stdout.write_all(ansi.as_bytes());
}

/// render from stdin to stdout
pub fn render_stdin() {
    let mut md = String::new();
    std::io::Read::read_to_string(&mut io::stdin(), &mut md).ok();
    let ansi = render_ansi(&md);
    let mut stdout = io::stdout().lock();
    let _ = stdout.write_all(ansi.as_bytes());
}

/// watch a file and re-render on change, clearing the terminal each time
pub fn watch_loop(path: &Path) {
    let path = path.to_path_buf();

    // initial render
    render_and_clear(&path);

    // watch for changes
    let (tx, rx) = mpsc::channel::<PathBuf>();
    let _watcher = watch::watch_file(&path, tx).expect("failed to watch file");

    for _ in rx {
        render_and_clear(&path);
    }
}

fn render_and_clear(path: &Path) {
    let md = fs::read_to_string(path).unwrap_or_else(|e| format!("error: {e}"));
    let ansi = render_ansi(&md);

    // clear screen and move cursor to top
    let mut stdout = io::stdout().lock();
    let _ = stdout.write_all(b"\x1b[2J\x1b[H");
    let _ = stdout.write_all(ansi.as_bytes());
    let _ = stdout.flush();
}
