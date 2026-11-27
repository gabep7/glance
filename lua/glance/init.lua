-- glance: markdown preview in a neovim split

local render = require("glance.render")

local uv = vim.uv or vim.loop
local api = vim.api

local M = {}

local defaults = {
  -- ms to wait after the last edit before re-rendering
  debounce = 30,
  -- "right" or "left"
  position = "right",
  -- preview width in columns; nil splits evenly
  width = nil,
  -- keep the preview scrolled to the cursor in the source window
  scroll_sync = true,
  -- set to false to skip default keymaps
  keymaps = {
    toggle = "<leader>gp",
    focus = "<leader>gf",
    sync = "<leader>gs",
  },
}

M.config = vim.deepcopy(defaults)

local ns = api.nvim_create_namespace("glance")

local state = {
  src_buf = nil,
  src_win = nil,
  buf = nil,
  win = nil,
  map = nil,
  timer = nil,
  session = 0,
  sync = true,
}

---------------------------------------------------------------------------
-- highlights
---------------------------------------------------------------------------

local highlights = {
  GlanceH1 = { link = "Title" },
  GlanceH2 = { link = "Constant" },
  GlanceH3 = { link = "Function" },
  GlanceH4 = { link = "Statement" },
  GlanceH5 = { link = "Type" },
  GlanceH6 = { link = "Special" },
  GlanceBold = { bold = true },
  GlanceItalic = { italic = true },
  GlanceBoldItalic = { bold = true, italic = true },
  GlanceStrike = { strikethrough = true },
  GlanceCode = { link = "String" },
  GlanceCodeBlock = { link = "CursorLine" },
  GlanceCodeLang = { link = "Comment" },
  GlanceLink = { link = "Underlined" },
  GlanceImage = { link = "Special" },
  GlanceQuote = { link = "Comment" },
  GlanceQuoteBar = { link = "Comment" },
  GlanceBullet = { link = "Special" },
  GlanceTodo = { link = "Comment" },
  GlanceDone = { link = "String" },
  GlanceDoneText = { link = "Comment" },
  GlanceRule = { link = "Comment" },
  GlanceTableBorder = { link = "Comment" },
  GlanceTableHeader = { bold = true },
  GlanceFrontmatter = { link = "Comment" },
}

local function set_highlights()
  for name, spec in pairs(highlights) do
    api.nvim_set_hl(0, name, vim.tbl_extend("force", spec, { default = true }))
  end
end

---------------------------------------------------------------------------
-- preview
---------------------------------------------------------------------------

local function valid_win(w)
  return w and api.nvim_win_is_valid(w)
end

local function valid_buf(b)
  return b and api.nvim_buf_is_valid(b)
end

local function is_open()
  return valid_win(state.win) and valid_buf(state.buf) and api.nvim_win_get_buf(state.win) == state.buf
end

local function is_markdown(buf)
  return vim.bo[buf].filetype == "markdown" or api.nvim_buf_get_name(buf):match("%.md$") ~= nil
end

local function sync_scroll()
  if not state.sync or not is_open() or not state.map then
    return
  end
  if not valid_win(state.src_win) or api.nvim_win_get_buf(state.src_win) ~= state.src_buf then
    return
  end
  local row = api.nvim_win_get_cursor(state.src_win)[1]
  local target = state.map[row]
  if not target then
    -- cursor past the last mapped line: use the closest one above it
    for r = row, 1, -1 do
      if state.map[r] then
        target = state.map[r]
        break
      end
    end
  end
  local total = api.nvim_buf_line_count(state.buf)
  target = math.max(1, math.min(target or 1, total))

  -- keep the target at the same screen row the cursor has in the source
  local screen_row = api.nvim_win_call(state.src_win, vim.fn.winline)
  local topline = math.max(1, target - screen_row + 1)
  api.nvim_win_call(state.win, function()
    vim.fn.winrestview({ topline = topline, lnum = target, col = 0 })
  end)
end

local function refresh()
  if not is_open() or not valid_buf(state.src_buf) then
    return
  end
  local src = api.nvim_buf_get_lines(state.src_buf, 0, -1, false)
  local width = api.nvim_win_get_width(state.win)
  local ok, result = pcall(render.render, src, { width = width })
  if not ok then
    vim.notify("glance: render failed: " .. tostring(result), vim.log.levels.ERROR)
    return
  end

  local buf = state.buf
  vim.bo[buf].modifiable = true
  api.nvim_buf_set_lines(buf, 0, -1, false, result.lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(result.line_hls) do
    api.nvim_buf_set_extmark(buf, ns, h[1], 0, { line_hl_group = h[2], priority = 10 })
  end
  for _, h in ipairs(result.hls) do
    if h[3] > h[2] then
      api.nvim_buf_set_extmark(buf, ns, h[1], h[2], {
        end_col = h[3],
        hl_group = h[4],
        priority = h[5],
        strict = false,
      })
    end
  end

  state.map = result.map
  sync_scroll()
end

local function schedule_refresh()
  if not state.timer then
    state.timer = uv.new_timer()
  end
  state.timer:stop()
  state.timer:start(M.config.debounce, 0, vim.schedule_wrap(refresh))
end

local function create_preview_buf(src_buf)
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "glance"
  local name = vim.fn.fnamemodify(api.nvim_buf_get_name(src_buf), ":t")
  pcall(api.nvim_buf_set_name, buf, "glance://" .. name)
  return buf
end

local function set_win_options(win)
  local opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    foldenable = false,
    colorcolumn = "",
    cursorline = false,
    list = false,
    spell = false,
    wrap = true,
    linebreak = true,
    breakindent = true,
    scrolloff = 0,
    winfixwidth = true,
    statuscolumn = "",
  }
  for k, v in pairs(opts) do
    pcall(api.nvim_set_option_value, k, v, { scope = "local", win = win })
  end
