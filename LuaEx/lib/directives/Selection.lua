--[[!
@fqxn LuaEx.Directives.Selection
@desc Selects one declaration before semantic validation or initialization.
    An ordinary declaration replaces one @default candidate; every other
    duplicate combination is an error. Lexical children of losing classes vanish.
!]]
local Diagnostics = require("LuaEx.lib.directives.Diagnostics");
local Selection = {};
local _ipairs = ipairs;

--[[!
@fqxn LuaEx.Directives.Selection.choose
@desc Groups exact identities and selects deterministically without mutating bodies.
@param table tRecords Ordered candidates from the complete batch.
@param function fName Returns a resolved declaration identity.
@param string sKind Diagnostic declaration kind.
@ret table Selected records in original order.
!]]
function Selection.choose(tRecords, fName, sKind)
    local tGroups, tWinners = {}, {};
    for _, tRecord in _ipairs(tRecords) do
        local sName = fName(tRecord);
        local tGroup = tGroups[sName] or {};
        tGroups[sName] = tGroup;
        tGroup[#tGroup + 1] = tRecord;
        if (#tGroup > 2 or (#tGroup == 2 and not not tGroup[1].Default == not not tRecord.Default)) then
            Diagnostics.fail(tRecord, "Duplicate "..sKind..": "..sName.." (expected at most one ordinary and one @default declaration).");
        end
        tWinners[sName] = (#tGroup == 1 or not tRecord.Default) and tRecord or tGroup[1];
    end
    local tSelected = {};
    for _, tRecord in _ipairs(tRecords) do
        if (tWinners[fName(tRecord)] == tRecord) then tSelected[#tSelected + 1] = tRecord; end
    end
    return tSelected;
end

--[[!
@fqxn LuaEx.Directives.Selection.classes
@desc Selects enclosing classes before their lexical children. Rebuilds nested maps
    and removes enum/extension records belonging to discarded class declarations.
@param table tClasses Flat parsed class list.
@param table tEnums Flat parsed enum/extension list.
@ret table Selected classes, followed by selected-scope enum/extension records.
!]]
function Selection.classes(tClasses, tEnums)
    local tSelected, tLive, tPending = {}, {}, tClasses;
    while (#tPending > 0) do
        local tLevel, tNext = {}, {};
        for _, tClass in _ipairs(tPending) do
            if (not tClass.Outer or tLive[tClass.Outer]) then tLevel[#tLevel + 1] = tClass;
            else tNext[#tNext + 1] = tClass; end
        end
        if (#tLevel == 0) then break; end
        for _, tClass in _ipairs(Selection.choose(tLevel, function(tRecord) return tRecord.FullName; end, "class")) do
            tLive[tClass], tSelected[#tSelected + 1], tClass.Nested = true, tClass, {};
            if (tClass.Outer) then tClass.Outer.Nested[tClass.Name] = tClass; end
        end
        tPending = tNext;
    end
    local tRecords = {};
    for _, tEnum in _ipairs(tEnums) do
        if (not tEnum.Outer or tLive[tEnum.Outer]) then tRecords[#tRecords + 1] = tEnum; end
    end
    return tSelected, tRecords;
end

return Selection;
