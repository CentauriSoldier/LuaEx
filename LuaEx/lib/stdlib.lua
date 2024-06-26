local tLuaEx = rawget(_G, "luaex");
local rawtype 	= rawtype;



function protect(sReference)--TODO what is the purpose of this? Does it violate POLA?
    local sReferenceType 	= rawtype(sReference);
    local sInputType		= rawtype(_G[sReference]);
    assert(sReferenceType == "string" and sInputType ~= "nil", "Reference must be a string which is a key in _G. Input given is '"..tostring(sReference).."' of type "..sReferenceType..".");
    assert(rawtype(tLuaEx[sReference]) == "nil", "Cannot protect item '"..sReference.."'; already protected.")
    local vInput 			= _G[sReference];

    local vProtected = vInput;

    --process the table (if needed)
    if (sInputType == "table") then--TODO check if the table is locked
        --clone the table
        vProtected = clone(vInput);
        --purge it
        table.purge(vInput);
        --forward the old reference to the new table
        vInput = setmetatable(vInput, {
            __index 	= vProtected,
            __newindex 	= vProtected,
        });
    end

    --protect the item
    tLuaEx[sReference] = vProtected;
    --clear the original entry from the global table
    _G[sReference] = nil;
end


--Credit for original https://stackoverflow.com/questions/24714253/how-to-loop-through-the-table-and-keep-the-order
function spairs(tInput, bReverse)
    local tSorted = {};
    local nRemovalIndex = 1;

    if (type(bReverse) == "boolean" and bReverse) then
        nRemovalIndex = nil;
    end

    for vKey in next, tInput do
        table.insert(tSorted, vKey);
    end

    table.sort(tSorted);

    return function()
        local vKey = table.remove(tSorted, nRemovalIndex);

        if vKey ~= nil then
            return vKey, tInput[vKey];
        end
    end

end
