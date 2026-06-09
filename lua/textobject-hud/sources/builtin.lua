local source_util = require("textobject-hud.sources.util")
local util = require("textobject-hud.util")

local M = {}

local TEXTOBJECTS = {
  "iw",
  "aw",
  "iW",
  "aW",
  "is",
  "as",
  "ip",
  "ap",
  'i"',
  'a"',
  "i'",
  "a'",
  "i`",
  "a`",
  "i(",
  "a(",
  "i)",
  "a)",
  "ib",
  "ab",
  "i[",
  "a[",
  "i]",
  "a]",
  "i{",
  "a{",
  "i}",
  "a}",
  "iB",
  "aB",
  "i<",
  "a<",
  "i>",
  "a>",
  "it",
  "at",
}

local function leave_visual_mode()
  vim.cmd("silent! normal! \027")
end

---@param left { row: integer, col: integer }
---@param right { row: integer, col: integer }
---@return boolean
local function position_before(left, right)
  if left.row ~= right.row then
    return left.row < right.row
  end

  return left.col <= right.col
end

---@param bufnr integer
---@param row integer
---@param col integer
---@return integer
local function next_byte_col(bufnr, row, col)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  if col >= #line then
    return #line
  end

  local char_index = vim.fn.charidx(line, math.max(col, 0))
  if char_index < 0 then
    return math.min(col + 1, #line)
  end

  local next_col = vim.fn.byteidx(line, char_index + 1)
  if next_col < 0 then
    return #line
  end

  return next_col
end

---@param mark string
---@return { row: integer, col: integer }?
local function mark_position(mark)
  local position = vim.fn.getpos(mark)
  if position[2] <= 0 then
    return nil
  end

  return { row = position[2] - 1, col = math.max(position[3] - 1, 0) }
end

---@param bufnr integer
---@param register_type string
---@return TextobjectHudRange?
local function yanked_range(bufnr, register_type)
  local start_pos = mark_position("'[")
  local end_pos = mark_position("']")
  if not start_pos or not end_pos then
    return nil
  end

  if not position_before(start_pos, end_pos) then
    start_pos, end_pos = end_pos, start_pos
  end

  if register_type:sub(1, 1) == "V" then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    return {
      start_row = start_pos.row,
      start_col = 0,
      end_row = math.min(end_pos.row + 1, line_count),
      end_col = 0,
    }
  end

  if register_type:sub(1, 1) == "\022" then
    return nil
  end

  return {
    start_row = start_pos.row,
    start_col = start_pos.col,
    end_row = end_pos.row,
    end_col = next_byte_col(bufnr, end_pos.row, end_pos.col),
  }
end

---@param ctx TextobjectHudContext
---@param key string
---@return TextobjectHudRange?
local function probe_textobject(ctx, key)
  vim.api.nvim_win_set_cursor(ctx.win, { ctx.cursor.row + 1, ctx.cursor.col })
  pcall(vim.fn.setpos, "'[", { 0, 0, 0, 0 })
  pcall(vim.fn.setpos, "']", { 0, 0, 0, 0 })

  local ok = pcall(vim.api.nvim_cmd, {
    cmd = "normal",
    bang = true,
    args = { "y" .. key },
    mods = { silent = true, emsg_silent = true },
  }, {})

  leave_visual_mode()
  if not ok then
    return nil
  end

  local range = yanked_range(ctx.bufnr, vim.fn.getregtype('"'))
  if not range or not util.range_contains_cursor(range, ctx.cursor) then
    return nil
  end

  return range
end

---@param ctx TextobjectHudContext
---@param callback fun(): TextobjectHudCandidate[]
---@return TextobjectHudCandidate[]
local function with_restored_window(ctx, callback)
  return vim.api.nvim_win_call(ctx.win, function()
    local cursor = vim.api.nvim_win_get_cursor(ctx.win)
    local view = vim.fn.winsaveview()
    local search = vim.fn.getreg("/")
    local unnamed = vim.fn.getreginfo('"')
    local yank = vim.fn.getreginfo("0")
    local operator_start = vim.fn.getpos("'[")
    local operator_end = vim.fn.getpos("']")
    local visual_start = vim.fn.getpos("'<")
    local visual_end = vim.fn.getpos("'>")

    local ok, result = xpcall(callback, debug.traceback)

    leave_visual_mode()
    vim.fn.setreg("/", search)
    vim.fn.setreg("0", yank)
    vim.fn.setreg('"', unnamed)
    pcall(vim.fn.setpos, "'[", operator_start)
    pcall(vim.fn.setpos, "']", operator_end)
    pcall(vim.fn.setpos, "'<", visual_start)
    pcall(vim.fn.setpos, "'>", visual_end)
    vim.fn.winrestview(view)
    vim.api.nvim_win_set_cursor(ctx.win, cursor)

    if not ok then
      error(result, 0)
    end

    return result
  end)
end

---@param ctx TextobjectHudContext
---@param opts TextobjectHudConfig
---@param source TextobjectHudSource
---@return TextobjectHudCandidate[]
function M.collect(ctx, opts, source)
  return with_restored_window(ctx, function()
    local result = {}

    for _, key in ipairs(TEXTOBJECTS) do
      local range = probe_textobject(ctx, key)
      if range then
        result[#result + 1] = source_util.candidate(opts, source, {
          name = key,
          bufnr = ctx.bufnr,
          range = range,
          priority = 60,
        })
      end
    end

    return result
  end)
end

return M
