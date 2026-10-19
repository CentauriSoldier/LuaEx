--LOCALIZATION
local class = class;

-- Configuration defines the slot names; instances own separate slot tables.
local _eComponent = enum("BaseVehicle.COMPONENT", luaex.cog.config.BaseVehicle.COMPONENT, nil, true);

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle.Helpers.componentName
    @scope local
    @desc Resolves an exact configured name or this class's component enum member.
    Unknown names and foreign enum members raise an error before mutation.
    @param string|BaseVehicle.COMPONENT vComponent The component slot.
    @ret string sName The configured name.
!]]
local function componentName(vComponent)
    local sName;

    if (_eComponent.__hasa(vComponent)) then
        sName = vComponent.name;
    elseif (rawtype(vComponent) == "string") then

        for _, eComponent in _eComponent() do

            if (vComponent == eComponent.name) then
                sName = vComponent;
                break;
            end

        end

    end

    assert(sName ~= nil, "Unknown BaseVehicle component slot.");

    return sName;
end

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle.Helpers.validateComponent
    @scope local
    @desc Requires a LuaEx class instance or null for an empty component slot.
    @param any oComponent The component to validate.
!]]
local function validateComponent(oComponent)
    assert(type.isnull(oComponent) or class.isinstance(oComponent),
           "Vehicle components must be class instances or null.");
end

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle.Helpers.buildComponents
    @scope local
    @desc Creates independent slot storage and validates the complete initializer.
    Omitted slots contain null; supplied component objects retain identity.
    @param table|nil tComponents Configured names or enum members mapped to objects.
    @ret table tSlots New storage indexed by configured names.
!]]
local function buildComponents(tComponents)
    assert(tComponents == nil or type(tComponents) == "table", "Vehicle components must be a table or nil.");

    local tSlots = {};
    local tSeen = {};

    for _, eComponent in _eComponent() do
        tSlots[eComponent.name] = null;
    end

    for vComponent, oComponent in pairs(tComponents or {}) do
        local sName = componentName(vComponent);

        assert(not tSeen[sName], "Vehicle component slot supplied more than once: "..sName);
        validateComponent(oComponent);

        tSeen[sName] = true;
        tSlots[sName] = oComponent;
    end

    return tSlots;
end

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle.Helpers.validateNumber
    @scope local
    @desc Requires a finite nonnegative vehicle measurement or value.
    @param number nValue The number to validate.
    @param string sName The field name used in diagnostics.
!]]
local function validateNumber(nValue, sName)
    assert(rawtype(nValue) == "number" and nValue >= 0 and nValue < math.huge,
           "BaseVehicle "..sName.." must be a finite nonnegative number.");
end

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle.Helpers.booleanValue
    @scope local
    @desc Defaults omitted flags and validates supplied booleans, preserving false.
    @param boolean|nil bValue The supplied flag.
    @param boolean bDefault The default used only for nil.
    @param string sName The field name used in diagnostics.
    @ret boolean bValue The validated flag or its default.
!]]
local function booleanValue(bValue, bDefault, sName)
    assert(bValue == nil or rawtype(bValue) == "boolean", "BaseVehicle "..sName.." must be a boolean or nil.");

    if (bValue == nil) then
        return bDefault;
    end

    return bValue;
end

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle
    @desc Generic vehicle identity, fuel, measurements and configured component slots.
    Supplied Pools, components and owners retain identity. Omitted fuel and slot
    storage are independent per instance. Flags are metadata; movement, trading,
    quest rules and copying of concrete vehicles belong to the application.
