# Run only this standalone Lua experiment. No wxLua or desktop automation is used.
param(
    [string]$LuaDll = (Join-Path $PSScriptRoot '../../wxLuma-main/Win/Bin/lua54.dll'),
    [switch]$Integration
)
$ErrorActionPreference = 'Stop'
$taskDll = (Resolve-Path -LiteralPath $LuaDll).Path
$taskTestName = if ($Integration) { 'integration.lua' } else { 'test.lua' }
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
                throw new Exception(Marshal.PtrToStringUTF8(lua_tolstring(state, -1, out length)));
            }
        }
        finally { lua_close(state); }
    }
}
'@
}

[LxcPrototypeHost]::Run($taskDll, "dofile([==[$taskTest]==]);")
