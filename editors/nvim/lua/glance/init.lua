-- glance.lua — nvim integration for glance markdown preview daemon

local M = {}

-- path to the glance binary
M.binary = vim.fn.expand("~/Projects/Personal/glance/target/release/glance")

function M.open()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)

  if path == "" then
    vim.notify("glance: buffer has no file", vim.log.levels.WARN)
    return
  end

  if vim.bo[buf].filetype ~= "markdown" and not path:match("%.md$") then
    vim.notify("glance: not a markdown file", vim.log.levels.WARN)
    return
  end

  vim.fn.jobstart({ M.binary, path }, { detach = true })
  vim.notify("glance: opened " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
end

function M.setup(opts)
  if opts and opts.binary then
    M.binary = opts.binary
  end

  vim.api.nvim_create_user_command("Glance", function()
    M.open()
  end, {})

  vim.api.nvim_create_user_command("GlanceStop", function()
    vim.fn.jobstart({ "pkill", "-f", "glance" }, { detach = true })
    vim.notify("glance: stopped", vim.log.levels.INFO)
  end, {})
end

return M
