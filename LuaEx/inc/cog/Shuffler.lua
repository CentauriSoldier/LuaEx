--[[!
@fqxn CoG.Shuffler
@desc Creates systems for randomized, non-repeating selection from a set of items, with support for resetting once all items have been selected. It maintains two internal tables: the pool, which stores all added items, and the buffer, a shuffled working copy used for pulling items via pop(). By default, when the buffer is emptied through pop(), it automatically resets by refilling from the pool.
!]]

--TODO localization
local type = type;
local math = math;
local ipairs = ipairs;
local pairs = pairs;

local function copyPool(tInput)
    assert(rawtype(tInput) == "table" and not class.isinstance(tInput), "Shuffler pool must be a dense array.");
    local tCopy = {};
    local nCount = 0;

    for nIndex in pairs(tInput) do
        assert(rawtype(nIndex) == "number" and nIndex >= 1 and nIndex < math.huge and nIndex % 1 == 0,
               "Shuffler pool must use positive integer indices.");
        nCount = nCount + 1;
    end

    for nIndex = 1, nCount do
        assert(tInput[nIndex] ~= nil, "Shuffler pool cannot contain holes.");
        tCopy[nIndex] = tInput[nIndex];
    end

    return tCopy;
end

local function validateSkipReset(bSkipReset)
    assert(bSkipReset == nil or rawtype(bSkipReset) == "boolean", "SkipReset must be a boolean or nil.");
end

