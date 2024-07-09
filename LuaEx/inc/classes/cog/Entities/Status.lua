return class("StatusHandler",
{--METAMETHODS
},
{--STATIC PUBLIC
    StatusHandler = function(stapub)
        local tConfig = rawget(_G, "luaex").config.Status;

        for nIndex, sEffect in pairs(tConfig.effects) do
            stapub[sEffect.."__RO"] = nIndex;
        end

    end,
},
{--PRIVATE

},
{--PROTECTED
    effects = {

    },
},
{--PUBLIC
    StatusHandler = function(this, cdat, tStatuses)

    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
