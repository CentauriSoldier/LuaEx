--[[!
    @fqxn Tests.Collections
    @desc Checks collection values, identity, removal, ordering, failure recovery,
    serialization and model-based Stack/Queue behavior. No native files are written.
!]]
if (not LUAEX_INIT) then require("LuaEx.load")(2); end
local _nChecks = 0;

--[[!
    @fqxn Tests.Collections.check
    @desc Asserts an independently specified expectation and counts the check.
    @param string sLabel Behavior under test.
    @param boolean bPassed Whether the expected behavior occurred.
!]]
local function check(sLabel, bPassed)
    assert(bPassed, sLabel);
    _nChecks = _nChecks + 1;
end

-- Compare operations to a plain-list model, including false and empty boundaries.
local tValues = {false, true, 0, "sword", {}, null};
local nSeed = 173;
local vOldReturn = rawget(_G, "vRet");
rawset(_G, "vRet", "unrelated game state");

for _, bStack in ipairs({true, false}) do
    local oCollection = bStack and Stack() or Queue();
    local tModel = {};
    local sPush = bStack and "push" or "enqueue";
    local sPop = bStack and "pop" or "dequeue";

    for nStep = 1, 600 do
        nSeed = (nSeed * 48271) % 2147483647;
        local nAction = nSeed % 7;

        if (nAction <= 2) then
            local vValue = tValues[nSeed % #tValues + 1];
            oCollection[sPush](vValue);
            table.insert(tModel, bStack and 1 or #tModel + 1, vValue);
        elseif (nAction == 3) then
            local vExpected = table.remove(tModel, 1);
            check("Pop/dequeue agrees with model", rawequal(oCollection[sPop](), vExpected));
        elseif (nAction == 4) then
            oCollection.reverse();
            for nIndex = 1, math.floor(#tModel / 2) do
                tModel[nIndex], tModel[#tModel - nIndex + 1] = tModel[#tModel - nIndex + 1], tModel[nIndex];
            end
        elseif (nAction == 5) then
            oCollection.clear();
            tModel = {};
        else
            oCollection[sPush](nil);
        end

        check("Peek preserves value and false", rawequal(oCollection.peek(), tModel[1]));
        check("Count agrees with model", #oCollection == #tModel and oCollection.size() == #tModel);
        check("Global return variable is untouched", rawget(_G, "vRet") == "unrelated game state");
    end

    oCollection.clear();
    check("Repeated empty removals return nil", oCollection[sPop]() == nil and oCollection[sPop]() == nil);
    oCollection[sPush](false);
    local oLoaded = deserialize(serialize(oCollection));
    check("Collection round trip preserves false", oLoaded.peek() == false and oLoaded[sPop]() == false);
    check("Restored state is independent", #oCollection == 1 and #oLoaded == 0);
end
rawset(_G, "vRet", vOldReturn);

local oSet = Set({"sword", "potion", false});
check("Remove chains", rawequal(oSet.remove("sword"), oSet));
check("Remove updates membership/count", not oSet.contains("sword") and #oSet == 2);
oSet.remove("absent");
check("Missing removal is harmless", #oSet == 2);
oSet.purgeSet(Set({false}));
check("Purge preserves unmatched values", #oSet == 1 and oSet.contains("potion"));
oSet.purgeSet(oSet);
check("Self purge empties Set", #oSet == 0 and tostring(oSet) == "{}");
check("Nil removal rejects", not pcall(oSet.remove, nil));

-- Equality metamethods must not confuse the identity used by membership keys.
local tEqualMeta = {__eq = function() return true; end};
local tFirst = setmetatable({name = "first"}, tEqualMeta);
local tSecond = setmetatable({name = "second"}, tEqualMeta);
oSet = Set({tFirst, tSecond});
oSet.remove(tSecond);
local vRemaining = oSet()();
check("Identity removal retains the correct equal-valued object", rawequal(vRemaining, tFirst) and oSet.contains(tFirst) and not oSet.contains(tSecond));

local tItem = {damage = {value = 7}};
oSet = Set({tItem, false, point(2, 3)});
local oCopy = clone(oSet);
for vMember in oCopy() do
    check("Cloned iteration agrees with membership", oCopy.contains(vMember));
    if (type(vMember) == "table") then
        check("Table member was copied", not rawequal(vMember, tItem));
        vMember.damage.value = 9;
    end
end
check("Cloned contents are independent", tItem.damage.value == 7 and not oCopy.contains(tItem));
local oCircular = Set();
oCircular.add(oCircular);
local oCircularCopy = clone(oCircular);
check("Circular Set clone reconnects to itself", oCircularCopy.contains(oCircularCopy) and not oCircularCopy.contains(oCircular));
local oSavedSet = deserialize(serialize(Set({false, "sword"})));
check("Set round trip retains membership", #oSavedSet == 2 and oSavedSet.contains(false) and oSavedSet.contains("sword"));

-- Dictionary keys remain sorted through ordinary and failing operations.
local oDictionary = SortedDictionary();
oDictionary.add("b", false).add("a", 1).add("c", tItem);
local tKeys = {};
for sKey in pairs(oDictionary) do tKeys[#tKeys + 1] = sKey; end
check("pairs uses sorted iteration", table.concat(tKeys, ",") == "a,b,c");
local _, vIteratorState = oDictionary();
check("Iterator does not expose private storage", rawequal(vIteratorState, oDictionary));
check("containsValue finds false", oDictionary.containsValue(false));
check("containsValue finds table identity", oDictionary.containsValue(tItem) and not oDictionary.containsValue({}));
check("Missing value returns false", oDictionary.containsValue("absent") == false);
oDictionary.set("empty", nil);
check("Explicit nil value retains its key", oDictionary.containsKey("empty") and oDictionary.containsValue(nil));
oDictionary.remove("empty");
check("Removing nil-valued key removes that value", not oDictionary.containsValue(nil));
oDictionary.setSortFunction(function(a, b) return a > b; end);
oDictionary.remove("b");
oDictionary.add("d", 4);
tKeys = {};
for sKey in oDictionary() do tKeys[#tKeys + 1] = sKey; end
check("Removal preserves descending comparator order", table.concat(tKeys, ",") == "d,c,a");
check("Failing comparator is rejected", not pcall(oDictionary.setSortFunction, function() error("bad comparator"); end));
oDictionary.add("e", 5);
tKeys = {};
for sKey in pairs(oDictionary) do tKeys[#tKeys + 1] = sKey; end
check("Comparator failure preserves later ordering", table.concat(tKeys, ",") == "e,d,c,a");
oDictionary.setSortFunction(function(a, b)
    if (a == "blocked" or b == "blocked") then error("blocked key"); end
    return a > b;
end);
local nSize = oDictionary.size();
check("Insertion comparator failure rejects", not pcall(oDictionary.add, "blocked", 99));
check("Insertion failure leaves no ghost key", oDictionary.size() == nSize and not oDictionary.containsKey("blocked"));
oDictionary.setSortFunction();
check("Invalid comparator rejects", not pcall(oDictionary.setSortFunction, false));
local oDictionaryCopy = clone(oDictionary);
oDictionaryCopy.get("c").damage.value = 12;
check("Dictionary clone owns nested values", oDictionary.get("c").damage.value == 7);
local oSavedDictionary = deserialize(serialize(oDictionary));
check("Dictionary round trip retains values and order", oSavedDictionary.size() == oDictionary.size() and oSavedDictionary.get("a") == 1);

print("PASS collections: ".._nChecks.." checks; models, false/empty boundaries, identity, cloning, sorting, failure recovery and serialization.");
