--[[!
    @fqxn CoG.ItemSystem.BaseItem
    @desc STUFF HERE
!]]
return class("BaseItem",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = BaseItem(); --TODO FINISH
        --print(type(oNew))
        return oNew;
    end,
},
{--STATIC PUBLIC
    BaseItem = function(stapub)
    end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE
},
{--PROTECTED
    Equipable__autoA_is     = false,
    events                  = null,
    Name__autoA_            = "", --leave as non-final so subclasses can alter it but create a public accessor only
    Quest__autoA_is         = false,
    Removable__autoA_is     = true,
    Sellable__autoA_is      = true,
    TagSystem__autoAF       = null,
    Tradable__autoA_is      = true,


    importEventsTable__FNL = function(this, cdat, tEvents)
        local tRet      = {};
        local nRet      = 0;
        local tTracker  = {};

        if (type(tEvents) == "table") then

            for _, sEvent in pairs(tEvents) do

                if (type(sEvent) == "string" and tTracker[sEvent] == nil) then
                    tTracker[sEvent]    = true;

                    nRet                = nRet + 1;
                    tRet[nRet]          = sEvent;
                end

            end

        end

        return tRet, nRet;
    end,

    BaseItem = function(this, cdat, sName, tEventsRaw)
        local pro = cdat.pro;
        type.assert.string(sName, "%S+");

        pro.Name        = sName;
        pro.TagSystem   = TagSystem();

        --create the item's events table
        local tEvents, nEvents = pro.importEventsTable(tEventsRaw);

        local tEvents       = {};
        local tEventsDecoy  = {};
        local tEventsMeta   = {

        };



        --pro.events
    end,
},
{--PUBLIC

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