end

function M.close()
  state.session = state.session + 1
  if state.timer then
    state.timer:stop()
  end
  pcall(api.nvim_del_augroup_by_name, "GlanceSession")
  if valid_win(state.win) and #api.nvim_list_wins() > 1 then
    pcall(api.nvim_win_close, state.win, true)
  end
  if valid_buf(state.buf) then
    pcall(api.nvim_buf_delete, state.buf, { force = true })
  end
  state.buf, state.win, state.src_buf, state.src_win, state.map = nil, nil, nil, nil, nil
end

function M.open()
  local src_buf = api.nvim_get_current_buf()
  if not is_markdown(src_buf) then
    vim.notify("glance: not a markdown buffer", vim.log.levels.WARN)
    return
  end

  M.close()
  state.session = state.session + 1
  local session = state.session
  state.src_buf = src_buf
  state.src_win = api.nvim_get_current_win()
  state.sync = M.config.scroll_sync
  state.buf = create_preview_buf(src_buf)

  local side = M.config.position == "left" and "leftabove" or "rightbelow"
  vim.cmd(side .. " vertical sbuffer " .. state.buf)
  state.win = api.nvim_get_current_win()
  if M.config.width then
    api.nvim_win_set_width(state.win, M.config.width)
  end
  set_win_options(state.win)
  api.nvim_set_current_win(state.src_win)

  api.nvim_buf_attach(src_buf, false, {
    on_lines = function()
      if state.session ~= session then
        return true -- detach
      end
      schedule_refresh()
    end,
    on_reload = function()
      if state.session == session then
        schedule_refresh()
      end
    end,
  })

  local group = api.nvim_create_augroup("GlanceSession", { clear = true })
  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinScrolled" }, {
    group = group,
    buffer = src_buf,
    callback = sync_scroll,
  })
  api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = group,
    callback = schedule_refresh,
  })
  api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    buffer = src_buf,
    callback = function()
      vim.schedule(M.close)
    end,
  })
  api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(state.win),
    callback = function()
      vim.schedule(M.close)
    end,
  })

  refresh()
end

function M.toggle()
  if is_open() then
    M.close()
  else
    M.open()
  end
end

function M.focus()
  if not is_open() then
    return M.open()
  end
  if api.nvim_get_current_win() == state.win then
    if valid_win(state.src_win) then
      api.nvim_set_current_win(state.src_win)
    end
  else
    api.nvim_set_current_win(state.win)
  end
end

function M.toggle_sync()
  state.sync = not state.sync
  vim.notify("glance: scroll sync " .. (state.sync and "on" or "off"))
  sync_scroll()
end

---------------------------------------------------------------------------
-- setup
---------------------------------------------------------------------------

local mapped = {} -- buf -> { lhs, ... }

local function unmap_all()
  for buf, keys in pairs(mapped) do
    if valid_buf(buf) then
      for _, lhs in ipairs(keys) do
        pcall(vim.keymap.del, "n", lhs, { buffer = buf })
      end
    end
  end
  mapped = {}
end

local function map_buffer(buf)
  local km = M.config.keymaps
  if not km or mapped[buf] then
    return
  end
  local keys = {}
  local function map(lhs, fn, desc)
    if lhs then
      vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true, desc = desc })
      keys[#keys + 1] = lhs
    end
  end
  map(km.toggle, M.toggle, "Glance: toggle preview")
  map(km.focus, M.focus, "Glance: focus preview")
  map(km.sync, M.toggle_sync, "Glance: toggle scroll sync")
  mapped[buf] = keys
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts)
  if opts.keymaps == false then
    M.config.keymaps = false
  end
  M.did_setup = true

  set_highlights()

  local group = api.nvim_create_augroup("Glance", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })

  unmap_all()
  if M.config.keymaps then
    api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "markdown",
      callback = function(ev)
        map_buffer(ev.buf)
      end,
    })
    api.nvim_create_autocmd("BufWipeout", {
      group = group,
      callback = function(ev)
        mapped[ev.buf] = nil
      end,
    })
    for _, buf in ipairs(api.nvim_list_bufs()) do
      if api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
        map_buffer(buf)
      end
    end
  end
end

return M
