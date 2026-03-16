local M = {}

local itemswindow = require("fzf-lua-pickers-razor-outline.collect_outline")
local helpers = require("fzf-lua-pickers-razor-outline.helpers")

-- lines above and below the highlighted line
-- local PREVIEW_CONTEXT = 7

local config = {
  preview_context = 7,
  preview_window = "up:65%",
  prompt = "RazorOutline> ",
}

-- Merge user options into the default plugin config
function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

-- Show an error notification inside Neovim
local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

-- Build the shell command used by fzf to preview surrounding lines with bat
local function build_preview_cmd(file_path)
  -- determine bat window content rendering
  local script = string.format([[
    line="${1%%:*}"
    ctx=%d
    start=$(( line > ctx ? line - ctx : 1 ))
    stop=$(( line + ctx ))

    BAT_PAGER="" bat \
      --paging=never \
      --style=numbers \
      --color=always \
      --highlight-line "$line" \
      --line-range "${start}:${stop}" \
      "$2"
  ]], config.preview_context)

  return table.concat({
    "bash -c",
    vim.fn.shellescape(script),
    "-- {} " .. vim.fn.shellescape(file_path),
  }, " ")
end

-- Move the cursor to the location represented by the selected outline entry
local function jump_to_entry(bufnr, entry)
  local line, col = helpers.parse_position(entry)
  if not line or not col then
    return
  end

  local target_win = 0
  if bufnr ~= vim.api.nvim_get_current_buf() then
    target_win = vim.fn.bufwinid(bufnr)
    if target_win == -1 then
      notify_error("Source buffer is not visible in any window")
      return
    end
  end

  vim.api.nvim_win_set_cursor(target_win, { line, col - 1 })
end

-- Return the file path of the buffer or nil if the buffer is unnamed
local function get_current_file(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if not file or file == "" then
    return nil
  end
  return file
end

-- Main entry point that builds the Razor outline and launches fzf-lua picker
function M.pick()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = get_current_file(bufnr)

  if not file_path then
    notify_error("Current buffer has no file name")
    return
  end

  local outline_items = itemswindow.collect_outline_items(bufnr)
  local preview_cmd = build_preview_cmd(file_path)

  require("fzf-lua").fzf_exec(outline_items, {
    prompt = config.prompt,
    fzf_opts = {
      ["--preview-window"] = config.preview_window,
      ["--preview"] = preview_cmd,
    },
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          jump_to_entry(bufnr, selected[1])
        end
      end,
    },
  })
end

return M
