--LOCALIZATION
local class = class;
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

local function permission(sField)
    return function(this, cdat, oObject, ...)
        return cdat.pro[sField].allows(oObject, this, ...);
    end;
end

local function acceptObject(vInput, cExpected, fDefault, sField)

    if (vInput == nil) then
        return fDefault();
    end

    assert(class.isinstance(vInput) and class.ischildorself(class.of(vInput), cExpected),
           "BaseItem "..sField.." must be an instance of "..class.getname(cExpected)..".");
    return vInput;
end

local function defaultObjectRegistry()
    return ObjectRegistry();
end

local function defaultRegistry()
    return Registry();
end

local function defaultDurability()
    return Pool(1, 1);
end

local function defaultQuantity()
    return Pool(1, 0);
end

local function defaultSlotPattern()
    return SlotPattern();
end

--[[!
    @fqxn CoG.ItemSystem.BaseItem
    @desc Base class for individual items. Registry fields express eligibility;
    callers perform actions and enforce their gameplay consequences. Durability
    reaching zero does not imply destruction. Inimitable is metadata only.
    Every omitted registry/Pool/SlotPattern input creates a fresh object in the constructor;
    validated supplied objects are retained by reference. Stacking belongs to
    ItemSlot. Trading also covers selling; callers determine cost from Value.
!]]
return class("BaseItem",
{--METAMETHODS
    __clone = function(this, cdat)
        --TODO Define copying of subclass state, attachments and BaseObject affixes.
        -- Inimitable is deliberately not enforced here.
        error("BaseItem subclasses must implement __clone for their item state.");
    end,

},
{--STATIC PUBLIC
    eachAttachmentOf = function(oHost)
        assert(class.isinstance(oHost) and class.ischildorself(class.of(oHost), CoG), "Attachment host must be a CoG instance.");
        return ipairs(Rules.attachments(oHost));
    end,

},
{--PRIVATE
    location = {}, -- Optional reference can change between unrelated container classes.
    attachment = {},
},
{--PROTECTED
    Attachable_To__autoA_    = null,
    Consumable_By__autoA_    = null,
    Damageable_By__autoA_    = null,
    Detachable_By__autoA_    = null,
    Equipable_By__autoA_     = null,
    Exclusive_In__autoA_    = null,
    Exclusive_With__autoA_  = null,
    Inimitable__autoA_is    = false,
    Removable_By__autoA_    = null,
    Repairable_By__autoA_   = null,
    Storable_In__autoA_     = null,
    Tradable_By__autoA_     = null,
    Tradable_To__autoA_     = null,
    Unequippable_By__autoA_ = null,
    Upgradeable_By__autoA_  = null,
    Downgradable_By__autoA_ = null,

    Durability__autoA_      = null,
    Size__autoA_            = null,
    Value__autoA_           = null,
    Weight__autoA_          = null,

    Slot_Pattern__autoA_    = null,

    --TODO Revisit blueprint identity and its relationship to item definitions.
    -- Container/attachment operations coordinate optional references. Registry
    -- and Pool replacement setters are deliberately not generated.

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.BaseItem
        @desc Protected constructor invoked by concrete item subclasses.
        Registry/Pool arguments are optional objects, never booleans or numbers.
        vExclusiveIn accepts a Registry or a particular supported system instance;
        omission includes slot systems, inventories and stashes. Other registries start empty.
        Location and Attached_To accept class instances or null/nil; omitted values
        remain null. Attached_To identifies one CoG host. Inimitable defaults false.
    !]]
    BaseItem = function(this, cdat, super, sName, sDescription, eRarity, wEventrix,
                        oAttachableTo, oConsumableBy, oDamageableBy, oDetachableBy,
                        oEquipableBy, vExclusiveIn, oExclusiveWith, bInimitable,
                        oRemovableBy, oRepairableBy, oStorableIn,
                        oTradableBy, oTradableTo, oUnequippableBy,
                        oUpgradeableBy, oDowngradableBy,
                        oDurability, oSize, oValue, oWeight,
                        oAttachedTo, oLocation, oSlotPattern)
        local pro = cdat.pro;
        local tFields = {};
        local tObjectRegistries = {
            {"Attachable_To", oAttachableTo}, {"Consumable_By", oConsumableBy},
            {"Damageable_By", oDamageableBy}, {"Detachable_By", oDetachableBy},
            {"Equipable_By", oEquipableBy}, {"Removable_By", oRemovableBy},
            {"Repairable_By", oRepairableBy}, {"Tradable_By", oTradableBy},
            {"Tradable_To", oTradableTo}, {"Unequippable_By", oUnequippableBy},
            {"Upgradeable_By", oUpgradeableBy}, {"Downgradable_By", oDowngradableBy},
        };

        for _, tField in ipairs(tObjectRegistries) do
            tFields[tField[1]] = acceptObject(tField[2], ObjectRegistry, defaultObjectRegistry, tField[1]);
        end

        tFields.Exclusive_With = acceptObject(oExclusiveWith, Registry, defaultRegistry, "Exclusive_With");
        tFields.Storable_In = acceptObject(oStorableIn, Registry, defaultRegistry, "Storable_In");

        if (vExclusiveIn == nil) then
            tFields.Exclusive_In = Registry({ItemSlotSystem, ItemSystem, ItemStashSystem});
        elseif (class.isinstance(vExclusiveIn) and
                (class.ischildorself(class.of(vExclusiveIn), ItemSlotSystem) or
                 class.ischildorself(class.of(vExclusiveIn), ItemSystem) or
                 class.ischildorself(class.of(vExclusiveIn), ItemStashSystem))) then
            tFields.Exclusive_In = Registry({vExclusiveIn});
        else
            tFields.Exclusive_In = acceptObject(vExclusiveIn, Registry, defaultRegistry, "Exclusive_In");
        end

        tFields.Durability = acceptObject(oDurability, Pool, defaultDurability, "Durability");
        tFields.Size = acceptObject(oSize, Pool, defaultQuantity, "Size");
        tFields.Value = acceptObject(oValue, Pool, defaultQuantity, "Value");
        tFields.Weight = acceptObject(oWeight, Pool, defaultQuantity, "Weight");
        assert(bInimitable == nil or rawtype(bInimitable) == "boolean", "Inimitable must be a boolean or nil.");

        if (oAttachedTo ~= nil and oAttachedTo ~= null) then
            assert(class.isinstance(oAttachedTo) and class.ischildorself(class.of(oAttachedTo), CoG),
                   "Attached_To must be a CoG instance or null.");
        end

        if (oLocation ~= nil and oLocation ~= null) then
            assert(class.isinstance(oLocation), "Location must be a class instance or null.");
        end

        tFields.Slot_Pattern = acceptObject(oSlotPattern, SlotPattern, defaultSlotPattern, "Slot_Pattern");
        super(sName, sDescription, eRarity, wEventrix);

        for sField, oObject in pairs(tFields) do
            pro[sField] = oObject;
        end

        pro.Inimitable = bInimitable == true;
        cdat.pri.attachment.host = oAttachedTo or null;
        cdat.pri.location.value = oLocation or null;
        Rules.registerAttachment(this, oAttachedTo or null, function(oHost)
            cdat.pri.attachment.host = oHost;
        end);
    end,

},
{--PUBLIC
    canAttachTo = permission("Attachable_To"),
    canConsumeBy = permission("Consumable_By"),
    canDamageBy = permission("Damageable_By"),
    canDetachBy = permission("Detachable_By"),
    canEquipBy = permission("Equipable_By"),
    canRemoveBy = permission("Removable_By"),
    canRepairBy = permission("Repairable_By"),
    canStoreIn = permission("Storable_In"),
    canTradeBy = permission("Tradable_By"),
    canTradeTo = permission("Tradable_To"),
    canUnequipBy = permission("Unequippable_By"),
    canUpgradeBy = permission("Upgradeable_By"),
    canDowngradeBy = permission("Downgradable_By"),

    getAttached_To__FNL = function(this, cdat)
        return cdat.pri.attachment.host;
    end,

    eachAttachment = function(this)
        return ipairs(Rules.attachments(this));
    end,

    attachTo = function(this, cdat, oHost)
        local bOK, sReason = Rules.attach(this, oHost);
        return this, bOK, sReason;
    end,

    detach = function(this, cdat, oActor)
        local bOK, sReason = Rules.detach(this, oActor);
        return this, bOK, sReason;
    end,

    getLocation__FNL = function(this, cdat)
        return cdat.pri.location.value;
    end,

    -- Coordinated container operations pass the expected previous location.
    setLocation__FNL = function(this, cdat, oLocation, oExpectedLocation)
        assert(Rules.canWriteLocation(), "Location mutations are forbidden inside prerequisite callbacks.");
        assert(oLocation == null or class.isinstance(oLocation), "Location must be a class instance or null.");
        assert(rawequal(cdat.pri.location.value, oExpectedLocation), "Item location changed; transfer rejected.");
        cdat.pri.location.value = oLocation;
        return this;
    end,

},
BaseObject, --extending class
false,      --if the class is final
nil         --interface(s)
);
