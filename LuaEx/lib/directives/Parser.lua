--[[!
@fqxn LuaEx.Directives.Parser
@desc Reads structured line comments from gaps in an existing token stream.
    Strings and executable tokens stay opaque; long comments, including DOx,
    cannot introduce directives. Declaration parsers decide which gaps are targets.
!]]
-- Keep runtime string operations independent of application replacements.
local _find, _gsub, _match, _sub = string.find, string.gsub, string.match, string.sub;


local Diagnostics = require("LuaEx.lib.directives.Diagnostics");
local Parser = {};
local _ipairs, _assert = ipairs, assert;

--[[!
@fqxn LuaEx.Directives.Parser.create
@desc Indexes annotation comments by following token without rescanning Lua bodies.
@param string sSource Original source text.
@param string pFile Diagnostic filename.
@param table tTokens Existing tokens with Start, Stop and Line offsets.
@ret table Reader with take and reject operations for declaration boundaries.
!]]
function Parser.create(sSource, pFile, tTokens)
    local tAnnotations, nPrevious, nLine = {}, 0, 1;
    for nIndex, tToken in _ipairs(tTokens) do
        local sGap = _sub(sSource, nPrevious + 1, tToken.Start - 1);
        local nPosition, tPending = 1, {};
        while (nPosition <= #sGap) do
            local sEquals = _match(sGap, "^%-%-%[(=*)%[", nPosition);
            local nAfter;
            if (sEquals) then
                local nEnd = _assert(_find(sGap, "]"..sEquals.."]", nPosition + #sEquals + 4, true));
                nAfter = nEnd + #sEquals + 2;
            elseif (_sub(sGap, nPosition, nPosition + 1) == "--") then
                nAfter = _find(sGap, "\n", nPosition, true) or (#sGap + 1);
                local sComment = _sub(sGap, nPosition, nAfter - 1);
                local sName, sValue = _match(sComment, "^%-%-%-%s*@([%a_][%w_]*)%s*(.-)%s*$");
                -- Parameter/return comments remain documentation, never contracts.
                if (sName and sName ~= "param" and sName ~= "ret" and sName ~= "return") then
                    tPending[#tPending + 1] = {Name = sName, Value = sValue, File = pFile, Line = nLine};
                end
            else nAfter = nPosition + 1; end
            local _, nNewLines = _gsub(_sub(sGap, nPosition, nAfter - 1), "\n", "");
            nLine = nLine + nNewLines;
            nPosition = nAfter;
        end
        if (#tPending > 0) then tAnnotations[nIndex] = tPending; end
        local _, nNewLines = _gsub(tToken.Text, "\n", "");
        nLine, nPrevious = tToken.Line + nNewLines, tToken.Stop;
    end
    local Reader = {};
    -- Consume only at a declaration boundary supplied by its owning parser.
    function Reader.take(nIndex)
        local tPending = tAnnotations[nIndex];
        tAnnotations[nIndex] = nil;
        return tPending;
    end
    function Reader.reject(nIndex)
        local tPending = Reader.take(nIndex);
        if (tPending) then Diagnostics.fail(tPending[1], "Directive has no supported following declaration in this scope."); end
    end
    return Reader;
end

return Parser;
