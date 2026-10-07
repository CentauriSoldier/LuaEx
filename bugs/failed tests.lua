--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then

    function getsourcepath()
        --determine the call location
        local sPath = debug.getinfo(1, "S").source;
        --remove the calling filename
        local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
        --make a pattern to account for case
        local sFilename = "";
        for x = 1, #sFilenameRAW do
            local sChar = sFilenameRAW:sub(x, x);

            if (sChar:find("[%a]")) then
                sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
            else
                sFilename = sFilename..sChar;
            end

        end

        sPath = sPath:gsub("@", ""):gsub(sFilename, "");
        --remove the "/" at the end
        sPath = sPath:sub(1, sPath:len() - 1);

        return sPath;
    end

    --determine the call location
    sSourcePath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sSourcePath.."\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================

--[[NOTE:
This test reproduces access to a class outside the scope of its local declaration.

Expected behavior:
Metadata queries may identify the class, but class.getbyname() must return nil
when the class is not visible to the caller. Its static methods must therefore
remain inaccessible through that query.

Current behavior:
class.getbyname() returns the class object after its declaring block has ended.
The returned object permits calling its static methods.

Expected output for the two scope checks:
PASS: An out-of-scope class lookup returns nil.
Lookup returned type: nil
PASS: The lookup does not permit calling an out-of-scope static method.
Failed expectations: 0
There should be no static method call after the lookup returns nil.

Failing output reproduced with the current implementation:
FAIL: An out-of-scope class lookup returns nil.
Lookup returned type: class
Static method call succeeded: The out-of-scope class's static method was called.
FAIL: The lookup does not permit calling an out-of-scope static method.
Failed expectations: 2
The inside-block, global-environment and metadata checks still pass.

Cause in LuaEx/lib/class.lua:
1. kit.build() defines isInScope as function() return oClass ~= nil end.
   This closure captures the class builder's local oClass, not the caller's
   local class identifier. After class.build() assigns oClass, that reference
   remains non-nil even after the user's local declaration leaves scope.
2. class.build() stores the class object in class.repo.byKit and
   class.repo.byName, with its kit in class.repo.byObject. kit.build() also
   stores the kit in kit.repo.byName and kit.repo.byObject. These registry
   references retain the class independently of the user's local variable.
3. getKit() resolves a supplied class name through kit.repo.byName.
4. class.getbyname() accepts that kit's isInScope() result and returns the
   registered class object through class.repo.byKit. The test below proves
   that the returned object also exposes its static GetMessage() method.

Other object-returning functions using the same scope-check pattern:
- class.getparent(): returns the immediate parent after checking both kits.
- class.getbase(): returns the root ancestor after checking its kit.
- class.getchildren(): returns direct child objects whose kit checks pass.
- class.of(): returns an instance's class object after checking its kit.
These relationship paths were traced in the implementation; this file's
executable reproduction specifically tests class.getbyname() and subsequent
static method access, rather than claiming to test every relationship path.

class.haspublicmember() also calls isInScope(), but returns presence, static
status and member type, not the class object. Metadata availability itself
is not the access failure demonstrated here.

Relevant source locations when this reproduction was written:
getKit:                  LuaEx/lib/class.lua:315
class.getbase:           LuaEx/lib/class.lua:344
class.getbyname:         LuaEx/lib/class.lua:362
class.getchildren:       LuaEx/lib/class.lua:393
class.getparent:         LuaEx/lib/class.lua:456
class.haspublicmember:   LuaEx/lib/class.lua:494
class.of:                LuaEx/lib/class.lua:786
class.build:             LuaEx/lib/class.lua:827
kit.build / isInScope:   LuaEx/lib/class.lua:1814

The failure is the exposure of the actual class object through a name lookup
outside its declaration's scope. Lua's local-variable visibility still works;
the registry lookup bypasses it, and the retained-reference check permits it.
No name-string fallback is expected: the inaccessible-object result is nil.

This example prints the failed expectations without stopping at the first one.
It does not change the class system or write any files.
]]

local sClassName = "FailedScopeAccessTest";
local nFailed = 0;

local function Report(sTest, bPassed)
    print((bPassed and "PASS: " or "FAIL: ")..sTest);

    if (not bPassed) then
        nFailed = nFailed + 1;
    end

end

--the class is visible only inside this block
do
    local FailedScopeAccessTest = class(sClassName,
    {--metamethods
    },
    {--public static members
        GetMessage = function()
            return "The out-of-scope class's static method was called.";
        end,
    },
    {--private members
    },
    {--protected members
    },
    {--public members
        FailedScopeAccessTest = function(this, cdat)
        end,
    });

    Report("The class is accessible inside its declaring block.",
        class.getbyname(sClassName) == FailedScopeAccessTest);
end

--the local class identifier is no longer visible here
Report("The class was not exported to the global environment.",
    rawget(_G, sClassName) == nil);
Report("The class name remains available as metadata.",
    class.getname(sClassName) == sClassName);

local cRetrieved = class.getbyname(sClassName);
Report("An out-of-scope class lookup returns nil.", cRetrieved == nil);
print("Lookup returned type: "..type(cRetrieved));

local bStaticAccessible = false;

if (class.is(cRetrieved)) then
    local bSuccess, vResult = pcall(function()
        return cRetrieved.GetMessage();
    end);

    bStaticAccessible = bSuccess;
    print("Static method call "..(bSuccess and "succeeded: " or "failed: ")..tostring(vResult));
end

Report("The lookup does not permit calling an out-of-scope static method.",
    not bStaticAccessible);
print("Failed expectations: "..tostring(nFailed));
