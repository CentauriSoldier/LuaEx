-- Override the addItem method to maintain order
addItem = function(cdat, vItem)
    local bRet = false

    if (rawtype(vItem) ~= "nil") then
        if (not cdat.pri.set[vItem]) then
            cdat.pri.set[vItem] = true
            cdat.pri.size = cdat.pri.size + 1
            cdat.pri.indexed[cdat.pri.size] = vItem
            table.insert(cdat.pri.ordered, vItem)
            bRet = true
        end
    end

    return bRet
end

-- Override the removeItem method to maintain order
removeItem = function(cdat, vItem)
    local bRet = false

    if (cdat.pri.set[vItem] ~= nil) then
        cdat.pri.set[vItem] = nil

        for x = 1, cdat.pri.size do
            if (cdat.pri.indexed[x] == vItem) then
                table.remove(cdat.pri.indexed, x)
                break
            end
        end

        for x = 1, #cdat.pri.ordered do
            if (cdat.pri.ordered[x] == vItem) then
                table.remove(cdat.pri.ordered, x)
                break
            end
        end

        cdat.pri.size = cdat.pri.size - 1
        bRet = true
    end

    return bRet
end

return class("OrderedSet",
{--METAMETHODS


-- Override the __call method to iterate over the ordered set
__call = function(this, cdat)
    local nIndex = 0
    local nMax = #cdat.pri.ordered

    return function()
        nIndex = nIndex + 1
        if (nIndex <= nMax) then
            return cdat.pri.ordered[nIndex]
        end
    end
end,

-- Override the __tostring method to maintain order in string representation
__tostring = function(this, cdat)
    local sRet = "{"

    for _, vItem in ipairs(cdat.pri.ordered) do
        sRet = sRet .. tostring(vItem) .. ", "
    end

    return sRet:sub(1, #sRet - 2) .. "}"
end,

-- Override methods like __add, __sub, __eq to ensure they work correctly with ordered sets

__add = function(left, right, cdat)
    assert(type(left) == "OrderedSet", sOtherError % {method = "__add"} .. type(left) .. '.')
    assert(type(right) == "OrderedSet", sOtherError % {method = "__add"} .. type(right) .. '.')

    local oRet = OrderedSet()
    local newcdat = cdat.ins[oRet]
    local leftcdat = cdat.ins[left]
    local rightcdat = cdat.ins[right]

    for _, vItem in ipairs(leftcdat.pri.ordered) do
        addItem(newcdat, vItem)
    end

    for _, vItem in ipairs(rightcdat.pri.ordered) do
        addItem(newcdat, vItem)
    end

    return oRet
end,

__sub = function(left, right, cdat)
    assert(type(left) == "OrderedSet", sOtherError % {method = "__sub"} .. type(left) .. '.')
    assert(type(right) == "OrderedSet", sOtherError % {method = "__sub"} .. type(right) .. '.')

    local oRet = OrderedSet()
    local newcdat = cdat.ins[oRet]
    local leftcdat = cdat.ins[left]
    local rightcdat = cdat.ins[right]

    for _, vItem in ipairs(leftcdat.pri.ordered) do
        if not rightcdat.pri.set[vItem] then
            addItem(newcdat, vItem)
        end
    end

    return oRet
end,

__eq = function(left, right, cdat)
    assert(type(left) == "OrderedSet", sOtherError % {method = "__eq"} .. type(left) .. '.')
    assert(type(right) == "OrderedSet", sOtherError % {method = "__eq"} .. type(right) .. '.')
    local leftcdat = cdat.ins[left]
    local rightcdat = cdat.ins[right]

    if leftcdat.pri.size ~= rightcdat.pri.size then
        return false
    end

    for i, vItem in ipairs(leftcdat.pri.ordered) do
        if vItem ~= rightcdat.pri.ordered[i] then
            return false
        end
    end

    return true
end,
},
{--STATIC PUBLIC

},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    OrderedSet = function(this, cdat, super)
        super();
    end,
},
Set,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
