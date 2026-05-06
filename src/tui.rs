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
    let mut result = vec![String::new()]; // line 0 starts with no active SGR
    let mut active: Vec<u8> = Vec::new();
    let bytes = ansi.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i] == b'\n' {
            // format current active SGR into a CSI sequence
            let seq = if active.is_empty() || (active.len() == 1 && active[0] == 0) {
                String::new()
            } else {
                let nums: Vec<String> = active.iter().map(|n| n.to_string()).collect();
                format!("\x1b[{}m", nums.join(";"))
            };
            result.push(seq);
            i += 1;
        } else if bytes[i] == b'\x1b' && i + 1 < bytes.len() && bytes[i + 1] == b'[' {
            i += 2; // skip \x1b [
            // collect parameter bytes
            let param_start = i;
            while i < bytes.len() && !bytes[i].is_ascii_alphabetic() && bytes[i] != b'@' {
                i += 1;
            }
            if i < bytes.len() {
                let terminator = bytes[i];
                let param_str = std::str::from_utf8(&bytes[param_start..i]).unwrap_or("");
                i += 1;
                if terminator == b'm' {
                    // SGR: update active state
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
        // bare CSI m = reset
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
            // bold/normal
            1 => { if !active.contains(&1) { active.push(1); } }
            22 => { active.retain(|&x| x != 1); }
            // italic
            3 => { if !active.contains(&3) { active.push(3); } }
            23 => { active.retain(|&x| x != 3); }
            // underline
            4 => { if !active.contains(&4) { active.push(4); } }
            24 => { active.retain(|&x| x != 4); }
            // fg colors 30-37
            30..=37 => {
                active.retain(|&x| !(30..=37).contains(&x));
                active.push(n);
            }
            39 => { active.retain(|&x| !(30..=37).contains(&x)); }
            // bg colors 40-47
            40..=47 => {
                active.retain(|&x| !(40..=47).contains(&x));
                active.push(n);
            }
            49 => { active.retain(|&x| !(40..=47).contains(&x)); }
            // 90-97 bright fg, 100-107 bright bg
            90..=97 => {
                active.retain(|&x| !(90..=97).contains(&x));
                active.push(n);
            }
            100..=107 => {
                active.retain(|&x| !(100..=107).contains(&x));
                active.push(n);
            }
            _ => {} // ignore extended color codes for now
        }
    }
}

/// render a viewport: slice of ANSI centered on cursor's proportional position.
/// tracks SGR formatting so sliced lines get correct active codes re-emitted.
fn render_viewport(
    markdown: &str,
    cursor_line: usize,
) -> String {
    let ansi = render_ansi(markdown);
    let ansi_lines: Vec<&str> = ansi.lines().collect();
    let total_ansi = ansi_lines.len();
    let height = term_height();

    if total_ansi <= height {
        return format!("\x1b[?25l\x1b[2J\x1b[H{}\x1b[?25h", ansi);
    }

    let source_lines = markdown.lines().count().max(1);
    let ratio = cursor_line as f64 / (source_lines - 1).max(1) as f64;
    let cursor_ansi = ((ratio * (total_ansi - 1) as f64) as usize).min(total_ansi - 1);
    let start = cursor_ansi.saturating_sub(height / 3); // cursor at top-third
    let start = start.min(total_ansi.saturating_sub(height));

    // get active SGR codes at the start line
    let sgr_map = sgr_at_line_starts(&ansi);
    let sgr_prefix = if start < sgr_map.len() { &sgr_map[start] } else { "" };

    let mut out = String::with_capacity(ansi.len() + 64);
    out.push_str("\x1b[?25l");       // hide cursor
    out.push_str("\x1b[2J\x1b[H");   // clear, cursor home
    if !sgr_prefix.is_empty() {
        out.push_str("\x1b[0m");     // reset first
        out.push_str(sgr_prefix);     // re-apply active formatting
    }
    for (i, line) in ansi_lines.iter().enumerate().skip(start).take(height) {
        if i > start {
            out.push('\n');
        }
        out.push_str(line);
    }
    out.push_str("\x1b[J");          // clear to end of screen
    out.push_str("\x1b[?25h");       // show cursor
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

/// watch a file via polling. cursor_file provides live cursor position for scroll sync.
pub fn poll_watch(path: &Path, cursor_file: Option<PathBuf>) {
    let path = path.to_path_buf();
    let mut last_mod = file_modified(&path);
    let mut last_cursor_mod: Option<std::time::SystemTime> = cursor_file
        .as_ref()
        .and_then(|cf| file_modified(cf));

    let md = fs::read_to_string(&path).unwrap_or_default();
    let cursor_line = read_cursor_file(cursor_file.as_deref()).unwrap_or(0);

    let ansi = render_viewport(&md, cursor_line);
    initial_render(&ansi);

    loop {
        std::thread::sleep(std::time::Duration::from_millis(30));

        let content_changed = {
            let current = file_modified(&path);
            let changed = current != last_mod;
            if changed {
                last_mod = current;
            }
            changed
        };

        let cursor_changed = cursor_file.as_ref().is_some_and(|cf| {
            let current = file_modified(cf);
            let changed = current != last_cursor_mod;
            if changed {
                last_cursor_mod = current;
            }
            changed
        });

        if content_changed || cursor_changed {
            let md = fs::read_to_string(&path).unwrap_or_default();
            let cursor_line = read_cursor_file(cursor_file.as_deref()).unwrap_or(0);
            let ansi = render_viewport(&md, cursor_line);
            clear_and_write(&ansi);
        }
    }
}

fn read_cursor_file(path: Option<&Path>) -> Option<usize> {
    let path = path?;
    let content = fs::read_to_string(path).ok()?;
    content.trim().parse().ok()
}

fn file_modified(path: &Path) -> Option<std::time::SystemTime> {
    std::fs::metadata(path).ok()?.modified().ok()
}


