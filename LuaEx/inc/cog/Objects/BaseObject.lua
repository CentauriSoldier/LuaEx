local function validateAffix(vAffix)
    local cAffix = class.of(vAffix);

    if not (cAffix) then
        error("Error in modifying Item with affix.\nAffix must be an instance of a class. Got type "..type(vAffix)..".", 2);
    end

    if not (class.ischildorself(cAffix, Affix)) then
        error("Error in modifying Item with affix.\nAffix must be an instance of an Affix subclass.", 2);
    end
end

return class("BaseObject",
{--METAMETHODS

},
{--STATIC PUBLIC
    BaseObject = function(stapub)
        --stapub.RARITY = enum("BaseObject.RARITY", tRarity.rarity, tRarity.colors, true);
    end,
},
{--PRIVATE
    affixDisplayOrder   = {},
    eventrix__RO        = null,
    affixHooks          = {},   --used to store hooks (for removal)
    affixes             = {},   --used for quick, existential checks and type checks
    orderedPrefixes     = {},   --used for setting display order
    orderedSuffixes     = {},   --used for setting display order
},
{--PROTECTED
    Description__autoA_     = "",
    Name__autoA_            = "", --leave as non-final so subclasses can alter it but create a public accessor only
    Rarity__auto__          = false,
    TagSystem__autoAF       = null,
    
    BaseObject = function(this, cdat, sName, sDescription, eRarity, wEventrix)
        local pri = cdat.pri;
        local pro = cdat.pro;
        type.assert.string(sName, "%S+");
        type.assert.string(sDescription, "%S+");

        pri.Eventrix    = eventrix(wEventrix); --TODO clone these?

        pro.Name        = sName;
        pro.Description = sDescription;
        pro.Rarity      = type(eRarity) == "Rarity.LEVEL" and eRarity or _eRarity[1];

        pro.TagSystem   = TagSystem();
    end,
},
{--PUBLIC
    --[[!
    @fqxn CoG.BaseObject.Methods.ApplyAffix
    @des stuff
    !]]
    applyAffix__FNL = function(this, cdat, oAffix, eEventID, wEnv, ...)
        local bRet      = false;
        local pri       = cdat.pri;
        local pro       = cdat.pro;
        local tAffixes  = pri.affixes;

        validateAffix(oAffix);

        if (tAffixes[oAffix] == nil) then
            local eType             = Affix.TYPE;
            local eAffixType        = oAffix.getType();
            local eAffixTier        = oAffix.getTier();
            local bIsPrefix         = eAffixType == eType.PREFIX;

            local eRarity           = pro.Rarity;
            local eMaxTier          = Rarity.getMaxTier(eRarity);

            local nMaxAffixes       = bIsPrefix and
                                      Rarity.getPrefixCount(eRarity) or
                                      Rarity.getSuffixCount(eRarity);
            local tSortedAffixes    = bIsPrefix and pri.prefixes or pri.suffixes;

            if (#tAffixes < nMaxAffixes and
                eAffixTier <= eMaxTier  and
                oAffix.isCompatibleWithClass(class.of(this))) then

                --log the affix type and store it for checks
                tAffixes[oAffix] = eAffixType;

                -- TODO FINISH proper sorting
                tSortedAffixes[#tSortedAffixes + 1] = oAffix;

                --apply the affix to the object
                local tEvents = oAffix.onApply(this, ...);

                if (type(tEvents) == "table") then
                    local oEventrix   = pri.Eventrix;
                    local tAffixHooks = pri.affixHooks;

                    --create the affix hook record table if it doesn't exist
                    if (tAffixHooks[oAffix] == nil) then
                        tAffixHooks[oAffix] = {};
                    end

                    local tHookRecord = tAffixHooks[oAffix];

                    for eEventID, fHook in pairs(tEvents) do

                        if (type(eEventID) == "enumitem" and type(fHook) == "function") then

                            if (tHookRecord[eEventID] == nil) then
                                tHookRecord[eEventID] = {};
                            end

                            --record the hook addition
                            tHookRecord[eEventID][fHook] = true;

                            --add the hook to the eventrix
                            oEventrix.addHook(eEventID, fHook, wEnv);
                        end

                    end

                end

                bRet = true;
            end

        end

        return bRet;
    end,
    fireEvent__FNL = function(this, cdat, eEventID, ...)
        return cdat.pri.eventrix.fire(eEventID, ...);
    end,
    removeAffix__FNL = function(this, cdat, oAffix, ...)
        local pri           = cdat.pri;

        validateAffix(oAffix);

        if (tAffixes[oAffix] ~= nil) then
            local oEventrix         = pri.eventrix;
            local eAffixType        = oAffix.getType()
            local tAffixes          = pri.affixes;
            local tAffixHooks       = pri.affixHooks;
            local tSortedAffixes    = eAffixType == Affix.TYPE.PREFIX and
                                      pri.sortedPrefixes or pri.sortedSuffixes;

            local tHookRecord = tAffixHooks[oAffix];

            --remove the hooks from the eventrix
            for eEventID, tHooks in pairs(tHookRecord) do

                for fHook, _ in pairs(tHooks) do
                    oEventrix.removeHook(eEventID, fHook);
                end

            end

            --destroy the affix's hook record
            tAffixHooks[oAffix] = nil;

            --remove the affix from the quick access table
            tAffixes[oAffix] = nil;

            --call affix's remove method
            oAffix.onRemove(this, ...);
        end

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
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
