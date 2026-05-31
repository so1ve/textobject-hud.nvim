local action = require("textobject-hud.action")
local candidate = require("textobject-hud.candidate")
local config = require("textobject-hud.config")
local context = require("textobject-hud.context")
local display = require("textobject-hud.display")
local highlight = require("textobject-hud.highlight")

local M = {}

local namespace = vim.api.nvim_create_namespace("textobject-hud")

local state = {
  hud_win = nil,
  hud_buf = nil,
  source_win = nil,
  source_buf = nil,
  candidates = {},
  layout = nil,
  opts = nil,
  augroup = nil,
}

local function valid_win(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function hud_height()
  return math.min(math.max(#state.candidates, 1), state.opts.window.max_height)
end

local function clamp(value, min, max)
  if max < min then
    return min
  end

  return math.min(math.max(value, min), max)
end

local function candidate_at_cursor()
  if #state.candidates == 0 or not valid_win(state.hud_win) then
    return nil
  end

  return state.candidates[vim.api.nvim_win_get_cursor(state.hud_win)[1]]
end

local function source_position()
  if not valid_win(state.source_win) or not state.layout then
    return { row = state.opts.window.row_offset, col = state.opts.window.col_offset }
  end

  return vim.api.nvim_win_call(state.source_win, function()
    local win_width = vim.api.nvim_win_get_width(state.source_win)
    local win_height = vim.api.nvim_win_get_height(state.source_win)
    local height = hud_height()
    local max_row = math.max(0, win_height - height)
    local max_col = math.max(0, win_width - state.layout.width)
    local row_gap = math.max(0, state.opts.window.row_offset)
    local col_gap = math.max(0, state.opts.window.col_offset)
    local cursor = vim.api.nvim_win_get_cursor(state.source_win)
    local cursor_row = cursor[1] - 1
    local cursor_col = cursor[2]
    local cursor_screen_row = math.max(0, vim.fn.winline() - 1)
    local cursor_screen_col = math.max(0, vim.fn.wincol() - 1)
    local cursor_line = vim.api.nvim_buf_get_lines(state.source_buf, cursor_row, cursor_row + 1, false)[1] or ""
    local line_origin_col = cursor_screen_col
      - vim.fn.strdisplaywidth(cursor_line:sub(1, clamp(cursor_col, 0, #cursor_line)))
    local right_row = clamp(cursor_screen_row, 0, max_row)
    local anchor = {
      top = cursor_screen_row,
      bottom = cursor_screen_row,
      right = cursor_screen_col,
    }
    local item = candidate_at_cursor() or state.candidates[1]

    if item and item.range then
      local top_line = vim.fn.line("w0") - 1
      local bottom_line = vim.fn.line("w$") - 1
      local start_row = item.range.start_row
      local end_row = item.range.end_row
      local right_col = cursor_screen_col

      if item.range.end_col == 0 and end_row > start_row then
        end_row = end_row - 1
      end

      if end_row >= top_line and start_row <= bottom_line then
        local first_row = math.max(start_row, top_line + right_row)
        local last_row = math.min(end_row, top_line + right_row + height - 1, bottom_line)

        for row = first_row, last_row do
          local line = vim.api.nvim_buf_get_lines(state.source_buf, row, row + 1, false)[1] or ""
          local end_col = row == item.range.end_row and item.range.end_col or #line
          local prefix = line:sub(1, clamp(end_col, 0, #line))

          right_col = math.max(right_col, line_origin_col + vim.fn.strdisplaywidth(prefix))
        end

        anchor = {
          top = clamp(start_row - top_line, 0, win_height - 1),
          bottom = clamp(end_row - top_line, 0, win_height - 1),
          right = clamp(right_col, 0, win_width - 1),
        }
      end
    end

    local vertical_col = clamp(cursor_screen_col + col_gap, 0, max_col)
    local right_col = anchor.right + col_gap
    local below_row = anchor.bottom + row_gap
    local above_row = anchor.top - height - row_gap
    local choices = {
      { row = right_row, col = right_col, fits = right_col <= max_col },
      { row = below_row, col = vertical_col, fits = below_row <= max_row },
      { row = above_row, col = vertical_col, fits = above_row >= 0 },
    }

    for _, choice in ipairs(choices) do
      if choice.fits then
        return { row = choice.row, col = choice.col }
      end
    end

    return {
      row = clamp(anchor.top, 0, max_row),
      col = vertical_col,
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
    width = state.layout.width,
    height = hud_height(),
    border = state.opts.window.border,
    focusable = true,
    title = " Textobjects ",
    style = "minimal",
  }
end

---@param source TextobjectHudSource|fun(ctx: TextobjectHudContext, opts: TextobjectHudConfig): TextobjectHudCandidate[]
---@param ctx TextobjectHudContext
---@param opts TextobjectHudConfig
---@return TextobjectHudCandidate[]
local function collect_source(source, ctx, opts)
  if type(source) == "function" then
    return source(ctx, opts)
  end

  local result = source.collect(ctx, opts, source)
  for _, item in ipairs(result) do
    item.source = item.source or source.name
    item.key_prefix = item.key_prefix or source.key_prefix
  end

  return result
end

local function render()
  local lines, highlights = display.render(state.candidates, state.layout)

  vim.bo[state.hud_buf].modifiable = true
  vim.api.nvim_buf_clear_namespace(state.hud_buf, namespace, 0, -1)
  vim.api.nvim_buf_set_lines(state.hud_buf, 0, -1, false, lines)
  vim.bo[state.hud_buf].modifiable = false

  for _, item in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(state.hud_buf, namespace, item.row, item.start_col, {
      end_col = item.end_col,
      hl_group = item.hl_group,
    })
  end

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

  for _, source in ipairs(opts.sources) do
    vim.list_extend(collected, collect_source(source, ctx, opts))
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
  local candidates = M.collect(opts, source_win)

  if #candidates == 0 then
    vim.notify("No textobjects at cursor", vim.log.levels.WARN)
    return
  end

  state.opts = opts
  state.source_win = source_win
  state.source_buf = vim.api.nvim_win_get_buf(source_win)
  state.candidates = candidates
  state.layout = display.layout(candidates)
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
  if valid_win(state.hud_win) and valid_win(state.source_win) and state.opts and state.layout then
    vim.api.nvim_win_set_config(state.hud_win, float_config())
  end
end

function M.sync_selection()
  local item = candidate_at_cursor()

  if item then
    highlight.show(item, state.opts)
    M.reposition()
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
  state.layout = nil
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
