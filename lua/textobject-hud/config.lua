local M = {}

--- # Options ~
---
--- Configuration is passed to `require("textobject-hud").setup()`.
---
---@class TextobjectHudWindowConfig
---@field border string | string[] Floating window border.
---@field width integer HUD width.
---@field max_height integer Maximum HUD height.
---@field row_offset integer Row offset from the source cursor.
---@field col_offset integer Column offset from the source cursor.
---@field follow boolean Reposition the HUD when the source cursor or source
---  window changes.

---@class TextobjectHudPreviewConfig
---@field enabled boolean Highlight the selected range while the HUD is open.
---@field hl_group string Highlight group used for source range preview.

---@class TextobjectHudCollectConfig
---@field ancestors boolean Include generic Tree-sitter ancestor nodes. These
---  are AST node types, not textobject captures.
---@field textobjects boolean Include automatically discovered captures from
---  `textobjects.scm` when query files exist.
---@field max_ancestor_depth integer Maximum number of containing ancestor nodes to inspect.
---@field max_lines integer Ignore very large ranges.
---@field include_anonymous boolean Include anonymous Tree-sitter nodes in ancestor candidates.

---@class TextobjectHudConfig
---@field window TextobjectHudWindowConfig Floating window options.
---@field preview TextobjectHudPreviewConfig Source preview options.
---@field collect TextobjectHudCollectConfig Candidate collection options.
---@field key_hints table<string, string | string[]> Display-only capture-to-keys mapping.

--- # Default config ~
---
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text
--- `key_hints` maps capture names to display-only hints:
--- >lua
---   require("textobject-hud").setup({
---     key_hints = {
---       ["@function.outer"] = { "]f", "[f", "]F", "[F" },
---       ["@function.inner"] = "if",
---     },
---   })
--- <
---
--- This table does not define or whitelist textobjects. Captures are discovered
--- from `textobjects.scm` automatically.
---
--minidoc_replace_start require("textobject-hud").setup({
-- stylua: ignore start
local defaults = {
--minidoc_replace_end
  -- Floating HUD window.
  window = {
    border = "rounded",
    width = 50,
    max_height = 12,
    row_offset = 1,
    col_offset = 1,
    follow = true,
  },

  -- Source-buffer range preview shown while the HUD is open.
  preview = {
    enabled = true,
    hl_group = "TextobjectHudRange",
  },

  -- Candidate sources and safety limits.
  -- `textobjects` discovers captures from `textobjects.scm` automatically.
  -- `ancestors` adds generic AST nodes, so it is disabled by default.
  collect = {
    ancestors = false,
    textobjects = true,
    max_ancestor_depth = 20,
    max_lines = 200,
    include_anonymous = false,
  },

  -- Display-only capture-to-keys mapping. This does not define or whitelist
  -- textobjects; it only annotates captures that were already discovered.
  key_hints = {},
--minidoc_replace_start })
}
-- stylua: ignore end
--minidoc_replace_end
--minidoc_afterlines_end

local options

---@private
---@param opts TextobjectHudConfig
---@return TextobjectHudConfig
function M.setup(opts)
  options = vim.tbl_deep_extend("force", defaults, opts)
  return options
end

---@private
---@return TextobjectHudConfig
function M.get()
  return options or defaults
end

return M
