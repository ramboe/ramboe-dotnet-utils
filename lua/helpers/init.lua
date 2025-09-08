-- todo: put into ramboe utils
-- map(): tiny wrapper around vim.keymap.set that lets you pass a string as the description.
-- Usage:
--   map("n", "K", vim.lsp.buf.hover, "Hover")
--   map("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover" })
-- Notes: keymaps are non-recursive by default; use `remap = true` if you want recursion.
_G.map = function(mode, lhs, rhs, opts)
  if type(opts) == "string" then
    opts = { desc = opts }
  end
  return vim.keymap.set(mode, lhs, rhs, opts)
end

-- Highight the C# method
function HighlightCSharpMethod()
  -- Jump to the beginning of the line
  -- vim.api.nvim_input('^vf{%j%V')
  vim.api.nvim_input "0"
  -- Enter visual mode
  vim.api.nvim_input "v"
  -- Move to the next "{" character
  vim.api.nvim_input "/{<CR>"
  -- Move to the matching "}" character
  vim.api.nvim_input "%"
  vim.api.nvim_input "V"
end

vim.api.nvim_create_user_command("HighlightCSharpMethod", HighlightCSharpMethod, {})

-- close other buffers
function CloseOtherBuffers()
  local current_buf = vim.api.nvim_get_current_buf()
  local buffers = vim.api.nvim_list_bufs()

  for _, buf in ipairs(buffers) do
    if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

vim.api.nvim_create_user_command("CloseOtherBuffers", CloseOtherBuffers, {})
