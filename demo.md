# glance

> markdown preview in your nvim split

## features

- live preview on every keystroke
- scroll sync with cursor position
- pure lua, no binary, no browser
- treesitter highlighting in code blocks
- tables, task lists, quotes

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
{ "gabep7/glance", ft = "markdown" }
```

## how it works

the preview is a scratch buffer in a split. on every change the source buffer is re-rendered in lua and drawn with extmark highlights. no temp files, no file watcher, no external process.

no daemon, no socket, no browser.

## scroll sync

every source line maps to its rendered line, so the preview follows your cursor exactly, even past tables and code blocks.

```lua
local target = state.map[cursor_row]
vim.fn.winrestview({ topline = target - screen_row + 1 })
```

the rendered line is kept at the same screen row as your cursor, so the two splits stay side by side.

## why another previewer

most markdown previewers bring a browser tab, a node runtime, or a headless server along for the ride. glance is a few hundred lines of lua, and a preview that keeps its place while you write.

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