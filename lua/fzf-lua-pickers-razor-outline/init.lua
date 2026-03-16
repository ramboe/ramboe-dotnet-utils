local M = {}

-- Tree-sitter query used to capture important Razor constructs
local CAPTURE_QUERY = [[
  (razor_inherits_directive name: (identifier) @inherits)
  (razor_page_directive) @page
  (razor_if) @if
  (razor_foreach) @foreach
  (element) @tag
]]

-- lines above and below the highlighted line
local PREVIEW_CONTEXT = 7

-- Show an error notification inside Neovim
local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

-- Read a single line from a buffer by row index
local function get_line(bufnr, row)
  return (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or "")
end

-- Remove leading whitespace from a string
local function trim_left(s)
  return s:gsub("^%s+", "")
end

-- Extract line and column numbers from an outline entry string
local function parse_position(entry)
  local line, col = entry:match("^(%d+):(%d+)")
  return tonumber(line), tonumber(col)
end

-- Collect outline items from the Razor buffer using Tree-sitter captures
local function collect_outline_items(bufnr)
  -- Extract a component tag from a line while ignoring closing or lowercase HTML tags
  local function extract_component_tag(line)
    -- Determine if a tag name represents a Razor component (starts with uppercase)
    local function is_component_tag(tag)
      return tag and tag:match("^[A-Z]") ~= nil
    end

    local trimmed = trim_left(line)

    if trimmed:match("^</") then
      return nil
    end

    local tag = trimmed:match("^<([%w%._%-:]+)")
    if not is_component_tag(tag) then
      return nil
    end

    return "<" .. tag .. ">"
  end

  -- Convert a Tree-sitter capture into the human-readable outline text
  local function format_capture_text(kind, node, bufnr, row)
    if kind == "tag" then
      return extract_component_tag(get_line(bufnr, row))
    end

    if kind == "inherits" then
      local name = vim.treesitter.get_node_text(node, bufnr)
      return "@inherits " .. name
    end

    return trim_left(get_line(bufnr, row))
  end

  -- Sort outline entries by line and column position
  local function sort_entries(items)
    table.sort(items, function(a, b)
      local line_a, col_a = parse_position(a)
      local line_b, col_b = parse_position(b)

      if line_a == line_b then
        return col_a < col_b
      end

      return line_a < line_b
    end)
  end

  -- Format a final entry string that fzf will display
  local function make_entry(kind, row, col, text)
    return string.format("%d:%d [%s] %s", row + 1, col + 1, kind, text)
  end

  local parser = vim.treesitter.get_parser(bufnr, "razor")
  local root = parser:parse()[1]:root()
  local query = vim.treesitter.query.parse("razor", CAPTURE_QUERY)

  local items = {}
  local seen = {}

  for capture_id, node in query:iter_captures(root, bufnr, 0, -1) do
    local kind = query.captures[capture_id]
    local row, col = node:start()
    local text = format_capture_text(kind, node, bufnr, row)

    if text then
      local entry = make_entry(kind, row, col, text)

      if not seen[entry] then
        seen[entry] = true
        table.insert(items, entry)
      end
    end
  end

  sort_entries(items)
  return items
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

  local outline_items = collect_outline_items(bufnr)
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
