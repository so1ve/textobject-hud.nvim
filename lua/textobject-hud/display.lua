local M = {}

local function width(text)
  return vim.fn.strdisplaywidth(text or "")
end

local function truncate(text, max_width)
  text = text or ""

  if max_width <= 0 then
    return ""
  end

  if width(text) <= max_width then
    return text
  end

  if max_width == 1 then
    return "…"
  end

  local result = ""
  local index = 0

  while true do
    local char = vim.fn.strcharpart(text, index, 1)
    if char == "" then
      break
    end

    if width(result .. char .. "…") > max_width then
      break
    end

    result = result .. char
    index = index + 1
  end

  return result .. "…"
end

local function pad_right(text, max_width)
  return text .. string.rep(" ", math.max(0, max_width - width(text)))
end

local function pad_left(text, max_width)
  return string.rep(" ", math.max(0, max_width - width(text))) .. text
end

---@param item TextobjectHudCandidate
---@return string
local function label_for_item(item)
  return item.capture or item.label or item.name or "object"
end

---@param candidates TextobjectHudCandidate[]
---@param total_width integer
---@return table
function M.layout(candidates, total_width)
  local label_width = 1
  local key_width = 0

  for _, item in ipairs(candidates) do
    label_width = math.max(label_width, width(label_for_item(item)))
    key_width = math.max(key_width, width(item.key_hint or ""))
  end

  key_width = math.min(key_width, math.max(0, total_width - 3))
  label_width = math.min(label_width, math.max(1, total_width - (key_width > 0 and key_width + 2 or 0)))

  return {
    width = total_width,
    label_width = label_width,
    key_width = key_width,
  }
end

---@param item TextobjectHudCandidate
---@param layout table
---@return string
function M.line(item, layout)
  local label = truncate(label_for_item(item), layout.label_width)
  local key = truncate(item.key_hint or "", layout.key_width)
  local left = pad_right(label, layout.label_width)

  if layout.key_width > 0 then
    return left .. "  " .. pad_left(key, layout.key_width)
  end

  return left
end

---@param candidates TextobjectHudCandidate[]
---@param total_width integer
---@return string[]
function M.render(candidates, total_width)
  if #candidates == 0 then
    return { "No textobjects at cursor" }
  end

  local layout = M.layout(candidates, total_width)
  local lines = {}

  for _, item in ipairs(candidates) do
    lines[#lines + 1] = M.line(item, layout)
  end

  return lines
end

return M
