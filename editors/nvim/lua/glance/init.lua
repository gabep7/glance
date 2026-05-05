-- glance.lua — nvim split preview for markdown

local M = {
  mode = "split",
  binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance"),
}

local state = {
  job_id = nil,
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
end

local function send_content()
  if not state.job_id or state.job_id <= 0 then
    return
  end
  if not state.source_win then
    return
  end
  local buf = vim.api.nvim_win_get_buf(state.source_win)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, "\n")
  local msg = #content .. "\n" .. content
  vim.fn.chansend(state.job_id, msg)
end

function M.open()
  -- check binary exists
  if vim.fn.filereadable(M.binary) == 0 then
    vim.notify("glance: binary not found at " .. M.binary, vim.log.levels.ERROR)
    return
  end

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

  -- create new empty buffer for terminal
  state.term_buf = vim.api.nvim_create_buf(false, true)

  -- open window on the right
  local width = math.floor(vim.o.columns * 0.45)
  state.term_win = vim.api.nvim_open_win(state.term_buf, true, {
    split = "right",
    width = width,
  })

  -- start glance in terminal
  local cmd = M.binary .. " --pipe"
  local ok, job_id = pcall(vim.fn.termopen, cmd)
  if not ok or job_id <= 0 then
    vim.notify("glance: failed to start terminal job", vim.log.levels.ERROR)
    M.stop()
    return
  end
  state.job_id = job_id

  -- configure terminal window
  vim.bo[state.term_buf].buflisted = false
  vim.bo[state.term_buf].bufhidden = "wipe"
  vim.wo[state.term_win].number = false
  vim.wo[state.term_win].signcolumn = "no"

  -- go back to source window
  vim.api.nvim_set_current_win(state.source_win)

  -- send initial content after terminal settles
  vim.fn.timer_start(200, function()
    send_content()
  end)

  -- live update on every text change
  state.autocmds[1] = vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = send_content,
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
  if state.job_id and state.job_id > 0 then
    pcall(vim.fn.jobstop, state.job_id)
    state.job_id = nil
  end
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
