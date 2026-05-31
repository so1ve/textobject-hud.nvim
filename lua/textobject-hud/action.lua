local M = {}

local function visual_end(bufnr, range)
  if range.end_col > 0 then
    return range.end_row, range.end_col - 1
  end

  if range.end_row > range.start_row then
    local row = range.end_row - 1
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    return row, math.max(#line - 1, 0)
  end

  return range.end_row, range.end_col
end

---@param source_win integer
---@param candidate TextobjectHudCandidate?
function M.select(source_win, candidate)
  if not candidate then
    return
  end

  vim.api.nvim_win_call(source_win, function()
    local range = candidate.range
    local end_row, end_col = visual_end(candidate.bufnr, range)

    vim.api.nvim_win_set_cursor(source_win, { range.start_row + 1, range.start_col })
    vim.cmd("normal! v")
    vim.api.nvim_win_set_cursor(source_win, { end_row + 1, end_col })
  end)
end

return M
