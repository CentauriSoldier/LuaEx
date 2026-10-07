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

-- Run in a fresh Lua process, like the examples. No implementation files are changed.
-- PASS means expected behavior; FAIL demonstrates a defect. Errors are caught and printed.
local nFailures=0;
local function check(sName,fCheck)
 local bOK,vResult=pcall(fCheck);
 local bPassed=bOK and vResult==true;
 if not bPassed then nFailures=nFailures+1; end
 print((bPassed and 'PASS: ' or 'FAIL: ')..sName);
 print('  Expected: true. Actual: '..tostring(vResult));
end
-- Cause: lib/cloner.lua tPure.table copies a self-reference to the ORIGINAL table.
-- Expected clone.self == clone; currently clone.self == original.
-- Thus a mutation through clone.self incorrectly changes the original.
-- clone(t,true) excludes metatables to isolate the copying behavior.
check('CONTROL: ordinary clone',function()
 local t={value=1}; local c=clone(t,true); return c~=t and c.value==1;
end);
check('Self-reference points to clone',function()
 local t={}; t.self=t; local c=clone(t,true); return c.self==c;
end);
check('Mutation through clone leaves original unchanged',function()
 local t={value=1}; t.self=t; local c=clone(t,true); c.self.value=2; return t.value==1;
end);
print('Failed expectations: '..nFailures);
