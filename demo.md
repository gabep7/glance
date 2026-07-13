# glance

> markdown preview in your nvim split

## features

- live preview on every keystroke
- scroll sync with cursor position
- terminal rendering, no browser
- no runtime dependencies
- proportional viewport tracking

## code

```rust
fn main() {
    let nums = (1..100)
        .filter(|n| n % 2 == 0)
        .map(|n| n * n)
        .collect::<Vec<_>>();
    println!(nums.len());
}
```

## usage

| key | action |
| --- | --- |
| `<leader>gp` | toggle |
| `<leader>gf` | focus |
| `<leader>gs` | freeze sync |
| `:Glance` | open |
| `:GlanceStop` | close |

## install

```lua
{ "gabep7/glance", build = "cargo build --release" }
```

## how it works

opens a terminal split running a rust binary that renders markdown to ANSI. the binary watches a temp file; nvim writes buffer content on every change. cursor position is written to a second temp file for scroll sync.

no daemon, no socket, no browser.

## scroll sync

the preview viewport is proportional to your cursor position. move your cursor down through the source and the preview follows. the preview stays aligned to what you are editing.

```rust
let ratio = cursor_line as f32 / total_lines as f32;
let preview_offset = ratio * rendered_height;
```

the ratio maps your position in the source file to a position in the rendered output. if you are 30 percent through the source, you see 30 percent through the preview.

## ansi rendering

markdown is parsed with pulldown-cmark and rendered to ANSI using termimad. SGR state is tracked across line boundaries so sliced lines do not break formatting. terminal height comes from ioctl TIOCGWINSZ, not the LINES env var.

```rust
unsafe {
    let mut ws: libc::winsize = std::mem::zeroed();
    libc::ioctl(fd, libc::TIOCGWINSZ, &mut ws);
}
```

## why another previewer

most markdown previewers bring a browser tab, a node runtime, or a headless server along for the ride. glance is one binary with no runtime dependencies, and a preview that keeps its place while you write.

- browser-based tools spawn a headless server and open a tab
- static TUI tools are one-shot: edit, save, re-run
- glance renders inside your editor split and updates on every keystroke

## roadmap

- [x] neovim integration
- [x] scroll sync
- [x] live reload
- [x] proportional viewport
- [ ] helix support
- [ ] zed support

## license

MIT