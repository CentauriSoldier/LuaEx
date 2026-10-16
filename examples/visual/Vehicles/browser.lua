local _cVehicle  = require("examples.visual.Vehicles.Vehicle");
local _cBase     = require("LuaEx.inc.cog.Objects.VehicleSystem.BaseVehicle");
local _tFleet    = {};
local _tEvents   = {};
local _nSelected = 1;
local _sMessage  = "Select a vehicle and explore its real LuaEx state.";
local _tFlags    = {"unmanned", "tradeable", "quest", "exclusive", "inimitable"};

--[[!
    @fqxn Examples.Vehicles.record
    @desc Keeps a bounded operation history and the latest visible result.
    @param string sMessage The operation result.
!]]
local function record(sMessage)
    _sMessage = sMessage;
    _tEvents[#_tEvents + 1] = sMessage;

    if (#_tEvents > 30) then
        table.remove(_tEvents, 1);
    end
end

--[[!
    @fqxn Examples.Vehicles.reset
    @desc Creates three independent fuel Pools, owners and component objects.
    Components use Pool objects so their condition is directly explorable.
!]]
local function reset()
    _tFleet    = {};
    _tEvents   = {};
    _nSelected = 1;

    local tPresets = {
        {"Trailwarden", "rover",   "Six wheels, long horizons. An expedition rover.",  80, 4,  72, 18000},
        {"Cloudrunner", "airship", "A brass and canvas cargo ship for mountain ports.", 120, 7, 110, 46000},
        {"Stillwater",  "skiff",   "An unmanned survey craft for remote waterways.",  50, 9,  36, 12000},
    };

    for nIndex, tPreset in ipairs(tPresets) do
        local tComponents = {};
        local oOwner      = Pool(); -- Minimal class instance representing crew identity.

        for _, eSlot in _cBase.COMPONENT() do
            tComponents[eSlot.name] = Pool(100, 100);
        end

        _tFleet[nIndex] = {
            image    = tPreset[2],
            distance = 0,
            owner    = oOwner,
            vehicle  = _cVehicle({
                name        = tPreset[1],
                description = tPreset[3],
                fuel        = Pool(tPreset[4], tPreset[4] * .75),
                efficiency  = tPreset[5],
                speed       = tPreset[6],
                value       = tPreset[7],
                components  = tComponents,
                owner       = oOwner,
                unmanned    = nIndex == 3,
                quest       = nIndex == 2,
                exclusive   = nIndex == 2,
            }),
        };
    end

    record("Fresh garage. Movement, component condition and clone policy belong to this example.");
end

--[[!
    @fqxn Examples.Vehicles.view
    @desc Exports plain display data without replacing any live vehicle references.
    @ret table tState The garage and selected vehicle inspector.
!]]
local function view()
    local tState = {visual = "vehicles", fleet = {}, events = clone(_tEvents), message = _sMessage, rarities = {}};

    for _, eRarity in Rarity.LEVEL() do
        tState.rarities[#tState.rarities + 1] = eRarity.name;
    end

    for nIndex, tRecord in ipairs(_tFleet) do
        local oVehicle = tRecord.vehicle;
        local oFuel    = oVehicle.getFuel();
        local tInfo    = {
            id              = nIndex,
            image           = tRecord.image,
            name            = oVehicle.getName(),
            description     = oVehicle.getDescription(),
            rarity          = oVehicle.getRarity().name,
            environment     = oVehicle.getEventEnvironment(),
            inspections     = oVehicle.getInspectionCount(),
            lastEnvironment = oVehicle.getLastEnvironment(),
            fuel            = oFuel.get(),
            capacity        = oFuel.get(Pool.ASPECT.MAX),
            available       = oFuel.get(Pool.ASPECT.AVAILABLE),
            reserved        = oFuel.get(Pool.ASPECT.RESERVED),
            efficiency      = oVehicle.getDistancePerFuelUnit(),
            speed           = oVehicle.getMaxSpeed(),
            value           = oVehicle.getValue(),
            distance        = tRecord.distance,
            owner           = type.isnull(oVehicle.getOwner()) and "Unowned" or "Expedition crew (shared object)",
            components      = {},
            tags            = {},
        };

        for _, sFlag in ipairs(_tFlags) do
            tInfo[sFlag] = oVehicle["get"..sFlag:gsub("^%l", string.upper)]();
        end

        for _, eSlot in _cBase.COMPONENT() do
            local oComponent = oVehicle.getComponent(eSlot);

            tInfo.components[#tInfo.components + 1] = {
                slot      = eSlot.name,
                installed = not type.isnull(oComponent),
                condition = type.isnull(oComponent) and 0 or oComponent.get(),
            };
        end

        for sTag in oVehicle.getTagSystem().eachTag() do
            tInfo.tags[#tInfo.tags + 1] = sTag;
        end

        tState.fleet[#tState.fleet + 1] = tInfo;

        if (nIndex == _nSelected) then
            tState.selected = tInfo;
        end
    end

    return tState;
end

--[[!
    @fqxn Examples.Vehicles.workbench_action
    @desc Applies a requested operation. Expected failures become visible messages.
    Constructor edits validate a replacement before publishing it to the garage.
    @param string sAction The operation name.
    @param table tData The operation arguments.
    @ret table tState The refreshed inspector state.
!]]
function workbench_action(sAction, tData)
    local tData = tData or {};

    local function fApply()
        if (sAction == "reset") then reset(); return; end
        if (sAction == "view") then return; end

        if (sAction == "select") then
            assert(_tFleet[tData.id], "Unknown vehicle.");
            _nSelected = tData.id;
            return;
        end

        local tRecord  = _tFleet[_nSelected];
        local oVehicle = tRecord.vehicle;
        local oFuel    = oVehicle.getFuel();

        if (sAction == "fuel") then
            local nAmount = tonumber(tData.amount);

            assert(nAmount and nAmount == nAmount and math.abs(nAmount) < math.huge, "Enter a finite fuel amount.");
            oFuel.adjust(nAmount);
            record("Adjusted fuel; Pool clamps current fuel to available capacity.");

        elseif (sAction == "reserve") then
            local nAmount = tonumber(tData.amount);
            local _, bAccepted = oFuel.set(nAmount, Pool.ASPECT.RESERVED_FLAT);

            assert(bAccepted, "Reservation exceeds fuel capacity; previous settings retained.");
            record("Reserved fuel capacity. Current fuel may clamp to the reduced available capacity.");

        elseif (sAction == "drive") then
            local nDistance = tonumber(tData.distance);

            assert(nDistance and nDistance >= 0 and nDistance < math.huge, "Enter a finite nonnegative distance.");
            assert(oVehicle.getMaxSpeed() > 0, "This vehicle has no configured movement speed.");
            assert(oVehicle.getDistancePerFuelUnit() > 0, "This vehicle has no configured fuel efficiency.");

            local nCost = nDistance / oVehicle.getDistancePerFuelUnit();

            assert(nCost <= oFuel.get(), "Insufficient fuel. No distance or fuel changed.");
            oFuel.adjust(-nCost);
            tRecord.distance = tRecord.distance + nDistance;
            record(string.format("Travelled %.2f km using %.2f units; minimum time at max speed: %.2f h.",
                                 nDistance, nCost, nDistance / oVehicle.getMaxSpeed()));

        elseif (sAction == "component") then
            if (tData.operation == "remove") then
                oVehicle.setComponent(tData.slot, nil);
            elseif (tData.operation == "install") then
                oVehicle.setComponent(tData.slot, Pool(100, 100));
            elseif (tData.operation == "share") then
                local oOther = _tFleet[_nSelected == 1 and 2 or 1].vehicle;

                oVehicle.setComponent(tData.slot, oOther.getComponent(tData.slot));
            else
                local oComponent = oVehicle.getComponent(tData.slot);

                assert(not type.isnull(oComponent), "Install a component first.");
                oComponent.adjust(tData.operation == "damage" and -25 or 25);
            end

            record("Component operation: "..tData.operation..". Shared component condition changes in both vehicles.");

        elseif (sAction == "rebuild") then
            tData.fuel        = oFuel;
            tData.components  = oVehicle.getComponents();
            tData.owner       = tData.unowned and null or tRecord.owner;
            tData.rarity      = Rarity.LEVEL[tData.rarity];
            assert(tData.environment == "_ENV" or tData.environment == "ExampleGarageWorkshop", "Choose a registered example event environment.");

            local oReplacement = _cVehicle(tData);

            for sTag, bEnabled in oVehicle.getTagSystem().eachTag() do
                oReplacement.getTagSystem().add(sTag, not bEnabled);
            end

            tRecord.vehicle = oReplacement;
            record("Constructed a replacement vehicle. Fuel, component and owner references were retained; tags copied.");

        elseif (sAction == "clone") then
            assert(#_tFleet < 12, "Reset before creating more than twelve vehicles.");

            local oCopy = clone(oVehicle);

            _tFleet[#_tFleet + 1] = {vehicle = oCopy, image = tRecord.image, distance = 0, owner = tRecord.owner};
            _nSelected = #_tFleet;
            record("Concrete clone: independent fuel, components and tags; shared owner; new trip counter. Inimitable is caller-enforced metadata.");

        elseif (sAction == "tag") then
            assert(rawtype(tData.tag) == "string" and #tData.tag <= 80, "Enter a tag of at most 80 characters.");
            oVehicle.getTagSystem()[tData.remove and "remove" or "add"](tData.tag);
            record("Updated inherited TagSystem.");

        elseif (sAction == "snapshot") then
            local tSnapshot = oVehicle.getComponents();
            local sSlot     = next(tSnapshot);

            assert(sSlot, "No configured slots.");

            local oOriginal = oVehicle.getComponent(sSlot);

            tSnapshot[sSlot] = null;
            assert(rawequal(oVehicle.getComponent(sSlot), oOriginal), "Snapshot unexpectedly changed vehicle.");
            record("PASS: editing the returned slot table leaves the vehicle unchanged. Objects inside it retain identity.");

        elseif (sAction == "baseclone") then
            local bOK, sWhy = pcall(clone, _cBase());

            assert(not bOK, "Base clone unexpectedly succeeded.");
            record("Expected base clone rejection: "..tostring(sWhy));

        elseif (sAction == "invalid") then
            local bOK, sWhy = pcall(function()
                if (tData.test == "slot") then oVehicle.setComponent("UNKNOWN", Pool());
                elseif (tData.test == "component") then oVehicle.setComponent(_cBase.COMPONENT[1], {});
                elseif (tData.test == "flag") then _cVehicle({tradeable = "yes"});
                elseif (tData.test == "fuel") then _cVehicle({fuel = {}});
                else _cVehicle({speed = -1}); end
            end);

            assert(not bOK, "Invalid input unexpectedly succeeded.");
            record("Expected validation rejection: "..tostring(sWhy));

        elseif (sAction == "serialize") then
            local bOK, vResult = pcall(serializer.serialize, oVehicle);

            record(bOK and ("Serialized: "..tostring(vResult)) or ("Current native serialization limitation: "..tostring(vResult)));

        elseif (sAction == "event") then
            oVehicle.fireEvent(_cVehicle.EVENT.INSPECTION, oVehicle);
            record("Inspection callback #"..oVehicle.getInspectionCount()..". Configured: "..oVehicle.getEventEnvironment().."; observed: "..oVehicle.getLastEnvironment()..". Eventrix does not currently rebind this hook's lexical environment.");
        else
            error("Unknown vehicle action.");
        end
    end

    local bOK, sWhy = pcall(fApply);

    if (not bOK) then
        record("Rejected: "..tostring(sWhy));
    end

    return view();
end

reset();
return view();
