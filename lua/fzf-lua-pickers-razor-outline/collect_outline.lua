local M = {}

local helpers = require("fzf-lua-pickers-razor-outline.helpers")

-- Tree-sitter query used to capture important Razor constructs
local CAPTURE_QUERY = [[
  (razor_inherits_directive name: (identifier) @inherits)
  (razor_page_directive) @page
  (razor_if) @if
  (razor_foreach) @foreach
  (element) @tag
]]

-- Read a single line from a buffer by row index
local function get_line(bufnr, row)
  return (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or "")
end

-- Remove leading whitespace from a string
local function trim_left(s)
  return s:gsub("^%s+", "")
end


-- Collect outline items from the Razor buffer using Tree-sitter captures
function M.collect_outline_items(bufnr)
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
      local line_a, col_a = helpers.parse_position(a)
      local line_b, col_b = helpers.parse_position(b)

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

return M
