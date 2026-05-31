local source_util = require("textobject-hud.sources.util")
local util = require("textobject-hud.util")

local M = {}

---@param node TSNode
---@return TextobjectHudRange
local function node_range(node)
  local start_row, start_col, end_row, end_col = node:range()
  return { start_row = start_row, start_col = start_col, end_row = end_row, end_col = end_col }
end

---@param ctx TextobjectHudContext
---@param opts TextobjectHudConfig
---@param source TextobjectHudSource
---@return TextobjectHudCandidate[]
function M.collect_ancestors(ctx, opts, source)
  if not ctx.node then
    return {}
  end

  local result = {}
  local node = ctx.node
  local depth = 0

  while node and depth < opts.collect.max_ancestor_depth do
    if opts.collect.include_anonymous or node:named() then
      result[#result + 1] = source_util.candidate(opts, source, {
        name = node:type(),
        label = node:type():gsub("_", " "),
        bufnr = ctx.bufnr,
        node = node,
        range = node_range(node),
        priority = 10 + depth,
      })
    end

    node = node:parent()
    depth = depth + 1
  end

  return result
end

---@param ctx TextobjectHudContext
---@param opts TextobjectHudConfig
---@param source TextobjectHudSource
---@return TextobjectHudCandidate[]
function M.collect_captures(ctx, opts, source)
  if not ctx.root or not ctx.lang then
    return {}
  end

  local query = vim.treesitter.query.get(ctx.lang, "textobjects")
  if not query then
    return {}
  end

  local result = {}

  for id, node in query:iter_captures(ctx.root, ctx.bufnr, 0, -1) do
    local capture = "@" .. query.captures[id]
    local range = node_range(node)

    if util.range_contains_cursor(range, ctx.cursor) then
      result[#result + 1] = source_util.candidate(opts, source, {
        name = capture:gsub("^@", ""),
        key = capture,
        capture = capture,
        bufnr = ctx.bufnr,
        node = node,
        range = range,
        priority = 80,
      })
    end
  end

  return result
end

return M
