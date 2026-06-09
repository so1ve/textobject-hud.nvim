--- *textobject-hud.nvim* Show selectable ranges available near cursor
---
--- `textobject-hud.nvim` opens a small HUD for textobjects and other selectable
--- ranges near the cursor. It collects candidates from configured sources,
--- previews the exact source range under the HUD cursor, avoids the selected
--- range when possible, and selects that range with `<CR>`.
---
--- Built-in sources include Tree-sitter captures from `textobjects.scm`,
--- mini.ai textobjects when available, and Vim/Neovim built-in textobjects.
--- Key hints are display-only and do not define, whitelist, or override
--- textobjects.
---
--- Built-in source objects are exposed as `require("textobject-hud").sources`.
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
--- Optional sources:
--- - `nvim-treesitter-textobjects` query files on 'runtimepath' provide
---   capture-based entries like `@function.outer` and `@parameter.inner`.
--- - `mini.ai` provides configurable textobjects like arguments, brackets,
---   quotes, functions, and custom specs.
--- - `hud.sources.builtin` probes Vim/Neovim built-in textobjects like `iw`,
---   `a"`, `i(`, and `ap`.
--- - `hud.sources.treesitter_ancestors` adds generic AST node ranges when
---   explicitly included in `sources`.
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
---     Open the HUD near the selected range, with cursor fallback.
---
---                                                 *:TextobjectHudInspect*
--- `:TextobjectHudInspect`
---     Print collected candidates for debugging.

local M = {}

M.sources = require("textobject-hud.sources")

---@private
---@param base TextobjectHudConfig
---@param opts TextobjectHudConfig
---@return TextobjectHudConfig
local function merge_options(base, opts)
  local sources = opts.sources
  local result = vim.tbl_deep_extend("force", base, opts)

  if sources then
    result.sources = sources
  end

  return result
end

--- Setup global configuration.
---@param opts? TextobjectHudConfig
function M.setup(opts)
  local config = require("textobject-hud.config")
  local highlight = require("textobject-hud.highlight")

  config.setup(opts or {})
  highlight.setup()
end

--- Open the HUD near the selected range, with cursor fallback.
---@param opts? TextobjectHudConfig
function M.open(opts)
  local config = require("textobject-hud.config")
  local hud = require("textobject-hud.hud")
  local merged = opts and merge_options(config.get(), opts) or config.get()

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
