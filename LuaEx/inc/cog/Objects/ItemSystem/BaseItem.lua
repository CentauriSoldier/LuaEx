--LOCALIZATION
local class = class;
local Persistence = require("LuaEx.inc.cog.Objects.ItemSystem.ItemPersistence");
local Rules = require("LuaEx.inc.cog.Objects.ItemSystem.ItemRules");

-- Build each permission method around its named registry, passing this item as additional context.
local function permission(sField)

    return function(this, cdat, oObject, ...)
        return cdat.pro[sField].allows(oObject, this, ...);
    end;
end

-- Create an independent default when omitted; retain a validated supplied component by identity.
local function acceptObject(vInput, cExpected, defaultFactory, sField)

    if (vInput == nil) then
        return defaultFactory();
    end

    assert(class.isinstance(vInput) and class.ischildorself(class.of(vInput), cExpected),
           "BaseItem "..sField.." must be an instance of "..class.getname(cExpected)..".");

    return vInput;
end

-- Start action permissions empty so callers explicitly choose eligible actors or hosts.
local function defaultObjectRegistry()

    return ObjectRegistry();
end

-- Create an independent empty storage/conflict registry.
local function defaultRegistry()

    return CoGRegistry();
end

-- Create an independent durability pool initially filled to its capacity of one.
local function defaultDurability()

    return Pool(1, 1);
end

-- Create a separate pool initially holding zero for each size, weight or value component.
local function defaultQuantity()

    return Pool(1, 0);
end

-- Create an independent empty footprint.
local function defaultSlotPattern()

    return SlotPattern();
end

