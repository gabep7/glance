if vim.g.loaded_glance then
  return
end
vim.g.loaded_glance = true

local function glance()
  local g = require("glance")
  if not g.did_setup then
    g.setup()
  end
  return g
end

vim.api.nvim_create_user_command("Glance", function() glance().open() end, { desc = "Open markdown preview" })
vim.api.nvim_create_user_command("GlanceStop", function() glance().close() end, { desc = "Close markdown preview" })
vim.api.nvim_create_user_command("GlanceToggle", function() glance().toggle() end, { desc = "Toggle markdown preview" })

-- default keymaps unless the user calls setup() themselves
vim.schedule(function()
  glance()
end)
