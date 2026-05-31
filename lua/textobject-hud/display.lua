local M = {}

local function width(text)
  return vim.fn.strdisplaywidth(text or "")
end

local function pad(text, max_width, align)
  local padding = string.rep(" ", math.max(0, max_width - width(text)))

  if align == "right" then
    return padding .. text
  end

  return text .. padding
end

local columns = {
  { name = "label", align = "left", min_width = 1 },
  { name = "key", align = "right", min_width = 0 },
  { name = "source", align = "left", min_width = 0 },
}

local separator = "  "

---@param column_widths integer[]
---@return integer
local function layout_width(column_widths)
  local total = 0
  local visible = 0

  for _, column_width in ipairs(column_widths) do
    if column_width > 0 then
      visible = visible + 1
      total = total + column_width
    end
  end

  return math.max(1, total + math.max(0, visible - 1) * width(separator))
end

---@param item TextobjectHudCandidate
---@return string[]
local function row_for_item(item)
  return {
    item.capture or item.label or item.name or "object",
    item.key_hint or "",
    item.source or "",
  }
end

---@param candidates TextobjectHudCandidate[]
---@return table
function M.layout(candidates)
  local rows = {}
  local widths = {}

  for index, column in ipairs(columns) do
    widths[index] = column.min_width or 0
  end

  for _, item in ipairs(candidates) do
    local row = row_for_item(item)
    rows[#rows + 1] = row

    for index, text in ipairs(row) do
      widths[index] = math.max(widths[index], width(text))
    end
  end

  local layout_columns = {}

  for index, column in ipairs(columns) do
    layout_columns[index] = {
      name = column.name,
      align = column.align,
      width = widths[index],
    }
  end

  return {
    width = layout_width(widths),
    columns = layout_columns,
    rows = rows,
  }
end

---@param item TextobjectHudCandidate
---@param layout table
---@return string, integer?, integer?
function M.line(item, layout)
  local row = row_for_item(item)
  local parts = {}
  local source_start
  local source_end
  local line_width = 0

  for index, column in ipairs(layout.columns) do
    if column.width > 0 then
      if #parts > 0 then
        parts[#parts + 1] = separator
        line_width = line_width + #separator
      end

      local text = row[index] or ""
      if column.name == "source" and text ~= "" then
        source_start = line_width
        source_end = source_start + #text
      end

      local cell = pad(text, column.width, column.align)
      parts[#parts + 1] = cell
      line_width = line_width + #cell
    end
  end

  return table.concat(parts), source_start, source_end
end

---@param candidates TextobjectHudCandidate[]
---@param layout table
---@return string[], table[]
function M.render(candidates, layout)
  local lines = {}
  local highlights = {}

  for index, item in ipairs(candidates) do
    local line, source_start, source_end = M.line(item, layout)
    lines[index] = line

    if source_start and source_end and source_end > source_start then
      highlights[#highlights + 1] = {
        row = index - 1,
        start_col = source_start,
        end_col = source_end,
        hl_group = "TextobjectHudSource",
      }
    end
  end

  return lines, highlights
end

return M
