# dap-dll-autopicker

Helper utilities for debugging .NET projects with [nvim-dap](https://github.com/mfussenegger/nvim-dap).  
It automatically locates the correct DLL to launch based on the current buffer’s `.csproj`.

## Prerequisites

- correctly set up nvim.dap for csharp (TBD)

## Features
- Finds the project root by searching upward for a `.csproj`.
- Detects the highest available `netX.Y` target folder (`bin/Debug/net8.0/`, etc).
- Builds the full path to the DLL for use with `nvim-dap`.
<!-- - Provides a `:DotnetDllPath` command to quickly echo the detected DLL. -->

## Installation

You already installed the ramboe-dotnet-utils with lazy, now assign the `build_dll_path` function to the `program` field inside your csharp dap configuration like so:

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

## Usage

In your dotnet project, set a break point and start the debugger with `require'dap'.continue()` - It will then pick the DLL related to the class you want to debug and output it at the bottom command line:   

![](https://firebasestorage.googleapis.com/v0/b/firescript-577a2.appspot.com/o/imgs%2Fapp%2Framboe%2F0Q-wLAyQg_.png?alt=media&token=f6a8c2fe-4a3b-42c7-bed5-bf36bf829e2f)  

Debugging should then work just fine  

![](https://firebasestorage.googleapis.com/v0/b/firescript-577a2.appspot.com/o/imgs%2Fapp%2Framboe%2Fq-tLHnOjZv.png?alt=media&token=b8efe086-ed8c-4e62-a705-ab36a1161a44)  
