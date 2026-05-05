-- glance.lua — nvim split preview for markdown

local M = {
  mode = "split",
  binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance"),
}

local state = {
  tmpfile = nil,
  term_buf = nil,
  term_win = nil,
  source_win = nil,
  autocmds = {},
}

local function cleanup()
  for _, id in ipairs(state.autocmds) do
    pcall(vim.api.nvim_del_autocmd, id)
  end
  state.autocmds = {}
  if state.tmpfile then
    os.remove(state.tmpfile)
    state.tmpfile = nil
  end
end

local function write_to_tmp()
  if not state.tmpfile or not state.source_win then
    return
  end
  if not vim.api.nvim_win_is_valid(state.source_win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(state.source_win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local f = io.open(state.tmpfile, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end
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

  -- create temp file and write initial content
  state.tmpfile = os.tmpname() .. ".md"
  write_to_tmp()

  -- create split on the right and open terminal
  vim.cmd("rightbelow vnew")
  vim.cmd("terminal " .. M.binary .. " --tui --watch " .. state.tmpfile)
  state.term_win = vim.api.nvim_get_current_win()
  state.term_buf = vim.api.nvim_get_current_buf()

  -- configure terminal window
  vim.bo[state.term_buf].buflisted = false
  vim.bo[state.term_buf].bufhidden = "wipe"
  vim.wo[state.term_win].number = false
  vim.wo[state.term_win].signcolumn = "no"

  -- go back to source window
  vim.api.nvim_set_current_win(state.source_win)

  -- live update on every text change (no debounce)
  state.autocmds[1] = vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = write_to_tmp,
  })

  -- cleanup when source buffer closes
  state.autocmds[2] = vim.api.nvim_create_autocmd("BufUnload", {
    buffer = buf,
    callback = function()
      M.stop()
    end,
  })
end

function M.stop()
  cleanup()
  if state.term_win and vim.api.nvim_win_is_valid(state.term_win) then
    pcall(vim.api.nvim_win_close, state.term_win, true)
  end
  if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
    pcall(vim.api.nvim_buf_delete, state.term_buf, { force = true })
  end
  state.term_buf = nil
  state.term_win = nil
  state.source_win = nil
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
