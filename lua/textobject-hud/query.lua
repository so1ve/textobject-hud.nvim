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
---@return TextobjectHudCandidate[]
function M.collect_ancestors(ctx, opts)
  if not ctx.node then
    return {}
  end

  local result = {}
  local node = ctx.node
  local depth = 0

  while node and depth < opts.collect.max_ancestor_depth do
    if opts.collect.include_anonymous or node:named() then
      local range = node_range(node)
      result[#result + 1] = {
        name = node:type(),
        label = node:type():gsub("_", " "),
        source = "ancestor",
        bufnr = ctx.bufnr,
        node = node,
        range = range,
        priority = 10 + depth,
      }
    end

    node = node:parent()
    depth = depth + 1
  end

  return result
end

---@param ctx TextobjectHudContext
---@param opts TextobjectHudConfig
---@return TextobjectHudCandidate[]
function M.collect_textobjects(ctx, opts)
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
      result[#result + 1] = {
        name = capture:gsub("^@", ""),
        label = capture:gsub("^@", ""),
        source = "textobjects",
        capture = capture,
        keys = opts.key_hints[capture],
        bufnr = ctx.bufnr,
        node = node,
        range = range,
        priority = 80,
      }
    end
  end

  return result
end

return M
