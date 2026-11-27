-- minimal config used by demo/record.py
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)

vim.g.mapleader = " "
vim.o.termguicolors = true
vim.o.number = true
vim.o.cursorline = true
vim.o.showmode = false
vim.o.showcmd = false
vim.o.ruler = false
vim.o.laststatus = 2
vim.o.fillchars = "eob: ,vert:│"
vim.o.shortmess = vim.o.shortmess .. "I"
vim.o.wrap = true
vim.o.linebreak = true
vim.o.swapfile = false
vim.o.statusline = "  %t%=%{&ft ==# 'glance' ? 'preview' : 'markdown'}  "

local c = {
  bg = "#15171c", bg2 = "#1b1e24", bg3 = "#262a32", fg = "#c9ced6", dim = "#5d6470",
  red = "#e8707b", orange = "#efa363", yellow = "#e8c47c", green = "#9ccc7e",
  cyan = "#62c3cc", blue = "#6cb2f0", purple = "#c58ae8",
}

local hl = {
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { fg = c.fg, bg = c.bg },
  LineNr = { fg = "#3a3f49" },
  CursorLineNr = { fg = c.yellow },
  CursorLine = { bg = c.bg2 },
  StatusLine = { fg = c.fg, bg = c.bg3 },
  StatusLineNC = { fg = c.dim, bg = c.bg2 },
  WinSeparator = { fg = c.bg3 },
  EndOfBuffer = { fg = c.bg },
  NonText = { fg = c.dim },
  MsgArea = { fg = c.fg },
  Comment = { fg = c.dim, italic = true },
  String = { fg = c.green },
  Constant = { fg = c.orange, bold = true },
  Number = { fg = c.orange },
  Boolean = { fg = c.orange },
  Function = { fg = c.blue, bold = true },
  Identifier = { fg = c.fg },
  Statement = { fg = c.purple },
  Keyword = { fg = c.purple },
  Operator = { fg = c.cyan },
  Type = { fg = c.yellow },
  Special = { fg = c.cyan },
  PreProc = { fg = c.red },
  Title = { fg = c.purple, bold = true },
  Underlined = { fg = c.blue, underline = true },
  Delimiter = { fg = c.dim },
  ["@variable"] = { fg = c.fg },
  ["@field"] = { fg = c.red },
  ["@punctuation.bracket"] = { fg = c.dim },
  ["@constructor"] = { fg = c.dim },
  markdownH1 = { fg = c.purple, bold = true },
  markdownH2 = { fg = c.orange, bold = true },
  markdownHeadingDelimiter = { fg = c.dim },
  markdownCode = { fg = c.green },
  markdownCodeBlock = { fg = c.green },
  markdownCodeDelimiter = { fg = c.dim },
  markdownListMarker = { fg = c.cyan },
  markdownOrderedListMarker = { fg = c.cyan },
  markdownBlockquote = { fg = c.dim },
  markdownLinkText = { fg = c.blue },
  markdownUrl = { fg = c.dim },
  markdownBold = { bold = true },
  markdownItalic = { italic = true },
  markdownRule = { fg = c.dim },
}
for name, spec in pairs(hl) do
  vim.api.nvim_set_hl(0, name, spec)
end

require("glance").setup()
