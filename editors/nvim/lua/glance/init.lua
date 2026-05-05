-- glance.lua — nvim integration for glance markdown preview
-- config:
--   require("glance").setup({ mode = "split" })  -- or "window"
--   mode = "split"  — preview in a vertical terminal split (live, no save needed)
--   mode = "window" — preview in a separate OS window

local M = {
  mode = "split",
  binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance"),
}

-- internal state
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
    vim.fn.delete(state.tmpfile)
    state.tmpfile = nil
  end
end

local function write_to_tmp()
  if not state.tmpfile or not state.source_buf then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(state.source_buf, 0, -1, false)
  vim.fn.writefile(lines, state.tmpfile)
end

-- debounced update: fires 150ms after last text change
local update_timer = nil
local function schedule_update()
  if update_timer then
    vim.fn.timer_stop(update_timer)
  end
  update_timer = vim.fn.timer_start(150, function()
    update_timer = nil
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

  -- cleanup previous preview if any
  cleanup()

  state.source_buf = buf

  if M.mode == "window" then
    vim.fn.jobstart({ M.binary, path }, { detach = true })
    vim.notify("glance: opened " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
    return
  end

  -- split mode: write to temp file, start tui watch in terminal split
  state.tmpfile = vim.fn.tempname() .. ".md"
  write_to_tmp()

  -- create vertical split
  vim.cmd("rightbelow vsplit")
  state.term_win = vim.api.nvim_get_current_win()

  -- open terminal with glance --tui --watch
  vim.fn.termopen({ M.binary, "--tui", "--watch", state.tmpfile })
  state.term_buf = vim.api.nvim_get_current_buf()

  -- go back to source window
  vim.cmd("wincmd p")

  -- set terminal buffer options
  vim.bo[state.term_buf].buflisted = false

  -- update temp file on text changes
  state.autocmds[1] = vim.api.nvim_create_autocmd("TextChanged", {
    buffer = buf,
    callback = schedule_update,
  })
  state.autocmds[2] = vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf,
    callback = schedule_update,
  })

  -- cleanup when source buffer is closed
  state.autocmds[3] = vim.api.nvim_create_autocmd("BufUnload", {
    buffer = buf,
    callback = function()
      cleanup()
      if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
        vim.api.nvim_buf_delete(state.term_buf, { force = true })
      end
    end,
  })

  vim.notify("glance: previewing " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
end

function M.stop()
  cleanup()
  if state.term_buf and vim.api.nvim_buf_is_valid(state.term_buf) then
    vim.api.nvim_buf_delete(state.term_buf, { force = true })
  end
  state.term_buf = nil
  state.term_win = nil
  vim.notify("glance: stopped", vim.log.levels.INFO)
end

function M.setup(opts)
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
