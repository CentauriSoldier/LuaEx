local _tMaster = {
    forbidden = {
        "class"
    },
    required = {
        id   = {"string"},
        name = {"string"},
    },
};

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
    @fqxn CoG.BaseObject
    @desc Shared CoG object metadata, tags and event dispatch. Concrete subclasses call the protected constructor.
    Names and descriptions must contain non-whitespace text. Rarity falls back to the first configured level.
    <ul>
    <li>getName() and getDescription() expose protected strings; no replacement setters are generated.</li>
    <li>getRarity()/setRarity(eRarity) expose the rarity property through generated accessors.</li>
    <li>getTagSystem() is final and returns the mutable per-object TagSystem; no replacement setter is generated.</li>
    <li>fireEvent(eEventID, ...) is final and delegates to this object's eventrix.</li>
    <li>applyAffix(oAffix, ...) and removeAffix(oAffix, ...) are final, unfinished affix operations; see their limitations below.</li>
    <li>getMaxPrefixes()/getMaxSuffixes() currently read undeclared private fields; they are unfinished.</li>
    </ul>
    @note Affix sorting/storage is unfinished. This class does not currently provide a complete safe affix lifecycle.
!]]
return class("BaseObject",
{--METAMETHODS

},
{--STATIC PUBLIC
    BaseObject = function(stapub)
        --stapub.RARITY = enum("BaseObject.RARITY", tRarity.rarity, tRarity.colors, true);
    end,
},
{--PRIVATE
    eventrix            = null,
    affixDisplayOrder   = {},
    affixHooks          = {},   --used to store hooks (for removal)
    affixes             = {},   --used for quick, existential, count and type checks
    orderedPrefixes     = {},   --used for setting display order
    orderedSuffixes     = {},   --used for setting display order
},
{--PROTECTED
    eventrix__RO            = null,
    --[[!
        @fqxn CoG.BaseObject.Methods.getDescription
        @pulsarlua function BaseObject.getDescription
        @desc Returns the stored description. Generated non-final getter; no public setter.
        @ret string vValue Stored value/reference.
    !]]
    Description__autoA_     = "",
    --[[!
        @fqxn CoG.BaseObject.Methods.getName
        @pulsarlua function BaseObject.getName
        @desc Returns the stored name. Generated non-final getter; no public setter.
        @ret string vValue Stored value/reference.
    !]]
    Name__autoA_            = "", --leave as non-final so subclasses can alter it but create a public accessor only
    --[[!
        @fqxn CoG.BaseObject.Methods.getRarity
        @pulsarlua function BaseObject.getRarity
        @desc Returns the current rarity reference. Generated non-final getter.
        @ret Rarity.LEVEL vValue Stored value/reference.
    !]]
    --[[!
        @fqxn CoG.BaseObject.Methods.setRarity
        @pulsarlua function BaseObject.setRarity
        @desc Generated setter. Assigns through the class field's type rules; it does not repeat the constructor's membership fallback.
        @param Rarity.LEVEL eRarity Replacement rarity.
        @ret BaseObject this This object.
    !]]
    Rarity__auto__          = null,
    --[[!
        @fqxn CoG.BaseObject.Methods.getTagSystem
        @pulsarlua function BaseObject.getTagSystem
        @desc Returns the mutable tag component by reference. Final getter; no replacement setter.
        @ret TagSystem vValue Stored value/reference.
    !]]
    TagSystem__autoAF       = null,
    --[[!
    @fqxn CoG.BaseObject.Methods.BaseObject
    @desc Protected constructor. Creates a fresh eventrix and TagSystem after validating the name and description.
    @param string sName The name of the object.
    @param string sDescription The description of the object.
    @param Rarity.LEVEL|nil eRarity Configured rarity member; other values use Rarity.LEVEL[1].
    @param string|nil wEventrix Optional registered event environment name.
    @throws Blank/non-string metadata or inherited/eventrix initialization errors.
    !]]
    BaseObject = function(this, cdat, super, sName, sDescription, eRarity, wEventrix)
        local pri = cdat.pri;
        local pro = cdat.pro;
        type.assert.string(sName, "%S+");
        type.assert.string(sDescription, "%S+");

        super();
        pri.eventrix   = eventrix(wEventrix); --TODO clone these?
        pro.eventrix   = pri.eventrix;

        pro.Name        = sName;
        pro.Description = sDescription;
        pro.Rarity      = Rarity.LEVEL.__hasa(eRarity) and eRarity or Rarity.LEVEL[1];

        pro.TagSystem   = TagSystem();
    end,
},
{--PUBLIC
    --[[!
    @fqxn CoG.BaseObject.Methods.ApplyAffix
    @pulsarlua function BaseObject.applyAffix
    @desc Applies a compatible affix within the configured rarity limit.
          Tier limits compare enum ordinals, including tiers with nested payloads.
    @param Affix oAffix Affix subclass instance, validated before use.
    @param varargs ... Arguments forwarded to onApply.
    @ret boolean bApplied True after application; false if already present or rejected.
    @note Incomplete: sorting selects undeclared prefixes/suffixes tables. An otherwise eligible affix can raise an error after its membership entry has been recorded. Do not rely on atomic application.
    !]]
    applyAffix__FNL = function(this, cdat, oAffix, ...)--, eEventID, wEnv, ...)
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
            local eMaxAffixTier     = Rarity.getMaxAffixTier(eRarity);

            local nMaxAffixes       = bIsPrefix and
                                      Rarity.getPrefixCount(eRarity) or
                                      Rarity.getSuffixCount(eRarity);
            local tSortedAffixes    = bIsPrefix and pri.prefixes or pri.suffixes;

            if (#tAffixes < nMaxAffixes and
                eAffixTier.id <= eMaxAffixTier.id  and
                oAffix.isCompatibleWithClass(class.of(this))) then
                local sEnv = oAffix.getEnvironment();

                --log the affix type and store it for checks
                tAffixes[oAffix] = eAffixType;

                -- TODO FINISH proper sorting
                tSortedAffixes[#tSortedAffixes + 1] = oAffix;

                --apply the affix to the object
                local tEvents = oAffix.onApply(this, ...);

                if (type(tEvents) == "table") then
                    local oEventrix   = pri.eventrix;
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
                            oEventrix.addHook(eEventID, fHook, sEnv);
                        end

                    end

                end

                bRet = true;
            end

        end

        return bRet;
    end,
    --[[!
        @fqxn CoG.BaseObject.Methods.fireEvent
        @pulsarlua function BaseObject.fireEvent
        @desc Dispatches an event through this object's eventrix. Final method.
        @param enumitem eEventID Event identifier.
        @param varargs ... Arguments forwarded to hooks.
        @ret table tResults Hook results/errors, as returned by eventrix.fire.
    !]]
    fireEvent__FNL = function(this, cdat, eEventID, ...)
        return cdat.pri.eventrix.fire(eEventID, ...);
    end,
    --[[!
        @fqxn CoG.BaseObject.Methods.removeAffix
        @pulsarlua function BaseObject.removeAffix
        @desc Intended to unregister hooks and call onRemove for an affix. Final method; implementation is unfinished.
        @param Affix oAffix Affix subclass instance.
        @param varargs ... Arguments intended for onRemove.
        @ret nil No explicit return.
        @note References tAffixes before its local declaration and uses undeclared sorted-prefix/suffix state. With no external tAffixes binding, removal raises an error. This is not a working removal guarantee.
    !]]
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
    --[[
    @fqxn CoG.Affix System.Affixory.Methods.getMaxPrefixes
    @desc Gets the maximum number of prefixes this container can hold.
    @ret int nMaxPrefixes The maximum number of prefixes.
    ]]
    --[[!
        @fqxn CoG.BaseObject.Methods.getMaxPrefixes
        @pulsarlua function BaseObject.getMaxPrefixes
        @desc Placeholder accessor reading an undeclared private field. This is not a working configured-limit API.
        @note This class does not initialize the referenced field.
    !]]
    getMaxPrefixes = function(this, cdat)
        return cdat.pri.maxPrefixes;
    end,
    --[[
    @fqxn CoG.Affix System.Affixory.Methods.getMaxSuffixes
    @desc Gets the maximum number of suffixes this container can hold.
    @ret int nMaxSuffixes The maximum number of suffixes.
    ]]
    --[[!
        @fqxn CoG.BaseObject.Methods.getMaxSuffixes
        @pulsarlua function BaseObject.getMaxSuffixes
        @desc Placeholder accessor reading an undeclared private field. This is not a working configured-limit API.
        @note This class does not initialize the referenced field.
    !]]
    getMaxSuffixes = function(this, cdat)
        return cdat.pri.maxSuffixes;
    end,
},
CoG,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
