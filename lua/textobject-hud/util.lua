local M = {}

---@class TextobjectHudRange
---@field start_row integer
---@field start_col integer
---@field end_row integer
---@field end_col integer

---@param range TextobjectHudRange
---@return string
function M.range_key(range)
  return table.concat({ range.start_row, range.start_col, range.end_row, range.end_col }, ":")
end

---@param range TextobjectHudRange
---@param cursor { row: integer, col: integer }
---@return boolean
function M.range_contains_cursor(range, cursor)
  if cursor.row < range.start_row or cursor.row > range.end_row then
    return false
  end

  if cursor.row == range.start_row and cursor.col < range.start_col then
    return false
  end

  if cursor.row == range.end_row and cursor.col >= range.end_col then
    return false
  end

  return true
end

---@param range TextobjectHudRange
---@return integer
function M.line_count(range)
  local count = range.end_row - range.start_row
  if range.end_col > 0 then
    count = count + 1
  end
  return math.max(1, count)
end

---@param range TextobjectHudRange
---@return integer
function M.range_size(range)
  return (range.end_row - range.start_row) * 100000 + math.max(0, range.end_col - range.start_col)
end

return M
