--[[!
    @fqxn Tests.ExplicitClassScope
    @desc Regression for a formerly leaked local class reference. Explicit bindings
    permit lookup inside the declaring block; omitted environments grant no access.
    Run from the repository root: lua "bugs/failed tests.lua".
!]]
if (not LUAEX_INIT) then
    require("LuaEx.load")(1);
end

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
        class.getbyname(sClassName, {[sClassName] = FailedScopeAccessTest}) == FailedScopeAccessTest);
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