return class("Shuffler",
{--METAMETHODS
    __pairs = function(this, cdat)
        local tRemaining = cdat.pro.remaining;
        local nIndex = 0;
        local nMax = #tRemaining;

        return function()

            -- Stop at this cycle's boundary, even when pop refills the buffer.
            -- Replacing the buffer also invalidates an existing iterator.
            if (nIndex < nMax and rawequal(cdat.pro.remaining, tRemaining) and #tRemaining > 0) then
                nIndex = nIndex + 1;
                return nIndex, this.pop();
            end

        end

    end,
},
{--STATIC PUBLIC
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --Shuffler = function(this) end, --static constructor (runs after class object creation)
},
{--PRIVATE
    AutoReset__autoF_ = true,
},
{--PROTECTED
    pool            = {},
    remaining       = {},

    shuffle = function(this, cdat)
        local tRemaining = cdat.pro.remaining;
        local nRemaining = #tRemaining;

        for x = nRemaining, 2, -1 do
            local y = math.random(x);
            tRemaining[x], tRemaining[y] = tRemaining[y], tRemaining[x];
        end

    end,
},
{--PUBLIC
    --[[!
    @fqxn CoG.Shuffler.Methods.Shuffler
    @pulsarlua function Shuffler
    @desc The class constructor.
    @param table|nil Optional argument that is a numerically-indexed table containing items to add to the pool.
    !]]
    Shuffler = function(this, cdat, tThePool)

        if (tThePool ~= nil) then
            this.set(tThePool);
        end

    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.add
    @pulsarlua function Shuffler.add
    @desc Adds any non-nil item to the pool and resets the buffer.
    @param any vItem Any non-nil item.
    @param boolean|nil Optional argument that, if set to true, will skip resetting the buffer. This is useful for bulk additions.
    @ret boolean bAddded True if the item was added, false otherwise.
    !]]
    add = function(this, cdat, vItem, bSkipReset)
        validateSkipReset(bSkipReset);
        local bRet = false;

        if (vItem ~= nil) then
            bRet = true;
            local pro = cdat.pro;

            table.insert(pro.pool, vItem);

            if (bRet and not bSkipReset) then
                this.reset();
            end

        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.empty
    @pulsarlua function Shuffler.empty
    @desc Empties the buffer so that no items are available for popping. The buffer will refill upon a reset.
    !]]
    empty = function(this, cdat)
        cdat.pro.remaining = {};
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.getRemaining
    @pulsarlua function Shuffler.getRemaining
    @desc Returns the total number items available in the buffer to pop before it requires reset.
    @ret number bRemaining The total number of items available.
    !]]
    getRemaining = function(this, cdat)
        return #cdat.pro.remaining;
    end,









    isEmpty = function(this, cdat)
        return #cdat.pro.remaining < 1;
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.remove
    @pulsarlua function Shuffler.remove
    @desc Removes an item from the pool and resets the buffer.
    <br>Note: if there is more than one instance of the item, only the first one (arbitrarily) encountered will be removed.
    @param any vItem Any non-nil item that exists in the pool.
    @param boolean|nil Optional argument that, if set to true, will skip resetting the buffer. This is useful for bulk removals.
    @ret number bRemoved True if the item was removed, false otherwise.
    !]]
    remove = function(this, cdat, vItem, bSkipReset)
        validateSkipReset(bSkipReset);
        local bRet = false;
        local pro = cdat.pro;
        local tPool = pro.pool;
        local tRemaining = pro.remaining;

        if (vItem ~= nil) then
            local zItem = type(vItem);

            for nIndex, vMyItem in ipairs(tPool) do

                if (zItem == type(vMyItem) and vItem == vMyItem) then
                    table.remove(tPool, nIndex);
                    bRet = true;
                    break;
                end

            end

            if (bRet) then

                if (not bSkipReset) then
                    this.reset();
                else
                    -- Remove one available occurrence without replenishing drawn items.
                    for nIndex, vMyItem in ipairs(tRemaining) do

                        if (zItem == type(vMyItem) and vItem == vMyItem) then
                            table.remove(tRemaining, nIndex);
                            break;
                        end

                    end

                end

            end

        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.pop
    @pulsarlua function Shuffler.pop
    @desc Removes a random item from the buffer and returns that item to the caller. If it's the last item in the buffer and auto-reset is enabled, the buffer is reset.
    @ret any vItem The item removed from the buffer.
    !]]
    pop = function(this, cdat)
        local vRet;
        local pro        = cdat.pro;
        local tRemaining = pro.remaining;
        local nRemaining = #tRemaining;

        if (nRemaining > 0) then
            vRet = tRemaining[nRemaining];
            table.remove(tRemaining, nRemaining);
        end

        if (#pro.remaining < 1 and cdat.pri.AutoReset) then
            this.reset();
        end

        return vRet;
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.purge
    @pulsarlua function Shuffler.purge
    @desc Removes all the items from the pool and buffer.
    !]]
    purge = function(this, cdat)
        cdat.pro.pool       = {};
        cdat.pro.remaining  = {};
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.reset
    @pulsarlua function Shuffler.reset
    @desc Resets the buffer to contain all pool items, shuffles it and makes available all items for popping.
    !]]
    reset = function(this, cdat)
        local pro           = cdat.pro;
        local tPool         = pro.pool;
        pro.remaining       = {};
        local tRemaining    = pro.remaining;

        for nIndex, vItem in ipairs(tPool) do
            tRemaining[nIndex] = vItem;
        end

        pro.shuffle();
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.set
    @pulsarlua function Shuffler.set
    @desc Replaces the pool with a validated dense array and resets the buffer.
    @param table tSet Numerically indexed pool entries. Invalid input leaves the existing pool unchanged.
    !]]
    set = function(this, cdat, tSet)
        local tPool = copyPool(tSet);
        cdat.pro.pool = tPool;
        this.reset();

    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.size
    @pulsarlua function Shuffler.size
    @desc Returns the total number items in the pool (not the buffer).
    @ret number bRemaining The total number of items in the pool.
    !]]
    size = function(this, cdat)
        return #cdat.pro.pool;
    end,
    --[[!
    @fqxn CoG.Shuffler.Methods.shuffle
    @pulsarlua function Shuffler.shuffle
    @desc Shuffles the items in the buffer. By default, this is done automatically when all items in the buffer have been popped (unless the AutoReset flag has been set to false).
    !]]
    shuffle = function(this, cdat)
        cdat.pro.shuffle();
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
