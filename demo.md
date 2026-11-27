# glance

> markdown preview that lives in your nvim split

glance renders your buffer as you type, right next to it. **no browser**, *no binary*, no build step. just `lua`.

## features

- live preview on every keystroke
- exact scroll sync, even past code and tables
- treesitter highlighting in code blocks
- tables, task lists, quotes and links
  - nested lists too
    - as deep as you like

## setup

```lua
{
  "gabep7/glance",
  ft = "markdown",
  opts = {
    position = "right",
    scroll_sync = true,
  },
}
```

## keys

| key          | action               |
| ------------ | -------------------- |
| `<leader>gp` | toggle preview       |
| `<leader>gf` | jump to preview      |
| `<leader>gs` | toggle scroll sync   |
| `:Glance`    | open                 |

## how it works

every change re-renders the source in lua and paints the result with extmark highlights. each source line maps to a rendered line:

```lua
local function sync(map, row)
  local target = map[row] or #map
  vim.fn.winrestview({ topline = target })
end
```

so the preview keeps your place while you write.

---

## why

1. most previewers bring a browser tab along
2. static TUI tools are one-shot: edit, save, re-run
3. glance stays in your split and updates as you type

see the [readme](README.md) for config and highlight groups.

## roadmap

- [x] live preview
- [x] scroll sync
- [x] tables and task lists
- [ ] images