!]]
return class("BaseVehicle",
{--METAMETHODS

    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.__clone
        @desc Rejects implicit copying. Concrete subclasses define how vehicle
        state, components, owners, affixes and runtime callbacks are copied.
        @throws Always; subclasses must provide their own __clone.
    !]]
    __clone = function()
        error("BaseVehicle subclasses must implement __clone for their vehicle state.");
    end,

},
{--STATIC PUBLIC

    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.COMPONENT
        @desc Configured component slot names, accepted alongside their exact strings.
    !]]
    COMPONENT = _eComponent,

},
{--PRIVATE
},
{--PROTECTED
    Components                 = {},    -- Configured names mapped to class instances or null.
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getDistancePerFuelUnit
        @pulsarlua function BaseVehicle.getDistancePerFuelUnit
        @desc Returns the stored DistancePerFuelUnit value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret number vValue Stored value/reference.
    !]]
    DistancePerFuelUnit__autoA_ = 0,     -- Nonnegative distance travelled per fuel unit.
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getExclusive
        @pulsarlua function BaseVehicle.getExclusive
        @desc Returns the stored Exclusive value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret boolean vValue Stored value/reference.
    !]]
    Exclusive__autoA_           = false,
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getFuel
        @pulsarlua function BaseVehicle.getFuel
        @desc Returns the stored Fuel value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret Pool vValue Stored value/reference.
    !]]
    Fuel__autoA_                = null,  -- Supplied Pool or an independent default Pool.
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getInimitable
        @pulsarlua function BaseVehicle.getInimitable
        @desc Returns the stored Inimitable value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret boolean vValue Stored value/reference.
    !]]
    Inimitable__autoA_          = false,
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getMaxSpeed
        @pulsarlua function BaseVehicle.getMaxSpeed
        @desc Returns the stored MaxSpeed value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret number vValue Stored value/reference.
    !]]
    MaxSpeed__autoA_            = 0,
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getOwner
        @pulsarlua function BaseVehicle.getOwner
        @desc Returns the stored Owner value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret object|null vValue Stored value/reference.
    !]]
    Owner__autoA_               = null,  -- Optional caller-owned class instance.
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getQuest
        @pulsarlua function BaseVehicle.getQuest
        @desc Returns the stored Quest value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret boolean vValue Stored value/reference.
    !]]
    Quest__autoA_               = false,
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getTradeable
        @pulsarlua function BaseVehicle.getTradeable
        @desc Returns the stored Tradeable value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret boolean vValue Stored value/reference.
    !]]
    Tradeable__autoA_           = true,
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getUnmanned
        @pulsarlua function BaseVehicle.getUnmanned
        @desc Returns the stored Unmanned value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret boolean vValue Stored value/reference.
    !]]
    Unmanned__autoA_            = false,
    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getValue
        @pulsarlua function BaseVehicle.getValue
        @desc Returns the stored Value value/reference. Generated non-final getter; no public replacement setter. Flags are caller-enforced metadata.
        @ret number vValue Stored value/reference.
    !]]
    Value__autoA_               = 0,
},
{--PUBLIC

    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.BaseVehicle
        @desc Validates vehicle inputs, initializes BaseObject, then stores the
        vehicle state. Owner and inherited metadata are optional trailing arguments.
        Only nil selects defaults. Fuel defaults to Pool(); numbers to zero;
        Tradeable to true; other flags to false. Tradeable covers selling as well
        as other trades. Component slots are case-sensitive.
        @param Pool|nil oFuel Fuel Pool or subclass instance, retained by reference.
        @param boolean|nil bUnmanned Whether the vehicle is unmanned.
        @param number|nil nDistancePerFuelUnit Finite nonnegative fuel efficiency.
        @param table|nil tComponents Configured names or enum members mapped to objects.
        @param number|nil nValue Finite nonnegative vehicle value.
        @param boolean|nil bTradeable Whether the vehicle can be traded, including sold.
        @param boolean|nil bQuest Whether the vehicle is quest-related.
        @param boolean|nil bExclusive Whether the vehicle is exclusive.
        @param boolean|nil bInimitable Caller-enforced copying metadata.
        @param number|nil nMaxSpeed Finite nonnegative maximum speed.
        @param object|null|nil oOwner Optional class instance; nil means null.
        @param string|nil sName Nonblank name, defaulting to Vehicle.
        @param string|nil sDescription Nonblank description, defaulting to A vehicle.
        @param Rarity.LEVEL|nil eRarity Rarity passed to BaseObject.
        @param string|nil sEventrixEnvironment Event environment name passed to BaseObject.
        @throws Invalid vehicle inputs or an inherited constructor error.
    !]]
    BaseVehicle = function(this, cdat, super, oFuel, bUnmanned, nDistancePerFuelUnit,
                          tComponents, nValue, bTradeable, bQuest,
                          bExclusive, bInimitable, nMaxSpeed, oOwner,
                          sName, sDescription, eRarity, sEventrixEnvironment)

        -- Validate the complete vehicle input before initializing inherited state.
        if (oFuel ~= nil) then
            assert(class.isinstance(oFuel) and class.ischildorself(class.of(oFuel), Pool),
                   "BaseVehicle Fuel must be a Pool instance.");
        end

        nDistancePerFuelUnit    = nDistancePerFuelUnit == nil and 0 or nDistancePerFuelUnit;
        nValue                  = nValue == nil and 0 or nValue;
        nMaxSpeed               = nMaxSpeed == nil and 0 or nMaxSpeed;

        validateNumber(nDistancePerFuelUnit,    "DistancePerFuelUnit");
        validateNumber(nValue,                  "Value");
        validateNumber(nMaxSpeed,               "MaxSpeed");

        bUnmanned   = booleanValue(bUnmanned,   false,  "Unmanned");
        bTradeable  = booleanValue(bTradeable,  true,   "Tradeable");
        bQuest      = booleanValue(bQuest,      false,  "Quest");
        bExclusive  = booleanValue(bExclusive,  false,  "Exclusive");
        bInimitable = booleanValue(bInimitable, false,  "Inimitable");

        local tSlots = buildComponents(tComponents);

        assert(oOwner == nil or type.isnull(oOwner) or class.isinstance(oOwner),
               "BaseVehicle Owner must be a class instance or null.");
        assert(sEventrixEnvironment == nil or rawtype(sEventrixEnvironment) == "string",
               "BaseVehicle event environment must be a name or nil.");

        sName           = sName == nil and "Vehicle" or sName;
        sDescription    = sDescription == nil and "A vehicle." or sDescription;

        super(sName, sDescription, eRarity, sEventrixEnvironment);

        -- Preserve supplied object identities and allocate defaults only when omitted.
        local pro = cdat.pro;

        pro.Components          = tSlots;
        pro.DistancePerFuelUnit = nDistancePerFuelUnit;
        pro.Exclusive           = bExclusive;
        pro.Fuel                = oFuel or Pool();
        pro.Inimitable          = bInimitable;
        pro.MaxSpeed            = nMaxSpeed;
        pro.Owner               = oOwner or null;
        pro.Quest               = bQuest;
        pro.Tradeable           = bTradeable;
        pro.Unmanned            = bUnmanned;
        pro.Value               = nValue;
    end,

    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getComponent
        @desc Returns the actual component in a configured slot, or null if empty.
        @param string|BaseVehicle.COMPONENT vComponent The configured slot.
        @ret object|null oComponent The stored reference or null.
    !]]
    getComponent = function(this, cdat, vComponent)
        return cdat.pro.Components[componentName(vComponent)];
    end,

    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.getComponents
        @desc Copies slot bindings while retaining component object identities.
        Editing the returned table does not change the vehicle's slot bindings.
        @ret table tComponents Configured names mapped to objects or null.
    !]]
    getComponents = function(this, cdat)
        local tComponents = {};

        for sName, oComponent in pairs(cdat.pro.Components) do
            tComponents[sName] = oComponent;
        end

        return tComponents;
    end,

    --[[!
        @fqxn CoG.VehicleSystem.BaseVehicle.Methods.setComponent
        @desc Validates the slot and object before replacing the binding. Nil or
        null clears a slot. Shared components are allowed; a binding does not
        confer exclusive ownership of the component object.
        @param string|BaseVehicle.COMPONENT vComponent The configured slot.
        @param object|null|nil oComponent A class instance or an empty-slot value.
        @ret BaseVehicle this The vehicle for chaining.
    !]]
    setComponent = function(this, cdat, vComponent, oComponent)
        local sName = componentName(vComponent);

        oComponent = oComponent == nil and null or oComponent;
        validateComponent(oComponent);

        cdat.pro.Components[sName] = oComponent;

        return this;
    end,

},
BaseObject,  --extending class
false,       --if the class is final
nil          --interfaces
);

--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle.InheritedBaseObject
    @inheritdoc CoG.BaseObject
!]]
