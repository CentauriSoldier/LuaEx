local class         = class;
local pairs         = pairs;
local type          = type;

local _eType        = Affix.TYPE;

return class("Affixory",
{--METAMETHODS
    -- Add any necessary metamethods here later
},
{--STATIC PUBLIC
    -- Define any static public variables or functions here later
},
{--PRIVATE
    maxPrefixes = 0,
    maxSuffixes = 0,
    prefixes    = {},
    suffixes    = {},
},
{--PROTECTED
    --[[!
    @fqxn CoG.Affix System.Affixory.Methods.Affixory
    @desc The constructor for the Affixory class.
    @vis Protected.
    @param int nMaxPrefixes The maximum number of prefixes the container can hold.
    @param int nMaxSuffixes The maximum number of suffixes the container can hold.
    !]]
    Affixory = function(this, cdat, nMaxPrefixes, nMaxSuffixes)
        local pri = cdat.pri;

        type.assert.positiveInteger(nMaxPrefixes, true);
        type.assert.positiveInteger(nMaxSuffixes, true);

        pri.maxPrefixes = nMaxPrefixes;
        pri.maxSuffixes = nMaxSuffixes;

        -- Initialize tables for storing affixes
        pri.prefixes    = {};
        pri.suffixes    = {};
    end,
},
{--PUBLIC
    --[[!
    @fqxn CoG.Affix System.Affixory.Methods.getMaxPrefixes
    @desc Gets the maximum number of prefixes this container can hold.
    @ret int nMaxPrefixes The maximum number of prefixes.
    !]]
    getMaxPrefixes = function(this, cdat)
        return cdat.pri.maxPrefixes;
    end,
    --[[!
    @fqxn CoG.Affix System.Affixory.Methods.getMaxSuffixes
    @desc Gets the maximum number of suffixes this container can hold.
    @ret int nMaxSuffixes The maximum number of suffixes.
    !]]
    getMaxSuffixes = function(this, cdat)
        return cdat.pri.maxSuffixes;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
