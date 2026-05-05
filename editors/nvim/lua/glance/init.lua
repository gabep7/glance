-- glance.lua — nvim split preview for markdown

local M = {
  mode = "split",
  binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance"),
}

local state = {
  tmpfile = nil,
  cursor_file = nil,
  term_buf = nil,
  term_win = nil,
  source_win = nil,
  source_buf = nil,
}

local function write_to_tmp()
  if not state.tmpfile or not state.source_buf then
    return
  end
  if not vim.api.nvim_buf_is_valid(state.source_buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(state.source_buf, 0, -1, false)
  local f = io.open(state.tmpfile, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end
end

local function write_cursor_line()
  if not state.cursor_file or not state.source_win then
    return
  end
  if not vim.api.nvim_win_is_valid(state.source_win) then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(state.source_win)
  local row = cursor[1] - 1 -- 0-indexed for rust
  local f = io.open(state.cursor_file, "w")
  if f then
    f:write(tostring(row))
    f:close()
  end
end



local function on_cursor_moved()
  write_cursor_line()
end

function M.open()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if path == "" then
    vim.notify("glance: buffer has no file", vim.log.levels.WARN)
    return
  end

  if not path:match("%.md$") and vim.bo[buf].filetype ~= "markdown" then
    vim.notify("glance: not a markdown file", vim.log.levels.WARN)
    return
  end

  M.stop()
  state.source_win = vim.api.nvim_get_current_win()
  state.source_buf = buf

  -- create temp files
  state.tmpfile = os.tmpname() .. ".md"
  state.cursor_file = os.tmpname() .. ".cursor"
  write_to_tmp()
  write_cursor_line()

  -- create split on the right and open terminal
  vim.cmd("rightbelow vnew")
  vim.cmd("terminal " .. M.binary
    .. " --tui --watch"
    .. " --cursor-file " .. state.cursor_file
    .. " " .. state.tmpfile)
  state.term_win = vim.api.nvim_get_current_win()
  state.term_buf = vim.api.nvim_get_current_buf()

  -- configure terminal window
  vim.bo[state.term_buf].buflisted = false
  vim.bo[state.term_buf].bufhidden = "wipe"
  vim.wo[state.term_win].number = false
  vim.wo[state.term_win].signcolumn = "no"

  -- go back to source window
  vim.api.nvim_set_current_win(state.source_win)

  -- attach to buffer changes — on_lines fires on every text change
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(...)
      write_to_tmp()
    end,
  })

  -- track cursor movement for scroll sync (immediate, poll loop caps rate)
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = on_cursor_moved,
  })

  -- cleanup when source buffer closes
  vim.api.nvim_create_autocmd("BufUnload", {
    buffer = buf,
    once = true,
    callback = function()
      M.stop()
    end,
  })
end

function M.stop()
  if state.term_win and vim.api.nvim_win_is_valid(state.term_win) then
    pcall(vim.api.nvim_win_close, state.term_win, true)
  end
  if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
    pcall(vim.api.nvim_buf_delete, state.term_buf, { force = true })
  end
  if state.tmpfile then
    os.remove(state.tmpfile)
    state.tmpfile = nil
  end
  if state.cursor_file then
    os.remove(state.cursor_file)
    state.cursor_file = nil
  end
  state.term_buf = nil
  state.term_win = nil
  state.source_win = nil
  state.source_buf = nil
end

function M.setup(opts)
  opts = opts or {}
  M.mode = opts.mode or M.mode
  if opts.binary then
    M.binary = opts.binary
  end

  vim.api.nvim_create_user_command("Glance", function()
    M.open()
  end, {})

  vim.api.nvim_create_user_command("GlanceStop", function()
    M.stop()
  end, {})
end

return M
