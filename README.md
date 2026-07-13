# glance

markdown preview that lives in your nvim split.

![glance demo](demo.gif)

## install

lazy.nvim:

```lua
{
  "gabep7/glance",
  build = "cargo build --release",
  config = function()
    require("glance").setup()
  end,
}
```

requires a rust toolchain (`cargo`) for the build step.

## keymaps

set automatically on `*.md` buffers:

| key | action |
|-----|--------|
| `<leader>gp` | toggle preview |
| `<leader>gf` | jump to preview / back to source |
| `<leader>gs` | freeze scroll sync |
| `:Glance` | open preview |
| `:GlanceStop` | close preview |

## how it works

opens a `:terminal` split running a rust binary that renders markdown to ANSI. the binary watches a temp file; nvim writes buffer content on every change. cursor position is written to a second temp file for scroll sync. no daemon, no socket, no browser.