--[[!
    @fqxn CoG.ItemSystem.BaseItem
    @desc Base class for individual items. ObjectRegistry action permissions and CoGRegistry storage/conflict fields express eligibility;
    callers perform actions and enforce their gameplay consequences. Durability
    reaching zero does not imply destruction. Inimitable is metadata only.
    Every omitted registry/Pool/SlotPattern input creates a fresh object in the constructor;
    validated supplied objects are retained by reference. Stacking belongs to
    ItemSlot. Trading also covers selling; callers determine cost from Value.
!]]
local cBaseItem = class("BaseItem",
{--METAMETHODS

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.__clone
        @desc Requires callers to choose how concrete items are cloned before populating another container.
    !]]
    __clone = function(this, cdat)

        --TODO Define copying of subclass state, attachments and BaseObject affixes.
        -- Inimitable is deliberately not enforced here.
        error("BaseItem subclasses must implement __clone for their item state.");
    end,

},
{--STATIC PUBLIC

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.eachAttachmentOf
        @desc Validates a CoG host and iterates a copied list of its attached item references.
    !]]
    eachAttachmentOf = function(oHost)
        assert(class.isinstance(oHost) and class.ischildorself(class.of(oHost), CoG), "Attachment host must be a CoG instance.");

        return ipairs(Rules.attachments(oHost));
    end,

},
{--PRIVATE
    location = {}, -- Optional reference can change between unrelated container classes.
    attachment = {},
    attachedItems = {}, -- Forward attachment membership retained in generated snapshots.
    identity = {}, -- Runtime self reference used to discover the concrete subclass when saving.
    persistenceID = 0,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.validateSnapshot
        @desc Validates saved identity and attachment/location holders before generated class restoration.
    !]]
    validateSnapshot = function(tState)
        Rules.integer(tState.pri.persistenceID, 1);
        type.assert.table(tState.pri.attachedItems);
        type.assert.table(tState.pri.location);
        type.assert.table(tState.pri.attachment);
        assert(type.isnull(tState.pri.location.value) or class.isinstance(tState.pri.location.value), "Invalid saved item location.");
        assert(type.isnull(tState.pri.attachment.host) or type.isCoG(tState.pri.attachment.host), "Invalid saved attachment host.");
    end,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.prepareSnapshot
        @desc Registers the concrete item adapter, wraps permission registries and omits inverse links from the
        copied snapshot.
    !]]
    prepareSnapshot = function(tState)
        local pri = tState.pri;

        -- A concrete subclass may be local; register its existing generated deserializer.
        Rules.registerPersistence(class.of(pri.identity.object), true);

        -- Wrap registries so saved prerequisites survive the class snapshot's method-field exclusions.
        for sField, vValue in pairs(tState.pro) do
            if (type.isCoGRegistry(vValue) or type.isObjectRegistry(vValue)) then
                tState.pro[sField] = Persistence.registry(vValue);
            end
        end

        -- Save forward membership only: containers own items and hosts own attached children.
        -- Reconnection reconstructs these omitted inverse links instead of serializing object cycles.
        pri.identity = nil;
        pri.location.value = null;
        pri.attachment.host = null;
    end,
},
{--PROTECTED
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getAttachable_To
        @pulsarlua function BaseItem.getAttachable_To
        @desc Returns the Attachable_To component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Attachable_To__autoA_    = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getConsumable_By
        @pulsarlua function BaseItem.getConsumable_By
        @desc Returns the Consumable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Consumable_By__autoA_    = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getDamageable_By
        @pulsarlua function BaseItem.getDamageable_By
        @desc Returns the Damageable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Damageable_By__autoA_    = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getDetachable_By
        @pulsarlua function BaseItem.getDetachable_By
        @desc Returns the Detachable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Detachable_By__autoA_    = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getEquipable_By
        @pulsarlua function BaseItem.getEquipable_By
        @desc Returns the Equipable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Equipable_By__autoA_     = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getExclusive_In
        @pulsarlua function BaseItem.getExclusive_In
        @desc Returns the Exclusive_In component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret CoGRegistry vValue Stored value/reference.
    !]]
    Exclusive_In__autoA_    = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getExclusive_With
        @pulsarlua function BaseItem.getExclusive_With
        @desc Returns the Exclusive_With component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret CoGRegistry vValue Stored value/reference.
    !]]
    Exclusive_With__autoA_  = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.isInimitable
        @pulsarlua function BaseItem.isInimitable
        @desc Returns the Inimitable component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret boolean vValue Stored value/reference.
    !]]
    Inimitable__autoA_is    = false,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getRemovable_By
        @pulsarlua function BaseItem.getRemovable_By
        @desc Returns the Removable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Removable_By__autoA_    = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getRepairable_By
        @pulsarlua function BaseItem.getRepairable_By
        @desc Returns the Repairable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Repairable_By__autoA_   = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getStorable_In
        @pulsarlua function BaseItem.getStorable_In
        @desc Returns the Storable_In component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret CoGRegistry vValue Stored value/reference.
    !]]
    Storable_In__autoA_     = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getTradable_By
        @pulsarlua function BaseItem.getTradable_By
        @desc Returns the Tradable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Tradable_By__autoA_     = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getTradable_To
        @pulsarlua function BaseItem.getTradable_To
        @desc Returns the Tradable_To component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Tradable_To__autoA_     = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getUnequippable_By
        @pulsarlua function BaseItem.getUnequippable_By
        @desc Returns the Unequippable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Unequippable_By__autoA_ = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getUpgradeable_By
        @pulsarlua function BaseItem.getUpgradeable_By
        @desc Returns the Upgradeable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Upgradeable_By__autoA_  = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getDowngradable_By
        @pulsarlua function BaseItem.getDowngradable_By
        @desc Returns the Downgradable_By component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret ObjectRegistry vValue Stored value/reference.
    !]]
    Downgradable_By__autoA_ = null,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getDurability
        @pulsarlua function BaseItem.getDurability
        @desc Returns the Durability component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret Pool vValue Stored value/reference.
    !]]
    Durability__autoA_      = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getSize
        @pulsarlua function BaseItem.getSize
        @desc Returns the Size component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret Pool vValue Stored value/reference.
    !]]
    Size__autoA_            = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getValue
        @pulsarlua function BaseItem.getValue
        @desc Returns the Value component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret Pool vValue Stored value/reference.
    !]]
    Value__autoA_           = null,
    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getWeight
        @pulsarlua function BaseItem.getWeight
        @desc Returns the Weight component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret Pool vValue Stored value/reference.
    !]]
    Weight__autoA_          = null,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getSlot_Pattern
        @pulsarlua function BaseItem.getSlot_Pattern
        @desc Returns the Slot_Pattern component/value. Generated non-final getter; no replacement setter. Mutable components retain identity.
        @ret SlotPattern vValue Stored value/reference.
    !]]
    Slot_Pattern__autoA_    = null,

    --TODO Revisit blueprint identity and its relationship to item definitions.
    -- Container/attachment operations coordinate optional references. CoGRegistry
    -- and Pool replacement setters are deliberately not generated.

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.BaseItem
        @desc Protected constructor invoked by concrete item subclasses.
        Registry/Pool arguments are optional objects, never booleans or numbers.
        vExclusiveIn accepts a CoGRegistry or a particular supported system instance;
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

        -- Validate component inputs before publishing any of them as this item's fields.
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

        tFields.Exclusive_With = acceptObject(oExclusiveWith, CoGRegistry, defaultRegistry, "Exclusive_With");
        tFields.Storable_In = acceptObject(oStorableIn, CoGRegistry, defaultRegistry, "Storable_In");

        -- Default scopes match container classes. A supplied system instance narrows scope by identity.
        if (vExclusiveIn == nil) then
            tFields.Exclusive_In = CoGRegistry({ItemSlotSystem, ItemSystem, ItemStashSystem});
        elseif (class.isinstance(vExclusiveIn) and
                (class.ischildorself(class.of(vExclusiveIn), ItemSlotSystem) or
                 class.ischildorself(class.of(vExclusiveIn), ItemSystem) or
                 class.ischildorself(class.of(vExclusiveIn), ItemStashSystem))) then
            tFields.Exclusive_In = CoGRegistry({vExclusiveIn});
        else
            tFields.Exclusive_In = acceptObject(vExclusiveIn, CoGRegistry, defaultRegistry, "Exclusive_In");
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

        -- Construct inherited object state after the item-specific inputs have been checked.
        super(sName, sDescription, eRarity, wEventrix);

        for sField, oObject in pairs(tFields) do
            pro[sField] = oObject;
        end

        -- Hold inverse references inside tables so changing targets preserves each declared field type.
        pro.Inimitable = bInimitable == true;
        cdat.pri.attachment.host = oAttachedTo or null;
        cdat.pri.location.value = oLocation or null;
        cdat.pri.persistenceID = Persistence.identify(this);
        cdat.pri.identity.object = this;
        Rules.registerHost(this, cdat.pri.attachedItems);
        Rules.registerAttachment(this, cdat.pri.attachment);
    end,

},
{--PUBLIC

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.restoreItemRuntime
        @desc Internal save/load reconnection of location and attachment indexes.
        Membership restores exact decoded identities without permission callbacks.
    !]]
    restoreItemRuntime__FNL = function(this, cdat, tToken)

        -- Load tokens isolate identity reconnection between independent deserialization operations.
        if (tToken) then
            Persistence.reconnect(cdat.pri.persistenceID, this, tToken);
        end

        cdat.pri.persistenceID = Persistence.identify(this);
        cdat.pri.identity.object = this;
        Rules.registerHost(this, cdat.pri.attachedItems, tToken);
        Rules.registerAttachment(this, cdat.pri.attachment);

        -- Repeated reconnection must not insert this item into the same location twice.
        local oLocation = cdat.pri.location.value;

        if (oLocation ~= null) then
            oLocation.restoreRuntime();
            local tState = Rules.state(oLocation);

            if (not Rules.indexOf(oLocation, this)) then
                tState.items[#tState.items + 1] = this;
            end
        end
    end,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canAttachTo
        @desc Checks the Attachable_To registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canAttachTo = permission("Attachable_To"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canConsumeBy
        @desc Checks the Consumable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canConsumeBy = permission("Consumable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canDamageBy
        @desc Checks the Damageable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canDamageBy = permission("Damageable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canDetachBy
        @desc Checks the Detachable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canDetachBy = permission("Detachable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canEquipBy
        @desc Checks the Equipable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canEquipBy = permission("Equipable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canRemoveBy
        @desc Checks the Removable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canRemoveBy = permission("Removable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canRepairBy
        @desc Checks the Repairable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canRepairBy = permission("Repairable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canStoreIn
        @desc Checks the Storable_In registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canStoreIn = permission("Storable_In"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canTradeBy
        @desc Checks the Tradable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canTradeBy = permission("Tradable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canTradeTo
        @desc Checks the Tradable_To registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canTradeTo = permission("Tradable_To"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canUnequipBy
        @desc Checks the Unequippable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canUnequipBy = permission("Unequippable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canUpgradeBy
        @desc Checks the Upgradeable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canUpgradeBy = permission("Upgradeable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.canDowngradeBy
        @desc Checks the Downgradable_By registry with (oObject, this, ...); returns its boolean and optional
        reason.
    !]]
    canDowngradeBy = permission("Downgradable_By"),

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getAttached_To
        @desc Returns this item's attachment host, or null when detached.
    !]]
    getAttached_To__FNL = function(this, cdat)
        return cdat.pri.attachment.host;
    end,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.eachAttachment
        @desc Iterates a copied list of items attached to this item.
    !]]
    eachAttachment = function(this)
        return ipairs(Rules.attachments(this));
    end,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.attachTo
        @desc Checks attachment permission and cycle rules before connecting this item to the host.
    !]]
    attachTo = function(this, cdat, oHost)
        local bOK, sReason = Rules.attach(this, oHost);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.detach
        @desc Checks the actor's detach permission before removing this item from its current host.
    !]]
    detach = function(this, cdat, oActor)
        local bOK, sReason = Rules.detach(this, oActor);

        return this, bOK, sReason;
    end,

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.getLocation
        @desc Returns the current leaf container, or null while the item is not stored.
    !]]
    getLocation__FNL = function(this, cdat)
        return cdat.pri.location.value;
    end,

    -- Coordinated container operations pass the expected previous location.

    --[[!
        @fqxn CoG.ItemSystem.BaseItem.Methods.setLocation
        @desc Changes the location only when the expected previous identity matches; transactions control writes
        during callbacks.
    !]]
    setLocation__FNL = function(this, cdat, oLocation, oExpectedLocation)
        assert(Rules.canWriteLocation(), "Location mutations are forbidden inside prerequisite callbacks.");
        assert(oLocation == null or class.isinstance(oLocation), "Location must be a class instance or null.");

        -- Refuse to overwrite a location whose exact identity changed since the operation began.
        assert(rawequal(cdat.pri.location.value, oExpectedLocation), "Item location changed; transfer rejected.");
        cdat.pri.location.value = oLocation;

        return this;
    end,

},
BaseObject, --extending class
false,      --if the class is final
nil         --interface(s)
);

return cBaseItem;

--[[!
    @fqxn CoG.ItemSystem.BaseItem.InheritedBaseObject
    @inheritdoc CoG.BaseObject
!]]
