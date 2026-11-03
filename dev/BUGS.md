# Active bugs

Reviewed on November 2, 2026, using Lua 5.4.2 on Windows x64 and the current
LuaEx and sibling Dox checkouts. These are the two confirmed issues remaining
from the previous bug reproductions. No LuaEx core defect was confirmed by that
review; this is not a claim that the entire framework is defect-free.

Both issues belong to the separate Dox project. Resolved issues and reproductions
for retired APIs have been removed. The former Pulsar reproduction expected a
plain JSON document; the current ZIP exporter passed its 196-check regression.
The synthetic array metatable guard probe did not represent an unprotected real
array: actual arrays reject metatable replacement.

## Reproduction setup

Run each reproduction in a fresh Lua process from the LuaEx repository root.
The sibling Dox repository must be available at `../Dox`. Add its package path
before initializing LuaEx so declaration discovery includes Dox.

Use this setup before either reproduction:

```lua
package.path = "../Dox/?.lua;"..package.path;
require("LuaEx.init");

-- Capture generated HTML in memory. Reads of builder assets remain available;
-- output files are never created. Restore io.open before reporting errors.
local function captureHTML(oDocument)
    local fOpen = io.open;
    local tChunks = {};

    io.open = function(pFile, sMode)
        if (sMode == "w" or sMode == "wb") then
            return {
                write = function(_, sText)
                    tChunks[#tChunks + 1] = sText;
                    return true;
                end,
                close = function()
                    return true;
                end,
            };
        end

        return fOpen(pFile, sMode);
    end;

    local bSuccess, vResult = pcall(oDocument.export, "probe");
    io.open = fOpen;
    assert(bSuccess, vResult);

    return table.concat(tChunks);
end
```

## 1. Parameter columns mishandle tabs and repeated spaces

**Location:** `../Dox/dox/Parser.lxc`, `processBlockItem`, around line 172.

**Expected:** Whitespace separates the parameter type, name and description.
Tabs and repeated spaces should preserve those three columns.

**Actual:** Tabs raise `Unable to find space for column 1`. Two spaces after the
type produce an empty parameter-name column and move `sName` into the description.

**Cause:** The column splitter searches for one literal space and consumes only
that character rather than the complete whitespace separator.

After the shared setup, run:

```lua
local oTabs = Dox.DoxLua("Tab parameter probe");
oTabs.importString(
    "--[[! @fqxn ParamProbe @param string\tsName\tdescription !]]",
    Dox.DoxMime("lua")
);

local bTabsAccepted, vTabError = pcall(oTabs.refresh);
print("Tabs accepted:", bTabsAccepted); -- currently false
print("Tab error:", vTabError);

local oSpaces = Dox.DoxLua("Repeated-space parameter probe");
oSpaces.importString(
    "--[[! @fqxn ParamProbe @param string  sName  description !]]",
    Dox.DoxMime("lua")
);

local sHTML = captureHTML(oSpaces);

-- The generated JavaScript escapes closing-tag slashes in its HTML payload.
local bEmptyName = sHTML:find([=[<em><\/em>]=], 1, true) ~= nil;
local bCorrectName = sHTML:find([=[<em>sName<\/em>]=], 1, true) ~= nil;
print("Empty parameter name:", bEmptyName); -- currently true
print("Correct parameter name:", bCorrectName); -- currently false
```

## 2. HTML introduction backslashes are not escaped for JavaScript

**Location:** `../Dox/dox/Builders/HTML/DoxBuilderHTML.lxc`, `buildJS`, around line 163.

**Expected:** A literal path such as `C:\new` survives unchanged in the rendered
introduction.

**Actual:** The generated JavaScript template literal contains a single backslash.
JavaScript interprets `\n` as a newline, so the displayed introduction loses the
literal path.

**Cause:** Introduction escaping handles backticks and `${`, but does not escape
backslashes before placing the introduction into a JavaScript template literal.
This issue is separate from FQXN key escaping, which passed the current review.

After the shared setup, run:

```lua
local oDocument = Dox.DoxLua("Introduction path probe");
oDocument.setIntro([=[<p>C:\new</p>]=]);

local sHTML = captureHTML(oDocument);
local bUnescaped = sHTML:find([=[<p>C:\new</p>]=], 1, true) ~= nil;
local bEscaped = sHTML:find([=[<p>C:\\new</p>]=], 1, true) ~= nil;
print("Unescaped intro path:", bUnescaped); -- currently true
print("Escaped intro path:", bEscaped); -- currently false
```
