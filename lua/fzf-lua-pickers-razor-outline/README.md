# fzf-lua-pickers-razor-outline

A small Neovim utility that creates a **navigable outline for Razor (`.razor`) files** using **Tree-sitter** and **fzf-lua**.

The picker extracts common Razor constructs (components, directives, and control blocks) and displays them in an interactive list. Selecting an entry jumps the cursor directly to the corresponding location in the file while showing a contextual preview using **bat**.

# Features

* Uses **Tree-sitter** to parse Razor files
* Interactive picker powered by **fzf-lua**
* Syntax-highlighted preview via **bat** (TBD)
* Fast navigation to:

  * `@inherits`
  * `@page`
  * `@if`
  * `@foreach`
  * Razor component tags (e.g. `<MyComponent>`)
* Configurable preview window and context
* Designed for large Razor files where navigation becomes cumbersome

# Requirements

* [fzf-lua](https://github.com/ibhagwan/fzf-lua)
* Tree-sitter Razor parser
* `bat` (for preview rendering)

# Installation

Example using **lazy.nvim**:

```lua
{
  "ramboe/ramboe-dotnet-utils",
  dependencies = {
    "ibhagwan/fzf-lua",
  },
  opts = {
    fzflua_razor_outline_preview_context = 7,
    fzflua_razor_outline_preview_window = "up:65%",
    fzflua_razor_outline_prompt = "RazorOutline> ",
  },
  config = function(_, opts)
    require("fzf-lua-pickers-razor-outline").setup(opts)
  end,
}
```

# Usage

Call the picker directly:

```lua
require("fzf-lua-pickers-razor-outline").pick()
```

# Keymap Example

A common pattern is to reuse a **single mapping for symbols** while switching behavior when editing Razor files.

Example:

```lua
map("n", "<leader>fs", function()
  if vim.bo.filetype == "razor" then
    require("fzf-lua-pickers-razor-outline").pick()
  else
    fzf.lsp_document_symbols()
  end
end, "Symbols / Razor Outline")
```

Behavior:

| Filetype      | Action               |
| ------------- | -------------------- |
| `razor`       | Razor outline picker |
| anything else | LSP document symbols |

This allows `<leader>fs` to function as a **general symbol navigation key** across all languages while providing a specialized Razor picker when editing `.razor` files.

# Configuration

| Option                                 | Default            | Description                                                |
| -------------------------------------- | ------------------ | ---------------------------------------------------------- |
| `fzflua_razor_outline_preview_context` | `7`                | Number of lines shown above and below the highlighted line |
| `fzflua_razor_outline_preview_window`  | `"up:65%"`         | Position and size of the preview window                    |
| `fzflua_razor_outline_prompt`          | `"RazorOutline> "` | Prompt shown in the picker                                 |

Example:

```lua
opts = {
  fzflua_razor_outline_preview_context = 3,
  fzflua_razor_outline_preview_window = "up:40%",
  fzflua_razor_outline_prompt = "razor> ",
}
```
# License

MIT
