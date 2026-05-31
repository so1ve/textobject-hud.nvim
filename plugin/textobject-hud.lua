if vim.g.loaded_textobject_hud then
  return
end

vim.g.loaded_textobject_hud = true

vim.api.nvim_create_user_command("TextobjectHud", function()
  require("textobject-hud").open()
end, { desc = "Open textobject HUD at the cursor" })

vim.api.nvim_create_user_command("TextobjectHudInspect", function()
  require("textobject-hud").inspect()
end, { desc = "Print textobject HUD candidates at the cursor" })
