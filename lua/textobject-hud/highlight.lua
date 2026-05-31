local M = {}

local namespace = vim.api.nvim_create_namespace("textobject-hud")

function M.setup()
  vim.api.nvim_set_hl(0, "TextobjectHudRange", { link = "Visual", default = true })
  vim.api.nvim_set_hl(0, "TextobjectHudCurrent", { link = "PmenuSel", default = true })
  vim.api.nvim_set_hl(0, "TextobjectHudSource", { link = "Comment", default = true })
end

---@param bufnr integer
function M.clear(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end
end

---@param candidate TextobjectHudCandidate?
---@param opts TextobjectHudConfig
function M.show(candidate, opts)
  if not candidate or not candidate.bufnr or not opts.preview.enabled then
    return
  end

  M.clear(candidate.bufnr)

  local range = candidate.range

  vim.api.nvim_buf_set_extmark(candidate.bufnr, namespace, range.start_row, range.start_col, {
    end_row = range.end_row,
    end_col = range.end_col,
    hl_group = opts.preview.hl_group,
  })
end

return M
