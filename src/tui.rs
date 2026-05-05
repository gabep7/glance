use std::fs;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::sync::mpsc;

use crate::watch;

fn render_ansi(markdown: &str) -> String {
    let skin = termimad::MadSkin::default();
    skin.term_text(markdown).to_string()
}

fn clear_and_write(ansi: &str) {
    let mut stdout = io::stdout().lock();
    // home cursor, output content (overwrites previous, no screen clear)
    let _ = stdout.write_all(b"\x1b[H");
    let _ = stdout.write_all(ansi.as_bytes());
    let _ = stdout.flush();
}

fn initial_render(ansi: &str) {
    let mut stdout = io::stdout().lock();
    // full screen clear only on first render
    let _ = stdout.write_all(b"\x1b[2J\x1b[H");
    let _ = stdout.write_all(ansi.as_bytes());
    let _ = stdout.flush();
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

/// read length-prefixed markdown from stdin, render, clear, output. loop forever.
/// protocol: "<length>\n<content>" where length is byte count of content.
pub fn pipe_mode() {
    let mut stdin = io::stdin();
    let mut len_buf = String::with_capacity(32);

    loop {
        len_buf.clear();
        if stdin.read_line(&mut len_buf).is_err() {
            break;
        }
        let len: usize = match len_buf.trim().parse() {
            Ok(0) => continue,
            Ok(n) => n,
            Err(_) => break,
        };

        let mut content = vec![0u8; len];
        if stdin.read_exact(&mut content).is_err() {
            break;
        }

        let markdown = String::from_utf8_lossy(&content);
        let ansi = render_ansi(&markdown);
        clear_and_write(&ansi);
    }
}

/// watch a file via polling (not OS events) — bulletproof on all platforms
pub fn poll_watch(path: &Path) {
    let path = path.to_path_buf();
    let mut last_mod = file_modified(&path);

    let md = fs::read_to_string(&path).unwrap_or_default();
    let ansi = render_ansi(&md);
    initial_render(&ansi);

    loop {
        std::thread::sleep(std::time::Duration::from_millis(100));
        let current = file_modified(&path);
        if current != last_mod {
            last_mod = current;
            let md = fs::read_to_string(&path).unwrap_or_default();
            let ansi = render_ansi(&md);
            clear_and_write(&ansi);
        }
    }
}

fn file_modified(path: &Path) -> Option<std::time::SystemTime> {
    std::fs::metadata(path).ok()?.modified().ok()
}

/// watch a file via notify events (macOS fsevent can be flaky)
pub fn watch_loop(path: &Path) {
    let path = path.to_path_buf();
    render_and_clear(&path, true);

    let (tx, rx) = mpsc::channel::<PathBuf>();
    let _watcher = watch::watch_file(&path, tx).expect("failed to watch file");

    for _ in rx {
        render_and_clear(&path, false);
    }
}

fn render_and_clear(path: &Path, initial: bool) {
    let md = fs::read_to_string(path).unwrap_or_default();
    let ansi = render_ansi(&md);
    if initial {
        initial_render(&ansi);
    } else {
        clear_and_write(&ansi);
    }
}
