-- The example owns movement and copying policy; BaseVehicle supplies storage.
local _cBaseVehicle = BaseVehicle or require("LuaEx.inc.cog.Objects.VehicleSystem.BaseVehicle");
local _eEvent       = enum("ExampleGarageVehicleEvent", {"INSPECTION"}, nil, true);
local _cVehicle;

-- Named event environments are registered once per Lua session.
envrepo.ExampleGarageWorkshop = {VEHICLE_ENV_LABEL = "Workshop environment"};

--[[!
    @fqxn Examples.Vehicles.Vehicle
    @desc A concrete example vehicle. Fuel and component objects are copied;
    the owner remains shared. Flags are metadata, including Inimitable.
    Affixes and runtime hooks are intentionally outside this example's policy.
!]]
_cVehicle = class("ExampleGarageVehicle",
{
    --[[!
        @fqxn Examples.Vehicles.Vehicle.__clone
        @desc Copies the supported vehicle state into a fresh concrete instance.
        @ret ExampleGarageVehicle oCopy An independent vehicle with a shared owner.
    !]]
    __clone = function(this)
        local tComponents = this.getComponents();

        for sSlot, oComponent in pairs(tComponents) do
            tComponents[sSlot] = type.isnull(oComponent) and null or clone(oComponent);
        end

        local oCopy = _cVehicle({
            fuel        = clone(this.getFuel()),
            components  = tComponents,
            owner       = this.getOwner(),
            name        = this.getName().." copy",
            description = this.getDescription(),
            rarity      = this.getRarity(),
            environment = this.getEventEnvironment(),
            efficiency  = this.getDistancePerFuelUnit(),
            value       = this.getValue(),
            speed       = this.getMaxSpeed(),
            unmanned    = this.getUnmanned(),
            tradeable   = this.getTradeable(),
            quest       = this.getQuest(),
            exclusive   = this.getExclusive(),
            inimitable  = this.getInimitable(),
        });

        for sTag, bEnabled in this.getTagSystem().eachTag() do
            oCopy.getTagSystem().add(sTag, not bEnabled);
        end

        return oCopy;
    end,
},
{
    EVENT = _eEvent,
}, {},
{
    InspectionCount__autoA_  = 0,
    EventEnvironment__autoA_ = "_ENV",
    LastEnvironment__autoA_  = "No event dispatched yet",
},
{
    --[[!
        @fqxn Examples.Vehicles.Vehicle.ExampleGarageVehicle
        @desc Passes named example settings to the positional BaseVehicle constructor.
        @param table tSettings Optional base vehicle settings.
    !]]
    ExampleGarageVehicle = function(this, cdat, super, tSettings)
        local tSettings = tSettings or {};

        super(tSettings.fuel,        tSettings.unmanned,  tSettings.efficiency,
              tSettings.components,  tSettings.value,     tSettings.tradeable,
              tSettings.quest,       tSettings.exclusive, tSettings.inimitable,
              tSettings.speed,       tSettings.owner,     tSettings.name,
              tSettings.description, tSettings.rarity,    tSettings.environment);

        cdat.pro.EventEnvironment = tSettings.environment or "_ENV";

        -- Each newly constructed instance receives its own inspection callback.
        local function fInspection()
            cdat.pro.InspectionCount = cdat.pro.InspectionCount + 1;
            cdat.pro.LastEnvironment = VEHICLE_ENV_LABEL or "Framework default environment";
        end

        cdat.pro.eventrix.addHook(_eEvent.INSPECTION, fInspection);
    end,
}, _cBaseVehicle, false, nil);

return _cVehicle;
