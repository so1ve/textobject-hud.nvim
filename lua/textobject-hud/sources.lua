local builtin = require("textobject-hud.sources.builtin")
local mini_ai = require("textobject-hud.sources.mini_ai")
local treesitter = require("textobject-hud.sources.treesitter")

local M = {}

--- # Sources ~
---
--- Built-in source descriptors are available from
--- `require("textobject-hud").sources` and can be placed directly in
--- |TextobjectHudConfig.sources|.
---
--- Example:
--- >lua
---   local hud = require("textobject-hud")
---
---   hud.setup({
---     sources = { hud.sources.mini_ai },
---   })
--- <
---
--- Available built-ins:
--- - `hud.sources.treesitter`: captures from `textobjects.scm`.
--- - `hud.sources.mini_ai`: configured mini.ai textobjects.
--- - `hud.sources.builtin`: fixed Vim/Neovim built-in textobject keys.
--- - `hud.sources.treesitter_ancestors`: generic Tree-sitter AST ancestors.
---
---@class TextobjectHudSource
---@field name string Source name shown in the HUD as a trailing comment-style column.
---@field key_prefix string Prefix used by `key_hints`, before the `:`.
---@field collect fun(ctx: TextobjectHudContext, opts: TextobjectHudConfig, source: TextobjectHudSource): TextobjectHudCandidate[]

M.treesitter = {
  name = "treesitter",
  key_prefix = "treesitter",
  collect = treesitter.collect_captures,
}

M.treesitter_ancestors = {
  name = "treesitter ancestors",
  key_prefix = "treesitter_ancestors",
  collect = treesitter.collect_ancestors,
}

M.mini_ai = {
  name = "mini.ai",
  key_prefix = "mini_ai",
  collect = mini_ai.collect,
}

M.builtin = {
  name = "builtin",
  key_prefix = "builtin",
  collect = builtin.collect,
}

return M
