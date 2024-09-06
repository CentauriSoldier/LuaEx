local _tCoGConfig   = rawget(_G, "luaex").cog.config;
local _eMaxTier     = _tCoGConfig.Affix.maxTier;

local class         = class;
local pairs         = pairs;
local type          = type;
local AffixSystem   = AffixSystem;

local function placeholder() end

return class("Affix",
{--METAMETHODS
    --[[!
    @fqxn CoG.Affix.Metamethods.__pairs
    @desc Iterates over the compatible classes table.
    !]]
    __pairs = function(this, cdat)
        return next, cdat.pri.appliesTo, nil;
    end,
},
{--STATIC PUBLIC
    Affix = function(stapub)
        stapub.MAX_TIER = _eMaxTier;
    end,
    --[[!
    @fqxn CoG.Affix.Enums.TYPE
    @desc Used for setting an <a href="#CoG.AffixSystem.Affix.Methods.Affix">Affix's</a> type.
    <hr>
    <ul>
        <li><b>PREFIX</b></li>
        <li><b>SUFFIX</b></li>
    </ul>
    !]]
    TYPE = enum("Affix.TYPE", {"PREFIX", "SUFFIX"}, nil, true),
},
{--PRIVATE
    appliesTo    = {},
    Tier__autoR_ = null,
    Type__autoR_ = null,
},
{--PROTECTED
    Name__autoRA        = null,
    Description__RA     = null,--TODO update links in docs below...
    --[[!
    @fqxn CoG.Affix.Methods.Affix
    @desc The constructor for the Affix class.
    @vis Protected.
    @param Affix.TYPE eType The type of the affix <em>(either <a href="CoG.Affix.Enums.TYPE.PREFIX">PREFIX</a> or <a href=".Affix.Enums.TYPE.SUFFIX">SUFFIX</a>)</em>.
    @param string sName The name of the affix. It should be a unique name among other affixes.
    @param string sDescription The description of the affix. It should explain precisely what the affix does.
    <br><strong class="text-danger">Warning</strong>: duplicate names with be silently overwritten with unpredictable results.
    @param TIER eTier The <a href="#CoG.Enums.TIER">TIER</a> of the affix.
    <br><strong>Note</strong>: the handler of the item/monster/etc. that hosts the affix is responsible for calling this function and determining when it should be called..
    @param table tAppliesTo The classes with which the affix is compatible. It must be a numerically-indexed table whose values are classes and there must be at least one entry.
    !]]
    Affix = function(this, cdat, eType, sName, sDescription, eTier, tAppliesTo)
        local pri = cdat.pri;
        local pro = cdat.pro;

        type.assert.custom(eType, "Affix.TYPE");
        type.assert.string(sName, "%S+");
        type.assert.custom(eTier, "TIER");

        if (eTier > _eMaxTier) then
            error("Error creating Affix.\nMax TIER is "..tostring(eMaxTier)..'. TIER given: '..tostring(eTier)..'.');
        end

        pri.Tier            = eTier;
        pri.Type            = eType;
        pro.activator       = fActivate;
        pro.deactivator     = fDeactivate;

        local tMyAppliesTo = pri.appliesTo;

        --TODO assert tAppliesTo
        for _, cTypeAppliesTo in pairs(tAppliesTo) do
            tMyAppliesTo[cTypeAppliesTo] = true;
        end

    end,
},
{--PUBLIC
    --[[!
    @fqxn CoG.Affix.Methods.isCompatibleWithClass
    @desc Determines whether this affix can be used with a given class.
    @param class cType The class to check.
    @ret boolean bIsCompatible True if compatible, false otherwise.
    !]]
    isCompatibleWithClass = function(this, cdat, cType)
        local bRet = class.is(cType);

        if (bRet) then

            for cMyType, _ in pairs(cdat.pri.appliesTo) do

                if (cType == cMyType) then
                    bRet = true;
                    break;
                end

            end

        end

        return bRet;
    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
