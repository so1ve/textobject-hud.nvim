local M = {}

---@class TextobjectHudSourceCandidateFields
---@field name string
---@field label? string
---@field key? string
---@field bufnr integer
---@field range TextobjectHudRange
---@field priority? integer
---@field node? TSNode
---@field capture? string

---@param opts TextobjectHudConfig
---@param source TextobjectHudSource
---@param fields TextobjectHudSourceCandidateFields
---@return TextobjectHudCandidate
function M.candidate(opts, source, fields)
  local key = fields.key or fields.name

  return {
    name = fields.name,
    label = fields.label or fields.name,
    source = source.name,
    key_prefix = source.key_prefix,
    keys = opts.key_hints[(source.key_prefix or source.name) .. ":" .. key],
    bufnr = fields.bufnr,
    range = fields.range,
    priority = fields.priority,
    node = fields.node,
    capture = fields.capture,
  }
end

return M
