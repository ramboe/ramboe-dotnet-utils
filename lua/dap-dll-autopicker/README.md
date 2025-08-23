# dap-dll-autopicker

Helper utilities for debugging .NET projects with [nvim-dap](https://github.com/mfussenegger/nvim-dap).  
It automatically locates the correct DLL to launch based on the current buffer’s `.csproj`.

## Features
- Finds the project root by searching upward for a `.csproj`.
- Detects the highest available `netX.Y` target folder (`bin/Debug/net8.0/`, etc).
- Builds the full path to the DLL for use with `nvim-dap`.
<!-- - Provides a `:DotnetDllPath` command to quickly echo the detected DLL. -->

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
  {
    'ramboe/ramboe-dotnet-utils',
    dependencies = { 'mfussenegger/nvim-dap' }
  },
```

Then assign the `build_dll_path` function to the `program` field inside your csharp dap configuration like so:

```
dap.configurations.cs = {
  {
    --- ...
    
    program = function()
      return require("dap-dll-autopicker").build_dll_path()
    end

  },
}
```
