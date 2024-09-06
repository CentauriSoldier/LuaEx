return class("ItemStashSystem",
{--METAMETHODS
    __ipairs = function(this, cdat)
        local tTabs     = cdat.pri.tabs;
        local nIndex    = 0;
        local nMax      = #tTabs;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex, tTabs[nIndex];
            end

        end

    end,
},
{--STATIC PUBLIC
    --ItemStashSystem = function(stapub) end,
},
{--PRIVATE
    maxItemsPerTab  = -1,
    Owner__autoRF   = null,
    tabs            = {},
},
{--PROTECTED
},
{--PUBLIC
    ItemStashSystem = function(this, cdat, oOwner, nTabs, nMaxItemsPerTab)
        local pri = cdat.pri;

        nTabs = rawtype(nTabs) == "number" and math.floor(nTabs) or 1;
        nTabs = nTabs > 0 and nTabs or 1;
        nMaxItemsPerTab = rawtype(nMaxItemsPerTab) == "number" and math.floor(nMaxItemsPerTab) or math.huge;
        nMaxItemsPerTab = nMaxItemsPerTab > 0 and nMaxItemsPerTab or math.huge;

        local tTabs = pri.tabs;

        for x = 1, nTabs do
            tTabs[x] = ItemSystem(nMaxItemsPerTab);
        end

        pri.maxItemsPerTab = nMaxItemsPerTab;

        --TODO assert oOwner
        pri.Owner = oOwner;
    end,
    addTab = function(this, cdat)
        local pri           = cdat.pri;
        local tTabs         = pri.tabs;

        tTabs[#tTabs + 1] = ItemSystem(pri.maxItemsPerTab);
        return this;
    end,
    getTab = function(this, cdat, nTab)
        local tTabs = cdat.pri.tabs;
        local oRet;

        if (tTabs[nTab] ~= nil) then
            oRet = tTabs[nTab];
        end

        return oRet;
    end,
    getTabCount = function(this, cdat)
        return #cdat.pri.tabs;
    end,
    eachTab = function(this, cdat)
        local tTabs     = cdat.pri.tabs;
        local nIndex    = 0;
        local nMax      = #tTabs;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex, tTabs[nIndex];
            end

        end

    end,
    removeTab = function(this, cdat, nTab)
        local tTabs     = cdat.pri.tabs;
        local oRet;

        if (tTabs[nTab] ~= nil and #tTabs > 1) then
            oRet = tTabs[nTab];
            table.remove(tTabs, nTab);
        end

        return oRet;
    end,
    --tabExists--TODO FINISH
    tabExistsAt = function(this, cdat, nTab)
        return cdat.pri.tabs[nTab] ~= nil;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
