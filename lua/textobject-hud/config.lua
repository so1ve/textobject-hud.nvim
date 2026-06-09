--minidoc_replace_start local hud = require("textobject-hud")
local hud = { sources = require("textobject-hud.sources") }
--minidoc_replace_end

local M = {}

--- # Options ~
---
--- Configuration is passed to `require("textobject-hud").setup()`.
---
---@class TextobjectHudWindowConfig
---@field border string | string[] Floating window border.
---@field max_height integer Maximum HUD height.
---@field row_offset integer Vertical gap from the selected range, or cursor fallback.
---@field col_offset integer Horizontal gap from the selected range, or cursor fallback.
---@field follow boolean Reposition the HUD when the source cursor or source
---  window changes.

---@class TextobjectHudPreviewConfig
---@field enabled boolean Highlight the selected range while the HUD is open.
---@field hl_group string Highlight group used for source range preview.

---@class TextobjectHudCollectConfig
---@field max_ancestor_depth integer Maximum number of containing ancestor nodes to inspect.
---@field max_lines integer Ignore very large ranges.
---@field include_anonymous boolean Include anonymous Tree-sitter nodes in ancestor candidates.

---@class TextobjectHudConfig
---@field window TextobjectHudWindowConfig Floating window options.
---@field preview TextobjectHudPreviewConfig Source preview options.
---@field sources TextobjectHudSource[] Candidate sources. Use
---  `require("textobject-hud").sources.*` entries.
---@field collect TextobjectHudCollectConfig Candidate collection options.
---@field key_hints table<string, string | string[]> Display-only source-prefixed
---  candidate-to-keys mapping.

--- # Default config ~
---
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@text
--- `key_hints` maps source-prefixed candidate names to display-only hints:
--- >lua
---   local hud = require("textobject-hud")
---
---   hud.setup({
---     sources = { hud.sources.treesitter, hud.sources.mini_ai, hud.sources.builtin },
---     key_hints = {
---       ["treesitter:@function.outer"] = { "]f", "[f", "]F", "[F" },
---       ["treesitter:@function.inner"] = "if",
---       ["mini_ai:a("] = "a(",
---       ["builtin:iw"] = "iw",
---     },
---   })
--- <
---
--- This table does not define or whitelist textobjects. Candidates are
--- discovered from configured sources automatically.
---
--minidoc_replace_start local hud = require("textobject-hud")
-- This line is replaced in generated docs.
--minidoc_replace_end
--minidoc_replace_start hud.setup({
-- stylua: ignore start
local defaults = {
--minidoc_replace_end
  -- Floating HUD window. It prefers the right side and avoids the selected range.
  window = {
    border = "rounded",
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

  -- Candidate sources. Replace this list to choose exactly which sources run.
  -- Built-ins are available as `require("textobject-hud").sources.*`.
  sources = {
    hud.sources.treesitter,
    hud.sources.mini_ai,
    hud.sources.builtin,
  },

  -- Source safety limits.
  -- `max_ancestor_depth` and `include_anonymous` affect `treesitter_ancestors`.
  collect = {
    max_ancestor_depth = 20,
    max_lines = 200,
    include_anonymous = false,
  },

  -- Display-only source-prefixed candidate-to-keys mapping. This does not define
  -- or whitelist textobjects; it only annotates candidates that were discovered.
  key_hints = {},
--minidoc_replace_start })
}
-- stylua: ignore end
--minidoc_replace_end
--minidoc_afterlines_end

local options

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

---@private
---@param opts TextobjectHudConfig
---@return TextobjectHudConfig
function M.setup(opts)
  options = merge_options(defaults, opts)
  return options
end

---@private
---@return TextobjectHudConfig
function M.get()
  return options or defaults
end

return M
