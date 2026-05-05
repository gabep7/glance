-- glance.lua — nvim split preview for markdown

local M = {
  mode = "split",
  binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance"),
}

local state = {
  tmpfile = nil,
  term_buf = nil,
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
  if not state.tmpfile then
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

-- debounce: 100ms
local timer = nil
local function schedule_update()
  if timer then
    vim.fn.timer_stop(timer)
  end
  timer = vim.fn.timer_start(100, function()
    timer = nil
    pcall(write_to_tmp)
  end)
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
  state.tmpfile = os.tmpname() .. ".md"
  write_to_tmp()

  -- create new window on the right with empty buffer
  vim.cmd("rightbelow vnew")
  local term_win = vim.api.nvim_get_current_win()

  -- run glance in terminal
  vim.fn.termopen({ M.binary, "--tui", "--watch", state.tmpfile })
  state.term_buf = vim.api.nvim_get_current_buf()

  -- configure terminal window
  local tb = state.term_buf
  vim.bo[tb].buflisted = false
  vim.bo[tb].bufhidden = "wipe"
  vim.wo[term_win].number = false
  vim.wo[term_win].signcolumn = "no"

  -- go back to source window
  vim.api.nvim_set_current_win(state.source_win)

  -- live update
  state.autocmds[1] = vim.api.nvim_create_autocmd("TextChanged", {
    buffer = buf,
    callback = schedule_update,
  })
  state.autocmds[2] = vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = schedule_update,
  })
  state.autocmds[3] = vim.api.nvim_create_autocmd("BufUnload", {
    buffer = buf,
    callback = function()
      M.stop()
    end,
  })
end

function M.stop()
  cleanup()
  if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
    vim.api.nvim_buf_delete(state.term_buf, { force = true })
  end
  state.term_buf = nil
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
