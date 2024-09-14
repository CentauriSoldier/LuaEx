local function validateAffix(vAffix)
    local cAffix = class.of(vAffix);

    if not (cAffix) then
        error("Error in modifying Item with affix.\nAffix must be an instance of a class. Got type "..type(vAffix)..".", 2);
    end

    if not (class.ischildorself(cAffix, Affix)) then
        error("Error in modifying Item with affix.\nAffix must be an instance of an Affix subclass.", 2);
    end
end

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
    --BaseItem = function(stapub)
    --end,
    --enum("Item.ACTION", {"DISCARD"}, nil, true),
},
{--PRIVATE
},
{--PROTECTED
    prefixes                = {},
    suffixes                = {},
    Description__autoA_     = "",
    Equipable__autoA_is     = false,
    Eventrix__autoAF        = null,
    Name__autoA_            = "", --leave as non-final so subclasses can alter it but create a public accessor only
    Quest__autoA_is         = false,
    Rarity__auto__          = false,
    Removable__autoA_is     = true,
    Sellable__autoA_is      = true,
    TagSystem__autoAF       = null,
    Tradable__autoA_is      = true,

    BaseItem = function(this, cdat, sName, sDescription, eRarity)
        local pro = cdat.pro;
        type.assert.string(sName, "%S+");
        type.assert.string(sDescription, "%S+");
        type.assert.custom(eRarity, "Rarity.LEVEL");

        pro.Eventrix    = eventrix();
        pro.Name        = sName;
        pro.Description = sDescription;
        pro.Rarity      = eRarity;
        pro.TagSystem   = TagSystem();

    end,
},
{--PUBLIC
    applyAffix = function(this, cdat, oAffix, eEventID, wEnv)
        local bRet = false;
        local pro = cdat.pro;
        --local yID = subtype(eIDInput);

        --if not (yID == "enumitem") then--or zID == "string") then
            --error("Error creating event. Event ID must be of type string or subtype enumitem. Type/subtype given: ${type}/${subtype}." % {type = zID, subtype = yID});
            --error("Error applying affix. Event ID must be of subtype enumitem. Subtype given: ${subtype}." % {subtype = yID});
        --end

        validateAffix(oAffix);

        local eType             = Affix.TYPE;
        local eAffixType        = oAffix.getType();
        local eAffixTier        = oAffix.getTier();
        local bIsPrefix         = eAffixType == eType.PREFIX;

        local eRarity           = pro.Rarity;
        local eMaxTier          = Rarity.getMaxTier(eRarity);

        local nMaxAffixes       = bIsPrefix and
                                  Rarity.getPrefixCount(eRarity) or
                                  Rarity.getSuffixCount(eRarity);
        local tAffixes          = bIsPrefix and pro.prefixes or pro.suffixes;

        if (#tAffixes < nMaxAffixes and
            eAffixTier <= eMaxTier  and
            oAffix.isCompatibleWithClass(class.of(this))) then
            --apply the affix to the item

            bRet = true;
        end

        return bRet;
    end,
    removeAffix = function(this, cdat, oAffix)
        validateAffix(oAffix);

    end,


--TODO COMPLETE THESE
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
