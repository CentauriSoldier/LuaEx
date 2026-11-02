# Run LXC checks in fresh native Lua states. No wxLua or desktop automation is used.
param(
    [string]$LuaDll,
    [switch]$Integration,
    [switch]$Benchmark,
    [switch]$Walkthrough,
    [switch]$Framework
)
$ErrorActionPreference = 'Stop'
if (-not $LuaDll) {
    $taskCandidates = @(
        (Join-Path $PSScriptRoot '../../wxLuma-main/Win/Bin/lua54.dll'),
        (Join-Path $env:USERPROFILE 'Sync/Projects/GitHub/wxLuma/Win/Bin/lua54.dll'),
        (Join-Path $env:USERPROFILE 'Sync/Projects/wxLuma/Win/Bin/lua54.dll')
    )
    $LuaDll = $taskCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $LuaDll) { throw 'Supply -LuaDll with a compatible Lua 5.4 DLL path.' }
}
$taskDll = (Resolve-Path -LiteralPath $LuaDll).Path
$taskTestName = if ($Benchmark) { 'benchmark.lua' } elseif ($Integration) { 'integration.lua' } elseif ($Walkthrough) { 'walkthrough.lua' } elseif ($Framework) { 'framework.lua' } else { 'test.lua' }
$taskTest = (Join-Path $PSScriptRoot $taskTestName).Replace('\', '/')
if ($taskTest.Contains(']==]')) { throw 'Unsupported long-string delimiter in test path.' }

if (-not ('LxcPrototypeHost' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class LxcPrototypeHost {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
    static extern IntPtr LoadLibrary(string path);
    [DllImport("lua54.dll", CallingConvention=CallingConvention.Cdecl)]
    static extern IntPtr luaL_newstate();
    [DllImport("lua54.dll", CallingConvention=CallingConvention.Cdecl)]
    static extern void luaL_openlibs(IntPtr state);
    [DllImport("lua54.dll", CallingConvention=CallingConvention.Cdecl)]
    static extern int luaL_loadstring(IntPtr state, [MarshalAs(UnmanagedType.LPUTF8Str)] string code);
    [DllImport("lua54.dll", CallingConvention=CallingConvention.Cdecl)]
    static extern int lua_pcallk(IntPtr state, int args, int results, int err, IntPtr ctx, IntPtr cont);
    [DllImport("lua54.dll", CallingConvention=CallingConvention.Cdecl)]
    static extern IntPtr lua_tolstring(IntPtr state, int index, out UIntPtr length);
    [DllImport("lua54.dll", CallingConvention=CallingConvention.Cdecl)]
    static extern void lua_close(IntPtr state);

    // Create and close a fresh state; the test cannot inherit framework globals.
    public static void Run(string dll, string code) {
        if (LoadLibrary(dll) == IntPtr.Zero) throw new Exception("Cannot load Lua 5.4 DLL: " + dll);
        IntPtr state = luaL_newstate();
        if (state == IntPtr.Zero) throw new Exception("Cannot create Lua state.");
        try {
            luaL_openlibs(state);
            int result = luaL_loadstring(state, code);
            if (result == 0) result = lua_pcallk(state, 0, 0, 0, IntPtr.Zero, IntPtr.Zero);
            if (result != 0) {
                UIntPtr length;
                IntPtr message = lua_tolstring(state, -1, out length);
                if (message == IntPtr.Zero) throw new Exception("Lua raised a non-string error.");

                // Copy Lua's length-delimited UTF-8 bytes. Windows PowerShell's
                // .NET Framework does not provide Marshal.PtrToStringUTF8.
                byte[] bytes = new byte[checked((int)length.ToUInt64())];
                Marshal.Copy(message, bytes, 0, bytes.Length);
                throw new Exception(System.Text.Encoding.UTF8.GetString(bytes));
            }
        }
        finally { lua_close(state); }
    }
}
'@
}

[LxcPrototypeHost]::Run($taskDll, "dofile([==[$taskTest]==]);")
