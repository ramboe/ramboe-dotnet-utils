# dap-scope-walker

# Intro

Walks and expands **nvim-dap-ui** *Scopes* automatically until a given variable name is found. It’s async, fast, and configurable (blocklist, case rules, visual highlight on hit).

## Prerequisites

* [`mfussenegger/nvim-dap`](https://github.com/mfussenegger/nvim-dap) configured
* [`rcarriga/nvim-dap-ui`](https://github.com/rcarriga/nvim-dap-ui) enabled (the walker operates in its *Scopes* window)
<!-- * Correctly set up `nvim-dap` for C# (TBD) -->

## Features

* Expands only when needed (async), walking line-by-line through the `scopes` window
* Stops on the **variable name** you specify (case/underscore-insensitive options)
* Optional **blocklist** to skip lines like “Static members”, collections, etc.
* Optional **Visual-Line highlight** of the found line and centering (`zz`)
* Works with custom `dap-ui` scope icons (collapsed/expanded)
* Starts from cursor or from top (configurable)
* Simple command: `:DapScopeWalk <TargetName>`

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'ramboe/dap-scope-walker',
  dependencies = { 'rcarriga/nvim-dap-ui', 'mfussenegger/nvim-dap' },
  config = function()
    require('dap_scope_walker').setup({
      -- sensible defaults; tweak as you like
      interval = 25,                       -- delay (ms) only after real expansions
      block = { 'Static members', ' _', '.Collections.', 'DateTime' },
      block_insensitive = true,            -- case-insensitive block matching
      insensitive = true,                  -- case-insensitive target matching
      start_at_top = true,                 -- begin at first line of Scopes
      center = true,                       -- center the hit line (zz)
      exact = true,                        -- exact name match (vs substring)
      visual_on_hit = true,                -- highlight the whole line on hit
    })
  end,
}
```

> Module name for `require(...)`: **`dap_scope_walker`** (underscores for Lua modules).

## Usage

* Open a debug session so **Scopes** is visible, then run:

```
:DapScopeWalk MyProperty
```
* The walker will expand through the tree until it finds a line whose **name** is `MyProperty`, select that line (Visual-Line), and center it.
* To change defaults, pass options in `setup()` (see Installation).
* Programmatic call:

```lua
require('dap_scope_walker').DapUI_WalkExpandUntilAsync('MyProperty')
```
