# glance

> markdown preview in your nvim split

## features

- live preview on every keystroke
- scroll sync with cursor position
- terminal rendering, no browser
- no runtime dependencies

## code

```rust
fn main() {
    let nums = (1..100)
        .filter(|n| n % 2 == 0)
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

## why

most markdown previewers bring a browser tab, a node runtime, or a headless server. glance is one binary with no runtime dependencies, and a preview that keeps its place while you write.

## license

MIT