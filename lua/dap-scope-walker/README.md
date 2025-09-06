# dap-scope-walker

# Intro

Walks and expands **nvim-dap-ui** *Scopes* automatically until a given variable name is found. 

![](https://firebasestorage.googleapis.com/v0/b/firescript-577a2.appspot.com/o/imgs%2Fapp%2Framboe%2FogO6Qgr0Kj.gif?alt=media&token=89c01370-1392-4331-a73f-3884b425d8c8)

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

You already installed the ramboe-dotnet-utils with lazy, now just call the `setup()` function, preferably in your `init.lua`

```lua
-- init.lua

require("dap-scope-walker").setup({
  interval          = 250,
  -- ...
});
```

## Configuration

```
{
  interval          = 500, -- conservative value here
  block             = { "Static members", " _", ".Collections.", "DateTime" }, 
  block_insensitive = true,
  insensitive       = true,
  center            = true,
  exact             = true,
  highlight         = true
}
```

Explanation

* `interval` — delay (ms) **after an expansion** so children can render.
* `block` — substrings; if a line contains any, **don’t expand** it.
* `block_insensitive` — case-insensitive matching for `block`.
* `insensitive` — case-insensitive match for the **target name**.
* `center` — center the found line (`zz`) when target is hit.
* `exact` — exact name match (else: substring match).
* `highlight` — select the hit line (Visual-Line) for quick copy/scan.

## Usage

* Open a debug session so [scopes](https://github.com/rcarriga/nvim-dap-ui?tab=readme-ov-file#variable-scopes) is visible, bring the cursor into the scopes window, then run:

```
:DapScopeWalk MyProperty
```

* The walker will expand through the tree until it finds a line whose **name** is `MyProperty`, select that line (Visual-Line), and center it.
* To change defaults, pass options in `setup()` (see Installation).
<!-- * Programmatic call: -->
<!---->
<!-- ```lua -->
<!-- require('dap-scope-walker').DapUI_WalkExpandUntilAsync('MyProperty') -->
<!-- ``` -->
