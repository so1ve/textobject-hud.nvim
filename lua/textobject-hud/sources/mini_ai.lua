local source_util = require("textobject-hud.sources.util")

local M = {}

---@param region table
---@return TextobjectHudRange
local function region_range(region)
  local to = region.to

  return {
    start_row = region.from.line - 1,
    start_col = region.from.col - 1,
    end_row = (to or region.from).line - 1,
    end_col = to and to.col or region.from.col - 1,
  }
end

local BUILTIN_IDS = {
  "'",
  '"',
  "`",
  "(",
  "[",
  "{",
  "<",
  "a",
  "b",
  "f",
  "q",
  "t",
}

local AI_TYPES = { "a", "i" }

---@param id unknown
---@return boolean
local function is_single_char(id)
  return type(id) == "string" and vim.fn.strchars(id) == 1
end

---@param mini_ai table
---@param bufnr integer
---@return table<string, unknown>
local function custom_textobjects(mini_ai, bufnr)
  local result = {}
  local global_custom = type(mini_ai.config) == "table" and mini_ai.config.custom_textobjects or nil
  local buffer_config = vim.b[bufnr].miniai_config
  local buffer_custom = type(buffer_config) == "table" and buffer_config.custom_textobjects or nil

  if type(global_custom) == "table" then
    for id, spec in pairs(global_custom) do
      result[id] = spec
    end
  end

  if type(buffer_custom) == "table" then
    for id, spec in pairs(buffer_custom) do
      result[id] = spec
    end
  end

  return result
end

---@param mini_ai table
---@param bufnr integer
---@return string[]
local function available_ids(mini_ai, bufnr)
  local custom = custom_textobjects(mini_ai, bufnr)
  local by_id = {}

  for _, id in ipairs(BUILTIN_IDS) do
    if custom[id] ~= false then
      by_id[id] = true
    end
  end

  for id, spec in pairs(custom) do
    if spec ~= false and is_single_char(id) then
      by_id[id] = true
    end
  end

  local result = vim.tbl_keys(by_id)
  table.sort(result)

  return result
end

---@param mini_ai table
---@param bufnr integer
---@param callback fun(): TextobjectHudCandidate[]
---@return TextobjectHudCandidate[]
local function with_silent(mini_ai, bufnr, callback)
  local config = mini_ai.config
  local old_global_silent
  local buffer_config = vim.b[bufnr].miniai_config
  local has_buffer_silent = type(buffer_config) == "table" and buffer_config.silent ~= nil
  local old_buffer_silent

  if type(config) == "table" then
    old_global_silent = config.silent
  end

  if has_buffer_silent then
    old_buffer_silent = buffer_config.silent
  end

  if type(config) == "table" then
    config.silent = true
  end

  if type(buffer_config) == "table" then
    buffer_config.silent = true
  end

  local ok, result = xpcall(callback, debug.traceback)

  if type(config) == "table" then
    config.silent = old_global_silent
  end

  if type(buffer_config) == "table" then
    if has_buffer_silent then
      buffer_config.silent = old_buffer_silent
    else
      buffer_config.silent = nil
    end
  end

  if not ok then
    error(result, 0)
  end

  return result
end

---@param mini_ai table
---@param ctx TextobjectHudContext
---@param ai_type string
---@param id string
---@return table?
local function find_region(mini_ai, ctx, ai_type, id)
  local ok, region = pcall(vim.api.nvim_win_call, ctx.win, function()
    return mini_ai.find_textobject(ai_type, id, {
      n_times = 1,
      reference_region = {
        from = {
          line = ctx.cursor.row + 1,
          col = ctx.cursor.col + 1,
        },
      },
      search_method = "cover",
    })
  end)

  if ok then
    return region
  end

  return nil
end

---@param ctx TextobjectHudContext
---@param opts TextobjectHudConfig
---@param source TextobjectHudSource
---@return TextobjectHudCandidate[]
function M.collect(ctx, opts, source)
  local ok, mini_ai = pcall(require, "mini.ai")
  if not ok or type(mini_ai.find_textobject) ~= "function" then
    return {}
  end

  return with_silent(mini_ai, ctx.bufnr, function()
    local result = {}

    for _, id in ipairs(available_ids(mini_ai, ctx.bufnr)) do
      for _, ai_type in ipairs(AI_TYPES) do
        local region = find_region(mini_ai, ctx, ai_type, id)

        if region then
          local name = ai_type .. id
          result[#result + 1] = source_util.candidate(opts, source, {
            name = name,
            bufnr = ctx.bufnr,
            range = region_range(region),
            priority = 70,
          })
        end
      end
    end

    return result
  end)
end

return M
