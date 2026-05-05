-- glance.lua — nvim split preview for markdown

local M = {
  mode = "split",
  binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance"),
}

local state = {
  tmpfile = nil,
  term_buf = nil,
  term_win = nil,
  source_buf = nil,
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

-- debounce: 100ms after last change
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

  -- close existing preview if any
  M.stop()

  state.source_buf = buf
  state.tmpfile = os.tmpname() .. ".md"

  -- initial write
  write_to_tmp()

  -- create split on the right
  vim.cmd("rightbelow vsplit")
  state.term_win = vim.api.nvim_get_current_win()

  -- open terminal
  vim.fn.termopen({ M.binary, "--tui", "--watch", state.tmpfile })
  state.term_buf = vim.api.nvim_get_current_buf()

  -- suppress terminal buffer noise
  local tb = state.term_buf
  vim.bo[tb].buflisted = false
  vim.bo[tb].bufhidden = "wipe"
  vim.bo[tb].modifiable = false
  vim.wo[state.term_win].number = false
  vim.wo[state.term_win].signcolumn = "no"
  vim.wo[state.term_win].statuscolumn = ""

  -- go back to source window (left side)
  vim.cmd("wincmd p")

  -- reset cursor to trigger first update
  schedule_update()

  -- live update on text changes
  state.autocmds[1] = vim.api.nvim_create_autocmd("TextChanged", {
    buffer = buf,
    callback = schedule_update,
  })
  state.autocmds[2] = vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = schedule_update,
  })

  -- cleanup when source buffer closes
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
  state.term_win = nil
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
