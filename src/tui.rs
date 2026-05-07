use std::fs;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};

fn render_ansi(markdown: &str) -> String {
    let skin = termimad::MadSkin::default();
    skin.term_text(markdown).to_string()
}

fn clear_and_write(ansi: &str) {
    let mut stdout = io::stdout().lock();
    let _ = stdout.write_all(b"\x1b[H");
    let _ = stdout.write_all(ansi.as_bytes());
    let _ = stdout.flush();
}

fn initial_render(ansi: &str) {
    let mut stdout = io::stdout().lock();
    let _ = stdout.write_all(b"\x1b[2J\x1b[H");
    let _ = stdout.write_all(ansi.as_bytes());
    let _ = stdout.flush();
}

/// get terminal height via ioctl, fall back to LINES env var, default 24
fn term_height() -> usize {
    use std::os::fd::AsRawFd;
    let fd = io::stdout().as_raw_fd();
    unsafe {
        let mut ws: libc::winsize = std::mem::zeroed();
        if libc::ioctl(fd, libc::TIOCGWINSZ, &mut ws) == 0 && ws.ws_row > 0 {
            return ws.ws_row as usize;
        }
    }
    std::env::var("LINES")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(24)
}

/// scan ANSI output, return active SGR params at the start of each line
fn sgr_at_line_starts(ansi: &str) -> Vec<String> {
    let mut result = vec![String::new()];
    let mut active: Vec<u8> = Vec::new();
    let bytes = ansi.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i] == b'\n' {
            let seq = if active.is_empty() || (active.len() == 1 && active[0] == 0) {
                String::new()
            } else {
                let nums: Vec<String> = active.iter().map(|n| n.to_string()).collect();
                format!("\x1b[{}m", nums.join(";"))
            };
            result.push(seq);
            i += 1;
        } else if bytes[i] == b'\x1b' && i + 1 < bytes.len() && bytes[i + 1] == b'[' {
            i += 2;
            let param_start = i;
            while i < bytes.len() && !bytes[i].is_ascii_alphabetic() && bytes[i] != b'@' {
                i += 1;
            }
            if i < bytes.len() {
                let terminator = bytes[i];
                let param_str = std::str::from_utf8(&bytes[param_start..i]).unwrap_or("");
                i += 1;
                if terminator == b'm' {
                    update_sgr(&mut active, param_str);
                }
            }
        } else {
            i += 1;
        }
    }
    result
}

fn update_sgr(active: &mut Vec<u8>, params: &str) {
    if params.is_empty() {
        active.clear();
        active.push(0);
        return;
    }
    for p in params.split(';') {
        let n: u8 = match p.parse() {
            Ok(v) => v,
            Err(_) => continue,
        };
        match n {
            0 => { active.clear(); active.push(0); }
            1 if !active.contains(&1) => { active.push(1); }
            22 => { active.retain(|&x| x != 1); }
            3 if !active.contains(&3) => { active.push(3); }
            23 => { active.retain(|&x| x != 3); }
            4 if !active.contains(&4) => { active.push(4); }
            24 => { active.retain(|&x| x != 4); }
            30..=37 => {
                active.retain(|&x| !(30..=37).contains(&x));
                active.push(n);
            }
            39 => { active.retain(|&x| !(30..=37).contains(&x)); }
            40..=47 => {
                active.retain(|&x| !(40..=47).contains(&x));
                active.push(n);
            }
            49 => { active.retain(|&x| !(40..=47).contains(&x)); }
            90..=97 => {
                active.retain(|&x| !(90..=97).contains(&x));
                active.push(n);
            }
            100..=107 => {
                active.retain(|&x| !(100..=107).contains(&x));
                active.push(n);
            }
            _ => {}
        }
    }
}

/// compute proportional ansi line index from source cursor line
fn calc_cursor_ansi(cursor_line: usize, source_lines: usize, total_ansi: usize) -> usize {
    let ratio = cursor_line as f64 / (source_lines - 1).max(1) as f64;
    ((ratio * (total_ansi - 1) as f64) as usize).min(total_ansi - 1)
}

