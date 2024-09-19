--[[!
    @fqxn CoG.VehicleSystem.BaseVehicle
    @desc Represents a generic vehicle with common fields and methods.
!]]
return class("BaseVehicle",
{--METAMETHODS
    __clone = function(this, cdat)
        local oNew = BaseVehicle();
        -- TODO: Implement cloning logic if needed
        return oNew;
    end,
},
{--STATIC PUBLIC
    -- Define static methods or properties if needed
},
{--PRIVATE
},
{--PROTECTED
    Components__autoA_          = {},              -- Table to store vehicle components
    DistancePerFuelUnit__autoA_ = 0,               -- Number representing distance per unit of fuel
    Exclusive__autoA_           = false,           -- Boolean indicating if the vehicle is exclusive
    Fuel__autoA_                = null,            -- Pool object for fuel management
    Inimitable__autoA_          = false,           -- Boolean indicating if the vehicle is inimitable
    MaxSpeed__autoA_            = 0,               -- Number representing the maximum speed of the vehicle
    Owner__autoA_               = null,            -- Owner of the vehicle (to be implemented later)
    Quest__autoA_               = false,           -- Boolean indicating if the vehicle is related to a quest
    Sellable__autoA_            = true,            -- Boolean indicating if the vehicle is sellable
    Tradeable__autoA_           = true,            -- Boolean indicating if the vehicle is tradeable
    Unmanned__autoA_            = false,           -- Boolean indicating if the vehicle is unmanned
    Value__autoA_               = 0,               -- Number representing the value of the vehicle
},
{--PUBLIC
    BaseVehicle = function(this, cdat, fuel, unmanned, distancePerFuelUnit, components, value, sellable, tradeable, quest, exclusive, inimitable, maxSpeed)
        local pro = cdat.pro;

        pro.Fuel                = type(fuel) == "table" and fuel or Pool();
        pro.Unmanned            = type(unmanned) == "boolean" and unmanned or false;
        pro.DistancePerFuelUnit = type(distancePerFuelUnit) == "number" and distancePerFuelUnit or 0;
        pro.Components          = type(components) == "table" and components or {};
        pro.Value               = type(value) == "number" and value or 0;
        pro.Sellable            = type(sellable) == "boolean" and sellable or true;
        pro.Tradeable           = type(tradeable) == "boolean" and tradeable or true;
        pro.Quest               = type(quest) == "boolean" and quest or false;
        pro.Exclusive           = type(exclusive) == "boolean" and exclusive or false;
        pro.Inimitable          = type(inimitable) == "boolean" and inimitable or false;
        pro.MaxSpeed            = type(maxSpeed) == "number" and maxSpeed or 0;
    end,
},
BaseObject,  -- Extending class
false,       -- If the class is final
nil          -- Interface(s)
);
