--- *textobject-hud.nvim* Show structural textobjects available at cursor
---
--- `textobject-hud.nvim` opens a small cursor-local HUD for Tree-sitter
--- textobject captures. It discovers captures from `textobjects.scm`, previews
--- the exact source range under the HUD cursor, and selects that range with
--- `<CR>`.
---
--- Key hints are display-only; textobjects are discovered automatically from
--- `textobjects.scm` when those query files are available on 'runtimepath'.
--- Generic Tree-sitter ancestor nodes can be enabled, but are off by default
--- because they are AST node types, not textobject captures.
---
--- # Setup ~
---
--- Minimal setup:
--- >lua
---   require("textobject-hud").setup()
--- <
---
--- Suggested mapping:
--- >lua
---   vim.keymap.set("n", "<leader>o", function()
---     require("textobject-hud").open()
---   end, { desc = "Open textobject HUD" })
--- <
---
--- Optional dependency: `nvim-treesitter-textobjects` query files on
--- 'runtimepath' provide capture-based entries like `@function.outer` and
--- `@parameter.inner`.
---
--- # Usage ~
---
--- Open the HUD with |:TextobjectHud| or `require("textobject-hud").open()`.
---
--- Controls inside the HUD:
--- >
---   <CR>          Select candidate
---   q / <Esc>     Close HUD
--- <
---
--- Use native window movement (`j`, `k`, arrows, `<C-d>`, `<C-u>`, mouse, ...)
--- to move the HUD cursor. The source preview follows the HUD cursor.
---
--- # Commands ~
---
---                                                        *:TextobjectHud*
--- `:TextobjectHud`
---     Open the HUD at the current cursor position.
---
---                                                 *:TextobjectHudInspect*
--- `:TextobjectHudInspect`
---     Print collected candidates for debugging.

local M = {}

--- Setup global configuration.
---@param opts? TextobjectHudConfig
function M.setup(opts)
  local config = require("textobject-hud.config")
  local highlight = require("textobject-hud.highlight")

  config.setup(opts or {})
  highlight.setup()
end

--- Open the HUD at the current cursor position.
---@param opts? TextobjectHudConfig
function M.open(opts)
  local config = require("textobject-hud.config")
  local hud = require("textobject-hud.hud")
  local merged = opts and vim.tbl_deep_extend("force", config.get(), opts) or config.get()

  return hud.open(merged)
end

--- Close the active HUD.
function M.close()
  return require("textobject-hud.hud").close()
end

--- Print and return candidates collected at the current cursor.
function M.inspect()
  return require("textobject-hud.hud").inspect()
end

return M
