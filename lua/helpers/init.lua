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
