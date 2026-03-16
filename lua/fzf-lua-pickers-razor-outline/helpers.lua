local M = {}

-- Extract line and column numbers from an outline entry string
function M.parse_position(entry)
  local line, col = entry:match("^(%d+):(%d+)")
  return tonumber(line), tonumber(col)
end

return M
