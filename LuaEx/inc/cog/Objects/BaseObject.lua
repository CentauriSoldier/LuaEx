return class("BaseObject",
{--METAMETHODS

},
{--STATIC PUBLIC
    --BaseObject = function(stapub) end,
},
{--PRIVATE
    affixRecords = {},
},
{--PROTECTED
    eventrix__RO            = null, --TODO move to pri?
    prefixes                = {},
    suffixes                = {},
    Name__autoA_            = "", --leave as non-final so subclasses can alter it but create a public accessor only
    Description__autoA_     = "",
},
{--PUBLIC
    BaseObject = function(this, cdat)

    end,
    applyAffix = function(this, cdat, oAffix, eEventID, wEnv, ...)
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
            --apply the affix to the object
            local tEvents = oAffix.onApply(this, ...);

            if (type(tEvents) == "table") then
                local oEventrix     = pro.Eventrix;
                local tAffixRecords   = cdat.pri.affixRecords;

                --create the affix record table if it doesn't exist
                if (tAffixRecord[oAffix] == nil) then
                    tAffixRecord[oAffix] = {};
                end

                local tRecord = tAffixRecord[oAffix];

                for eEventID, fHook in pairs(tEvents) do

                    if (type(eEventID) == "enumitem" and type(fHook) == "function") then

                        if (tRecord[eEventID] == nil) then
                            tRecord[eEventID] = {};
                        end

                        --record the hook addition
                        tRecord[eEventID][fHook] = true;
                        --add the hook
                        oEventrix.addHook(eEventID, fHook, wEnv);
                    end

                end

            end

            bRet = true;
        end

        return bRet;
    end,
    fireEvent = function(this, cdat, eEventID)

    end,
    removeAffix = function(this, cdat, oAffix, ...)
        local oEventrix     = cdat.pro.eventrix;
        local tAffixRecords = cdat.pri.affixRecords;
        validateAffix(oAffix);

        if (tAffixRecords[oAffix] ~= nil) then
            local tRecord = tAffixRecords[oAffix];

            --remove the hooks from the eventrix
            for eEventID, tHooks in pairs(tRecord) do

                for fHook, _ in pairs(tHooks) do
                    oEventrix.removeHook(eEventID, fHook);
                end

            end

            --destroy the affix's record
            tAffixRecords[oAffix] = nil;

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
