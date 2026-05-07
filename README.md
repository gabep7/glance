# glance

markdown preview that scrolls with your cursor. terminal-first, editor-optional.

![glance demo](demo.gif)

## overview

- `glance file.md` opens a native webview window with rendered markdown
- `glance --tui file.md` renders in the terminal instead
- `:Glance` in neovim opens a live side-by-side preview
- cursor moves in source, preview scrolls to match
- edits appear in real time, no save needed

## install

**standalone** (prebuilt binaries on [releases](https://github.com/gabep7/glance/releases)):

```bash
# macOS
brew install gabep7/tap/glance

# or download from releases
curl -L https://github.com/gabep7/glance/releases/latest/download/glance-macos-arm64 -o /usr/local/bin/glance
chmod +x /usr/local/bin/glance

# cargo
cargo install glance-md
```

**neovim** (lazy.nvim):

```lua
{
  "gabep7/glance",
  build = "cargo build --release",
  config = function()
    require("glance").setup()
  end,
}
```

## usage

```
# terminal preview
glance --tui README.md

# watch mode, re-renders on change
glance --tui --watch README.md

# render from stdin
echo "# hello" | glance --stdin --tui

# continuous mode from stdin (for editor integrations)
echo "8" | glance --pipe --tui
```

neovim keymaps (set automatically on `*.md`):

| key | action |
|-----|--------|
| `<leader>gp` | toggle preview |
| `<leader>gf` | jump to preview / back to source |
| `<leader>gs` | freeze scroll sync |
| `:Glance` | open preview |
| `:GlanceStop` | close preview |

> **Note:** the crate is `glance-md` but the binary is still named `glance`.

## how it works

neovim opens a `:terminal` split running `glance --tui --watch` against a temp file. edits and cursor position are written to temp files. a 30ms rust poll loop picks up changes and re-renders ANSI to the terminal. no daemon, no socket, no config.

the preview viewport is proportional -- cursor at 30% through the source shows 30% through the rendered output. ANSI SGR state is tracked so sliced lines don't break formatting. terminal height comes from `ioctl(TIOCGWINSZ)`, not `$LINES`.

## why

existing markdown previewers either need a browser, a node runtime, a headless server, or don't follow your cursor. this is one binary, no dependencies at runtime, and scrolls with you.
