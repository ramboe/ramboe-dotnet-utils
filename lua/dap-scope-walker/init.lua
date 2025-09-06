local M = {}

-- Defaults (edit these)
M._cfg = {
  interval          = 500, -- conservative value here
  block             = { "Static members", " _", ".Collections.", "DateTime" },
  block_insensitive = true,
  insensitive       = true,
  center            = true,
  exact             = true,
  highlight         = true
}

-- Merge helper
local function _merge(user)
  if type(user) == "table" then
    M._cfg = vim.tbl_deep_extend("force", M._cfg, user)
  end
end

-- Public setup (call once from your config)

-- optional: let users override defaults once
function M.setup(opts)
  if type(opts) == "table" then
    M._cfg = vim.tbl_deep_extend("force", M._cfg, opts)
  end
end

-- Expand all collapsed nodes in the *focused* nvim-dap-ui Scopes buffer.
function M.DapUI_SendEnter()
  local cr = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  vim.api.nvim_feedkeys(cr, "m", false) -- "m" = apply mappings (needed for dap-ui)

  vim.notify("executed DapUI_SendEnter", vim.log.levels.INFO)
  vim.cmd("redraw")
  vim.notify("executed redraw", vim.log.levels.INFO)
end

-- Returns true iff we actually expanded the current line
function M.DapUI_EnterIfCollapsed(opts)
  opts = opts or {}
  local block = opts.block
  local insensitive = (opts.insensitive ~= false)

  local icons = require("dapui.config").icons or {}
  local icon = icons.collapsed or ""

  local line = vim.api.nvim_get_current_line() or ""

  -- block check
  local function contains(hay, needle)
    if insensitive then
      return hay:lower():find(needle:lower(), 1, true) ~= nil
    else
      return hay:find(needle, 1, true) ~= nil
    end
  end
  local function is_blocked(s)
    if not block then return false end
    if type(block) == "string" then return contains(s, block) end
    if type(block) == "table" then
      for _, b in ipairs(block) do
        if type(b) == "string" and contains(s, b) then return true end
        if type(b) == "function" and b(s) then return true end
      end
      return false
    end
    if type(block) == "function" then return block(s) end
    return false
  end
  if is_blocked(line) then return false end

  local _, e = line:find("^%s*" .. vim.pesc(icon) .. "%s+")
  if not e then return false end

  -- move to start of name and press <CR>
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_win_set_cursor(0, { row, e })
  M.DapUI_SendEnter()
  return true
end

-- ---------- helpers for the walker ----------
local function var_name_from_line(line)
  local icons = require("dapui.config").icons or {}
  -- strip leading whitespace and any leading icon
  local s, e
  for _, ic in ipairs({ icons.collapsed, icons.expanded }) do
    if ic then
      s, e = line:find("^%s*" .. vim.pesc(ic) .. "%s+")
      if e then break end
    end
  end
  if not e then _, e = line:find("^%s*") end
  local lhs = (line:sub((e or 0) + 1)):match("^(.-)=") or line:sub((e or 0) + 1)
  lhs = lhs:gsub("%s+$", "")
  local name = lhs:match("^([%w_%.%[%]]+)") or lhs:match("^(%S+)") or ""
  return name
end

local function norm(s) return (s or ""):lower():gsub("_", "") end

-- ---------- the walker ----------
function M.DapUI_WalkExpandUntilAsync(target, opts)
  opts                    = opts or {}
  local interval          = opts.interval or 25 -- short; we only wait on expand
  local insensitive       = (opts.insensitive ~= false)
  local block             = opts.block
  local block_insensitive = (opts.block_insensitive ~= nil) and opts.block_insensitive or insensitive
  local center_on_hit     = (opts.center ~= false)
  local exact             = (opts.exact ~= false) -- default: exact name match
  local visual_on_hit     = (opts.highlight ~= false)

  if type(target) ~= "string" or target == "" then
    vim.notify("Target must be a non-empty string", vim.log.levels.ERROR)
    return
  end

  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local ft  = vim.bo[buf].filetype
  if ft ~= "dapui_scopes" and ft ~= "dap-float" then
    vim.notify("Focus the nvim-dap-ui Scopes window first", vim.log.levels.WARN)
    return
  end

  local lnum        = vim.api.nvim_win_get_cursor(win)[1]
  local needle_raw  = insensitive and target:lower() or target
  local needle_norm = norm(target)

  local function step()
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then return end
    local last = vim.api.nvim_buf_line_count(buf)
    if lnum > last then
      vim.notify("Target not found below cursor: " .. target, vim.log.levels.INFO)
      return
    end

    vim.api.nvim_win_set_cursor(win, { lnum, 0 })
    local line = (vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1] or "")
    local name = var_name_from_line(line)

    -- stop when the variable NAME matches the target
    local found
    if exact then
      found = (insensitive and name:lower() == needle_raw) or (not insensitive and name == target)
      -- also try underscore-insensitive exact
      if not found then found = (norm(name) == needle_norm) end
    else
      local hay = insensitive and name:lower() or name
      found = hay:find(needle_raw, 1, true) ~= nil or norm(name):find(needle_norm, 1, true) ~= nil
    end

    if found then
      -- make sure we’re on the line
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, { lnum, 0 })

      if visual_on_hit then
        -- Visual-Line select the whole line
        vim.cmd("normal! V")
      end

      if center_on_hit then
        vim.cmd("normal! zz")
      end
      return
    end

    -- try to expand this row; only wait if expansion happened
    local did_expand = false
    if type(M.DapUI_EnterIfCollapsed) == "function" then
      did_expand = M.DapUI_EnterIfCollapsed({
        block = block,
        insensitive = block_insensitive,
      }) or false
    end

    lnum = lnum + 1
    if did_expand then
      vim.defer_fn(step, interval) -- give UI time to insert children
    else
      vim.schedule(step)           -- immediate next tick
    end
  end

  step()
end

-- command: just pass current cfg
vim.api.nvim_create_user_command("DapScopeWalk", function(opts)
  M.DapUI_WalkExpandUntilAsync(opts.args, vim.deepcopy(M._cfg)) -- deepcopy is just defensive
end, { nargs = 1 })

-- (optional) sugar so you can do: require("..."){ ... }
setmetatable(M, {
  __call = function(_, opts)
    M.setup(opts); return M
  end
})

--- I think we don't need this
function M.DapUI_ResetPanels(delay_ms)
  delay_ms = delay_ms or 40
  local dapui = require("dapui")
  dapui.close()
  vim.defer_fn(function()
    dapui.open()
  end, delay_ms)
end

return M
