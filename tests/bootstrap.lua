--[[!
    @fqxn Tests.Bootstrap
    @desc Supplies native test setup and the existing virtual-root XML fixture.
    Preserves native print for serializer tests. Unmocked filesystem writes are
    rejected; repository reads resolve independently of the working directory.
!]]
local Bootstrap = {};

--[[!
    @fqxn Tests.Bootstrap.run
    @desc Initializes the full current core and runs one regression, restoring
    host I/O wrappers even after a failed check.
    @param string sRoot Repository root relative to the invoking process.
    @param string sFile Repository-relative suite path.
!]]
function Bootstrap.run(sRoot, sFile)
    require("LuaEx.load")();
    local fOpen = io.open;
    local fLoadFile = loadfile;
    local tMemory = {};

    -- Resolve only known repository roots; other native paths retain their meaning.
    local function fResolve(sPath)
        local sNormalized = sPath:gsub("\\", "/");
        if (sNormalized:sub(1, 7) == "/LuaEx/") then sNormalized = sNormalized:sub(2); end
        if (sNormalized:match("^LuaEx/") or sNormalized:match("^tests/") or
            sNormalized:match("^examples/") or sNormalized:match("^docs/")) then
            return sRoot.."/"..sNormalized;
        end
        return sPath;
    end

    io.open = function(sPath, sMode)
        sMode = sMode or "r";
        if (sPath == "/xml-test.tmx") then
            if (sMode:find("w", 1, true)) then
                tMemory[sPath] = "";
                return {
                    write = function(this, sText) tMemory[sPath] = tMemory[sPath]..sText; return this; end,
                    close = function() return true; end,
                };
            elseif (tMemory[sPath]) then
                return {read = function() return tMemory[sPath]; end, close = function() return true; end};
            end
        end

        assert(not sMode:find("[wa+]"), "Test attempted an unmocked filesystem write: "..sPath);
        return fOpen(fResolve(sPath), sMode);
    end;
    loadfile = function(sPath, ...)
        return fLoadFile(fResolve(sPath), ...);
    end;

    local bOK, sReason = xpcall(function()
        assert(loadfile(sFile))();
    end, debug.traceback);

    io.open = fOpen;
    loadfile = fLoadFile;
    if (not bOK) then error(sReason, 0); end
end

return Bootstrap;
