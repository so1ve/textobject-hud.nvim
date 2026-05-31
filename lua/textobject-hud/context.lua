local M = {}

---@class TextobjectHudContext
---@field bufnr integer
---@field win integer
---@field cursor { row: integer, col: integer }
---@field filename string
---@field filetype string
---@field lang? string
---@field parser? vim.treesitter.LanguageTree
---@field tree? TSTree
---@field root? TSNode
---@field node? TSNode

---@param opts { bufnr?: integer, win: integer }
---@return TextobjectHudContext
function M.get(opts)
  local win = opts.win
  local bufnr = opts.bufnr or vim.api.nvim_win_get_buf(win)
  local cursor_pos = vim.api.nvim_win_get_cursor(win)
  local cursor = { row = cursor_pos[1] - 1, col = cursor_pos[2] }
  local filetype = vim.bo[bufnr].filetype
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local lang = vim.treesitter.language.get_lang(filetype) or filetype

  local ctx = {
    bufnr = bufnr,
    win = win,
    cursor = cursor,
    filename = filename,
    filetype = filetype,
    lang = lang,
  }

  local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not parser_ok or not parser then
    return ctx
  end

  local trees = parser:parse()
  local tree = trees and trees[1]
  if not tree then
    return ctx
  end

  ctx.parser = parser
  ctx.tree = tree
  ctx.root = tree:root()

  ctx.node = vim.treesitter.get_node({ bufnr = bufnr, pos = { cursor.row, cursor.col } })

  return ctx
end

return M