/// render viewport from cached ANSI — no markdown re-parsing
fn render_viewport_from_cached(
    ansi: &str,
    sgr_map: &[String],
    source_lines: usize,
    cursor_line: usize,
) -> String {
    let ansi_lines: Vec<&str> = ansi.lines().collect();
    let total_ansi = ansi_lines.len();
    let height = term_height();

    if total_ansi <= height {
        return format!("\x1b[?25l\x1b[2J\x1b[H]{}\x1b[?25h", ansi);
    }

    let cursor_ansi = calc_cursor_ansi(cursor_line, source_lines, total_ansi);
    let start = cursor_ansi.saturating_sub(height / 3);
    let start = start.min(total_ansi.saturating_sub(height));

    let sgr_prefix = if start < sgr_map.len() { &sgr_map[start] } else { "" };

    let mut out = String::with_capacity(ansi.len() / 2 + 64);
    out.push_str("\x1b[?25l");
    out.push_str("\x1b[2J\x1b[H");
    if !sgr_prefix.is_empty() {
        out.push_str("\x1b[0m");
        out.push_str(sgr_prefix);
    }
    for (i, line) in ansi_lines.iter().enumerate().skip(start).take(height) {
        if i > start {
            out.push('\n');
        }
        out.push_str(line);
    }
    out.push_str("\x1b[J");
    out.push_str("\x1b[?25h");
    out
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

/// watch a file for changes and re-render. cursor_file provides live cursor position for scroll sync.
pub fn poll_watch(path: &Path, cursor_file: Option<PathBuf>) {
    use std::sync::mpsc;
    use notify::{EventKind, RecursiveMode, Watcher};

    let path = path.to_path_buf();
    let cursor_file_path = cursor_file;

    // cache ansi + sgr so cursor-only changes skip markdown parsing
    let md = fs::read_to_string(&path).unwrap_or_default();
    let mut cached_ansi = render_ansi(&md);
    let mut cached_sgr = sgr_at_line_starts(&cached_ansi);
    let mut source_lines = md.lines().count().max(1);
    let mut last_cursor_line: usize = read_cursor_file(cursor_file_path.as_deref()).unwrap_or(0);

    let ansi = render_viewport_from_cached(&cached_ansi, &cached_sgr, source_lines, last_cursor_line);
    initial_render(&ansi);

    // setup file watcher
    let (watch_tx, watch_rx) = mpsc::channel::<notify::Event>();
    let mut watcher = notify::recommended_watcher(move |res: Result<notify::Event, notify::Error>| {
        let _ = watch_tx.send(res.unwrap_or_default());
    })
    .expect("failed to start file watcher");
    watcher
        .watch(&path, RecursiveMode::NonRecursive)
        .expect("failed to watch file");

    // setup cursor file watcher if provided
    let (cursor_tx, cursor_rx) = mpsc::channel::<notify::Event>();
    if let Some(ref cp) = cursor_file_path
        && let Ok(mut w) = notify::recommended_watcher(move |res: Result<notify::Event, notify::Error>| {
            let _ = cursor_tx.send(res.unwrap_or_default());
        })
    {
        let _ = w.watch(cp, RecursiveMode::NonRecursive);
    }

    // poll cursor file every 16ms (in case watcher misses events)
    let mut cursor_poll_count = 0;

    loop {
        // check for file watcher events
        if let Ok(event) = watch_rx.try_recv() {
            match event.kind {
                EventKind::Modify(_) | EventKind::Create(_) => {
                    let md = fs::read_to_string(&path).unwrap_or_default();
                    cached_ansi = render_ansi(&md);
                    cached_sgr = sgr_at_line_starts(&cached_ansi);
                    source_lines = md.lines().count().max(1);
                    let ansi = render_viewport_from_cached(&cached_ansi, &cached_sgr, source_lines, last_cursor_line);
                    clear_and_write(&ansi);
                }
                _ => {}
            }
        }

        // check for cursor file watcher events
        if let Ok(event) = cursor_rx.try_recv() {
            match event.kind {
                EventKind::Modify(_) | EventKind::Create(_) => {
                    let current_cursor = read_cursor_file(cursor_file_path.as_deref()).unwrap_or(0);
                    if current_cursor != last_cursor_line {
                        last_cursor_line = current_cursor;
                        let ansi = render_viewport_from_cached(&cached_ansi, &cached_sgr, source_lines, last_cursor_line);
                        clear_and_write(&ansi);
                    }
                }
                _ => {}
            }
        }

        // fallback: poll cursor file every 16ms (in case watcher misses events)
        cursor_poll_count += 1;
        if cursor_poll_count >= 1 {
            cursor_poll_count = 0;
            if let Some(cp) = &cursor_file_path {
                let current_cursor = read_cursor_file(Some(cp));
                if let Some(cur) = current_cursor && cur != last_cursor_line {
                    last_cursor_line = cur;
                    let ansi = render_viewport_from_cached(&cached_ansi, &cached_sgr, source_lines, last_cursor_line);
                    clear_and_write(&ansi);
                }
            }
        }

        std::thread::sleep(std::time::Duration::from_millis(16));
    }
}

fn read_cursor_file(path: Option<&Path>) -> Option<usize> {
    let path = path?;
    let content = fs::read_to_string(path).ok()?;
    content.trim().parse().ok()
}


