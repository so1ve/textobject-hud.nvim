local action = require("textobject-hud.action")
local candidate = require("textobject-hud.candidate")
local config = require("textobject-hud.config")
local context = require("textobject-hud.context")
local display = require("textobject-hud.display")
local highlight = require("textobject-hud.highlight")
local query = require("textobject-hud.query")

local M = {}

local state = {
  hud_win = nil,
  hud_buf = nil,
  source_win = nil,
  source_buf = nil,
  candidates = {},
  opts = nil,
  augroup = nil,
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function hud_height()
  return math.min(math.max(#state.candidates, 1), state.opts.window.max_height)
end

local function source_position()
  if not valid_win(state.source_win) then
    return { row = state.opts.window.row_offset, col = state.opts.window.col_offset }
  end

  return vim.api.nvim_win_call(state.source_win, function()
    return {
      row = math.max(0, vim.fn.winline() + state.opts.window.row_offset - 1),
      col = math.max(0, vim.fn.wincol() + state.opts.window.col_offset - 1),
    }
  end)
end

local function float_config()
  local position = source_position()

  return {
    relative = "win",
    win = state.source_win,
    row = position.row,
    col = position.col,
    width = state.opts.window.width,
    height = hud_height(),
    border = state.opts.window.border,
    focusable = true,
    title = " Textobjects ",
    style = "minimal",
  }
end

local function cursor_row()
  if #state.candidates == 0 then
    return nil
  end

  return vim.api.nvim_win_get_cursor(state.hud_win)[1]
end

local function candidate_at_cursor()
  local row = cursor_row()
  return row and state.candidates[row] or nil
end

local function render()
  vim.bo[state.hud_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.hud_buf, 0, -1, false, display.render(state.candidates, state.opts.window.width))
  vim.bo[state.hud_buf].modifiable = false

  if #state.candidates > 0 then
    vim.api.nvim_win_set_cursor(state.hud_win, { 1, 0 })
  end

  M.sync_selection()
end

local function attach_autocmds()
  state.augroup = vim.api.nvim_create_augroup("TextobjectHud", { clear = true })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = state.augroup,
    pattern = tostring(state.hud_win),
    callback = M.close,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = state.augroup,
    buffer = state.hud_buf,
    callback = M.sync_selection,
  })

  if not state.opts.window.follow then
    return
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = state.augroup,
    buffer = state.source_buf,
    callback = M.reposition,
  })

  vim.api.nvim_create_autocmd("WinScrolled", {
    group = state.augroup,
    callback = function(args)
      if tonumber(args.match) == state.source_win then
        M.reposition()
      end
    end,
  })
end

---@param opts TextobjectHudConfig
---@param source_win integer
---@return TextobjectHudCandidate[]
function M.collect(opts, source_win)
  local ctx = context.get({ win = source_win })
  local collected = {}

  if opts.collect.ancestors then
    vim.list_extend(collected, query.collect_ancestors(ctx, opts))
  end

  if opts.collect.textobjects then
    vim.list_extend(collected, query.collect_textobjects(ctx, opts))
  end

  return candidate.prepare(collected, {
    bufnr = ctx.bufnr,
    cursor = ctx.cursor,
    require_contains_cursor = true,
    max_lines = opts.collect.max_lines,
  })
end

---@param opts TextobjectHudConfig
function M.open(opts)
  M.close()

  local source_win = vim.api.nvim_get_current_win()

  state.opts = opts
  state.source_win = source_win
  state.source_buf = vim.api.nvim_win_get_buf(source_win)
  state.candidates = M.collect(state.opts, source_win)
  state.hud_buf = vim.api.nvim_create_buf(false, true)
  state.hud_win = vim.api.nvim_open_win(state.hud_buf, true, float_config())

  vim.bo[state.hud_buf].bufhidden = "wipe"
  vim.bo[state.hud_buf].buftype = "nofile"
  vim.bo[state.hud_buf].modifiable = true
  vim.wo[state.hud_win].cursorline = true

  render()
  vim.keymap.set("n", "<CR>", M.select, { buffer = state.hud_buf, nowait = true, silent = true })
  vim.keymap.set("n", "q", M.close, { buffer = state.hud_buf, nowait = true, silent = true })
  vim.keymap.set("n", "<Esc>", M.close, { buffer = state.hud_buf, nowait = true, silent = true })
  attach_autocmds()
end

function M.reposition()
  if valid_win(state.hud_win) and valid_win(state.source_win) and state.opts then
    vim.api.nvim_win_set_config(state.hud_win, float_config())
  end
end

function M.sync_selection()
  local item = candidate_at_cursor()

  if item then
    highlight.show(item, state.opts)
  elseif state.source_buf then
    highlight.clear(state.source_buf)
  end
end

function M.close()
  if state.augroup then
    vim.api.nvim_del_augroup_by_id(state.augroup)
  end

  if state.source_buf then
    highlight.clear(state.source_buf)
  end

  if valid_win(state.hud_win) then
    vim.api.nvim_win_close(state.hud_win, true)
  end

  state.hud_win = nil
  state.hud_buf = nil
  state.source_win = nil
  state.source_buf = nil
  state.candidates = {}
  state.opts = nil
  state.augroup = nil
end

function M.select()
  local item = candidate_at_cursor()
  local source_win = state.source_win
  M.close()
  action.select(source_win, item)
end

function M.inspect()
  local candidates = M.collect(config.get(), vim.api.nvim_get_current_win())
  vim.print(candidates)
  return candidates
end

return M
