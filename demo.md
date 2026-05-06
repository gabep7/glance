# glance

> live markdown previewer

## features

- **live preview** -- renders as you type
- **scroll sync** -- preview follows your cursor
- *terminal-first*, with an optional webview window

## install

```bash
cargo install glance-md
```

## usage

| command | does |
| --- | --- |
| `glance file.md` | open webview |
| `glance --tui file.md` | terminal preview |
| `glance --tui --watch file.md` | watch for changes |
| `:Glance` | neovim split preview |

## quickstart

Open any markdown file and run `:Glance`. A split opens on the right with the rendered preview. Move your cursor and the preview scrolls to match.

No save required. No browser. No node.

## why another previewer

Most markdown previewers fall into one of two camps:

1. **Browser-based** -- spawns a headless server, opens a tab, and leaves you context-switching between editor and browser.
2. **Static TUI** -- renders in the terminal but is a one-shot command. Edit, save, re-run.

glance is different. It renders inside your editor split and updates on every keystroke. The preview viewport is proportional to your cursor position, so you are always looking at the rendered version of what you are editing.

## how scroll sync works

neovim writes cursor position to a temp file. a 30ms rust poll loop picks it up and re-renders. the preview slice is calculated as a ratio:

```rust
let ratio = cursor_line as f32 / total_lines as f32;
let preview_offset = ratio * rendered_height;
```

ANSI SGR state is tracked so sliced lines do not break formatting. terminal height comes from `ioctl(TIOCGWINSZ)`, not `$LINES`.

## supported markdown

- headers
- bold, italic, strikethrough
- inline code and fenced code blocks
- tables
- blockquotes
- thematic breaks
- footnotes

## roadmap

- [x] neovim integration
- [x] scroll sync
- [x] live reload
- [ ] helix support
- [ ] zed support

## configuration

```lua
require("glance").setup({
  width = 0.4,      -- split width ratio
  follow = true,    -- scroll sync
})
```

## license

MIT
