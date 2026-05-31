local util = require("textobject-hud.util")

local M = {}

---@class TextobjectHudCandidate
---@field id? string
---@field name string
---@field label string
---@field source string
---@field bufnr? integer
---@field range TextobjectHudRange
---@field node? TSNode
---@field priority? integer
---@field capture? string
---@field keys? string | string[]
---@field key_hint? string

---@param item TextobjectHudCandidate
---@return TextobjectHudCandidate
function M.normalize(item)
  local keys = item.keys
  if type(keys) == "string" then
    keys = { keys }
  end

  local normalized = vim.tbl_extend("force", item, {
    name = item.name or item.label or "object",
    label = item.label or item.name or "object",
    source = item.source or "custom",
    priority = item.priority or 0,
    keys = keys,
    key_hint = item.key_hint or (keys and table.concat(keys, " ") or nil),
  })

  normalized.id = normalized.id or table.concat({ normalized.source, normalized.name, util.range_key(item.range) }, ":")

  return normalized
end

---@param candidates TextobjectHudCandidate[]
---@param opts { cursor?: { row: integer, col: integer }, require_contains_cursor?: boolean, max_lines?: integer, bufnr?: integer }
---@return TextobjectHudCandidate[]
function M.prepare(candidates, opts)
  local by_range = {}

  for _, item in ipairs(candidates) do
    local normalized = M.normalize(item)
    local keep = true

    if opts.cursor and opts.require_contains_cursor ~= false then
      keep = util.range_contains_cursor(normalized.range, opts.cursor)
    end

    if keep and opts.max_lines and util.line_count(normalized.range) > opts.max_lines then
      keep = false
    end

    if keep then
      normalized.bufnr = normalized.bufnr or opts.bufnr
      local key = util.range_key(normalized.range)
      local current = by_range[key]

      if not current or (normalized.priority or 0) > (current.priority or 0) then
        by_range[key] = normalized
      end
    end
  end

  local result = vim.tbl_values(by_range)

  table.sort(result, function(left, right)
    local left_size = util.range_size(left.range)
    local right_size = util.range_size(right.range)

    if left_size ~= right_size then
      return left_size < right_size
    end

    if (left.priority or 0) ~= (right.priority or 0) then
      return (left.priority or 0) > (right.priority or 0)
    end

    return (left.capture or left.name) < (right.capture or right.name)
  end)

  return result
end

return M
