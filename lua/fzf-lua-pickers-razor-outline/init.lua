local M = {}

local itemswindow = require("fzf-lua-pickers-razor-outline.collect_outline")


-- lines above and below the highlighted line
local PREVIEW_CONTEXT = 7

-- Show an error notification inside Neovim
local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

-- Extract line and column numbers from an outline entry string
local function parse_position(entry)
  local line, col = entry:match("^(%d+):(%d+)")
  return tonumber(line), tonumber(col)
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
  ]], PREVIEW_CONTEXT)

  return table.concat({
    "bash -c",
    vim.fn.shellescape(script),
    "-- {} " .. vim.fn.shellescape(file_path),
  }, " ")
end

-- Move the cursor to the location represented by the selected outline entry
local function jump_to_entry(bufnr, entry)
  local line, col = parse_position(entry)
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

-- Main entry point that builds the Razor outline and launches fzf-lua picker
function M.pick()
  -- Return the file path of the buffer or nil if the buffer is unnamed
  local function get_current_file(bufnr)
    local file = vim.api.nvim_buf_get_name(bufnr)
    if not file or file == "" then
      return nil
    end
    return file
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = get_current_file(bufnr)

  if not file_path then
    notify_error("Current buffer has no file name")
    return
  end

  local outline_items = itemswindow.collect_outline_items(bufnr)
  local preview_cmd = build_preview_cmd(file_path)

  require("fzf-lua").fzf_exec(outline_items, {
    prompt = "RazorOutline> ",
    fzf_opts = {
      ["--preview-window"] = "up:65%",
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
