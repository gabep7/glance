-- nvim --headless -u NONE -l tests/run.lua
vim.opt.rtp:prepend(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h"))

local render = require("glance.render")
local failures, count = 0, 0

local function eq(a, b, msg)
  count = count + 1
  if not vim.deep_equal(a, b) then
    failures = failures + 1
    print(("FAIL %s\n  expected: %s\n  got:      %s"):format(msg, vim.inspect(b), vim.inspect(a)))
  end
end

local function has_hl(r, row, group)
  for _, h in ipairs(r.hls) do
    if h[1] == row and h[4] == group then
      return h
    end
  end
end

-- inline
eq({ render.inline("a **b** c") }, { "a b c", { { 2, 3, "GlanceBold", 109 } } }, "bold")
eq(render.inline("`x * y`"), "x * y", "code span keeps literal stars")
eq(render.inline("see [docs](http://x.y) now"), "see docs now", "link hides url")
eq(render.inline("snake_case_name"), "snake_case_name", "intraword underscore")
eq(render.inline("\\*not em\\*"), "*not em*", "escapes")
eq(render.inline("2 * 3 * 4"), "2 * 3 * 4", "spaced stars are literal")
eq(render.inline("~~gone~~"), "gone", "strike")
eq(render.inline("![logo](a.png)"), "[image: logo]", "image")
eq(render.inline("<https://a.b>"), "https://a.b", "autolink")
eq(render.inline("***both***"), "both", "bold italic")

-- blocks
local r = render.render({ "# Title", "", "text" }, { width = 20 })
eq(r.lines, { "Title", "━━━━━", "", "text" }, "h1 underline")
eq(r.map, { 1, 3, 4 }, "map skips underline")
eq(has_hl(r, 0, "GlanceH1") ~= nil, true, "h1 highlight")

r = render.render({ "- a", "  - b", "- [ ] todo", "- [x] done", "1. one" })
eq(r.lines, { "• a", "  ◦ b", "☐ todo", "☑ done", "1. one" }, "lists")

r = render.render({ "```lua", "local x = 1", "```", "after" })
eq(r.lines, { " lua", " local x = 1", "", "after" }, "fenced code")
eq(#r.line_hls, 3, "code block line highlights")
eq(r.map, { 1, 2, 3, 4 }, "code map")

r = render.render({ "```", "unterminated" })
eq(r.lines, { "", " unterminated" }, "unterminated fence")

r = render.render({ "| a | bb |", "|:--|--:|", "| ccc | d |" })
eq(r.lines, {
  "┌─────┬────┐",
  "│ a   │ bb │",
  "├─────┼────┤",
  "│ ccc │  d │",
  "└─────┴────┘",
}, "table")
eq(r.map, { 2, 3, 4 }, "table map")

r = render.render({ "> quote **b**" })
eq(r.lines, { "▎ quote b" }, "quote")

r = render.render({ "Title", "===", "---" }, { width = 10 })
eq(r.lines, { "Title", "━━━━━", ("─"):rep(10) }, "setext + hr")

r = render.render({ "---", "title: x", "---", "# h" })
eq(r.lines[2], "title: x", "frontmatter")
eq(r.map[4], 4, "frontmatter map")

-- every source line maps somewhere, monotonically
local demo = vim.fn.readfile(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h") .. "/demo.md")
r = render.render(demo)
local last = 0
for i = 1, #demo do
  local m = r.map[i]
  if not m or m < last or m > #r.lines then
    eq(m, "monotonic", "demo.md map at line " .. i)
    break
  end
  last = m
end
for _, h in ipairs(r.hls) do
  local line = r.lines[h[1] + 1]
  if not line or h[2] < 0 or h[3] > #line then
    eq(h, "in bounds", "highlight bounds")
    break
  end
end

-- plugin smoke test
vim.cmd("runtime plugin/glance.lua")
local glance = require("glance")
glance.setup()
local tmp = vim.fn.tempname() .. ".md"
vim.fn.writefile(demo, tmp)
vim.cmd("edit " .. tmp)
glance.open()
eq(#vim.api.nvim_list_wins(), 2, "preview opened")
local wins = vim.api.nvim_list_wins()
local pbuf = vim.api.nvim_win_get_buf(wins[1] == vim.api.nvim_get_current_win() and wins[2] or wins[1])
eq(vim.api.nvim_buf_get_lines(pbuf, 0, 1, false)[1], r.lines[1], "preview rendered")
vim.api.nvim_buf_set_lines(0, 0, 1, false, { "# changed" })
vim.wait(500, function()
  return vim.api.nvim_buf_get_lines(pbuf, 0, 1, false)[1] == "changed"
end)
eq(vim.api.nvim_buf_get_lines(pbuf, 0, 1, false)[1], "changed", "live update")
local pwin = vim.fn.bufwinid(pbuf)
local fresh = render.render(vim.api.nvim_buf_get_lines(0, 0, -1, false))
vim.api.nvim_win_set_cursor(0, { 60, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = 0 })
eq(vim.api.nvim_win_get_cursor(pwin)[1], fresh.map[60], "scroll sync follows cursor")
glance.toggle()
eq(#vim.api.nvim_list_wins(), 1, "preview closed")
glance.toggle()
eq(#vim.api.nvim_list_wins(), 2, "preview reopened")
vim.cmd("bwipeout!")
vim.wait(100)
eq(vim.api.nvim_buf_is_valid(pbuf), false, "preview gone with source")

print(("%d/%d passed"):format(count - failures, count))
vim.cmd(failures > 0 and "cquit 1" or "qall!")
