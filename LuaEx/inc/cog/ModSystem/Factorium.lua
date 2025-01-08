--TODO NOTE: if classes getting BP info is slow, have them cache the calls

-- Pattern explanation:
-- ^        : start of the string
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %u%u%u  : exactly three uppercase letters (XXX)
-- %-       : literal dash (-)
-- %x%x%x%x : exactly four hexadecimal digits (DDDD)
-- $        : end of the string
local _sDefaultModID    = BaseMod.DEFAULT_MOD_ID;
local _sIDFormat        = "^%u%u%u%-%u%u%u%-%x%x%x%x$";
local _nMaxIDs          = 20316036096000;--WARNING: CHANGE (ONLY) IF YOU ALSO CHANGE THE ID FORMAT AND LENGTH
local _tIDCheckCache    = {};
local _fIDSchema        = schema.Pattern(_sIDFormat);
--this is main table that stores blueprints and relevant details. Indexed by class, it contains a nuermically-indexed blueprints table, a byID table, the factory method for creating objects and the schema function.
local _tSchemata        = {
    --[[each entry is:
    [cClass] = {
        blueprints      = <table>,
        blueprintsByID  = <table>,
        factory         = <function>
        schema          = <function>
    },
    --]]
};

--TODO create rnadom BP getter and do class/prefix/prefix 2 ones too

--this is quick lookup table indexed by blueprint ID.
local _tBlueprints = {
    --[[
    class       = cChild,
    blueprint   = tBPCloned,
    factory     = tSchema.factory,
    modID       = "",
    ]]
}; --tracks which classes and blueprints belong to which IDs for fast lookup

--another quick lookup table used for getting the blueprint IDs of blueprints in a mod.
local _tBlueprintsByMod = {};

local function idIsValid(vID)
    local bRet = false;

    if (_tIDCheckCache[vID] ~= nil) then
        bRet = _tIDCheckCache[vID];
    else
        local zID = type(vID);

        if (zID ~= "nil") then

            if (zID == "string" and vID:match(_sIDFormat)) then
                bRet = true;
                _tIDCheckCache[vID] = bRet;
            end

        end

    end

    return bRet;
end

--[[!
@fqxn CoG.ModSystem.Factorium
@desc Factorium is a static class designed to handle factory methods for classes. Specifically, it handles building class instances from blueprint tables. Once a class has registered with Factorium, it's factory method is publicly available. Blueprints can be added for the class and objects built from those blueprints.
<br><br>When registering <i>(which must be done within its static contructor)</i>, the class provides a schema TODO add link function <i>(used to validate blueprint tables)</i> and a factory method that builds the object and is responsible for returning that built object.
<br><br>In additional, this can even be used for classes with private/protected constructors ensuring only blueprints could be used to build instances for those classes.
@ex TODO example should show - create a class, register it, build objects
!]]
return class("Factorium",
{--METAMETHODS

},
{--STATIC PUBLIC
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --Factorium = function(this) end, --static constructor (runs after class object creation)
    SCHEMA_ID               = _fIDSchema,
    ID_BLOCK                = enum("Factorium.ID_BLOCK", {"ONE", "TWO"}, {"([^%-]+)", "-(.-)-"}, true),
    addBlueprint = function(cChild, tBP, sModID)
        local sMessage;
        local bRet      = false;
        local bIsChild  = class.is(cChild);-- and class.ischild(cChild, CoG);
        local sModID    = (type(sModID) == "string" and sModID:match(string.patterns.nonblank)) and sModID or _sDefaultModID;

        --make sure the class is a child of CoG and it's been registered
        if (bIsChild and _tSchemata[cChild] ~= nil) then
            local tSchema   = _tSchemata[cChild];
            local tBPsByID  = tSchema.blueprintsByID;
            local tBPs      = tSchema.blueprints;

            --TODO ID check and type errors
            if (type(tBP) == "table") then
                local sID = tBP.id;

                if (type(sID) == "string" and sID:match(_sIDFormat)) then
                local tErrors = schema.CheckSchema(tBP, tSchema.schema);

                    if (tErrors) then --TODO FIX change error messages when class helper functions are updated
                        sMessage = "Error adding blueprint ("..sID..") to class, '"..class.getname(cChild).."'. "..schema.FormatOutput(tErrors);
                    else

                        if (tBPsByID[sID] == nil) then
                            --clone and store the blueprint
                            bRet            = true;
                            local tBPCloned = clone(tBP);
                            tBPsByID[sID]   = tBPCloned;
                            tBPs[#tBPs + 1] = tBPCloned;

                            --create an entry in the _tBlueprints quick-lookup table
                            _tBlueprints[sID] = {
                                class       = cChild,
                                blueprint   = tBPCloned,
                                factory     = tSchema.factory,
                                mod         = sModID,
                            };

                            --create an entry in the bymod quick lookup table
                            if (_tBlueprintsByMod[sModID] == nil) then
                                _tBlueprintsByMod[sModID] = {};
                            end

                            _tBlueprintsByMod[sModID][sID] = tBPCloned;
                        else
                            sMessage = "Error adding blueprint ("..sID..") to class, '"..class.getname(cChild).."' Blueprint already exists."; --TODO FIX this...allow overwrites and track them
                        end

                    end

                else
                    sMessage = "Error adding blueprint to class, '"..class.getname(cChild).."'. Blueprint ID is invalid. ID must be a string matching pattern, '".._sIDFormat.."' and be stored in index 'id' at the base level of the blueprint table.";
                end

            end

        else
            --sMessage TODO
        end

        return bRet, sMessage;
    end,
    --[[This function is responsible for returning the instance (or nil as the first return and a second return value containing a string messsage indicating what went wrong).
    <br>It must accept the ]]
    fromBlueprint = function(sID, ...)
        local oRet, sMessage;
        --TODO check input

        --if the blueprint exists...
        if (_tBlueprints[sID] ~= nil) then

            local tBPData = _tBlueprints[sID];
            --...run the factory method and return the created object
            oRet, sMessage = tBPData.factory(sID, clone(tBPData.blueprint), ...);

            --check that the object actually got created --TODO FIX update message after class helper functions updated
            if not (class.of(oRet) == tBPData.class) then
                --TODO THROW ERROR (append last error)
            end

        else
            --TODO update message after class helper functions are changed
            sMessage = "Error building class object from blueprint, '"..sID.."'. Blueprint does not exist.";
            --print(sID, sMessage)
        end

        return oRet, sMessage;
    end,
    getBlueprintIDsByClass = function(cClass)
        local tRet;

        if (_tSchemata[cClass] ~= nil) then
            tRet = {};

            for sID, tBP in pairs(_tSchemata[cClass]) do
                tRet[#tRet + 1] = sID;
            end

        end

        return tRet;
    end,
    getBlueprintIDsByBlock = function(eIDBlock, sBlock) --TODO 
        local tRet = {};
        --TODO assert input        type.assert.custom();
        local sCheckMe = "";

        if (eIDBlock == Factorium.ID_BLOCK[1]) then

        end


        --for sID, tData in pairs(_tBlueprints) do
        --    local sPatternMatch =

        --    if (sID:match(sPattern) and ) then
        --        tRet[#tRet + 1] = sID;
        --    end

        --end

        table.sort(tRet);

        return tRet;
    end,
    getBlueprintIDsByMod = function(sModID)
        --TODO assert input        type.assert.custom();
--_tBlueprintsByMod

        --for sID, tData in pairs() do

        --end

    end,
    isClassRegistered = function(cClass)
        return _tSchemata[cClass] ~= nil;
    end,
    --getBlueprintIDsByPrefix
    --getBlueprintIDsBySuffix
    --[[!
    @fqxn CoG.ModSystem.Factorium.Methods.registerFactory
    @desc Registers a class with Factorium for the purposes of being able to build class instances from blueprints.
    <br><b><i>Note</i></b>: this <b>must</b> be called from within the class's static contructor (not static initializer).
    @param class cClass The class to be registered.
    @param string SAuthCode The authentication code available within the class's static constructor.
    @param function fSchema The schema record <b>TODO</b> (put link here) used to validate imported blueprints.
    @param function fFromBlueprint The factory function used to build an instance of the class (see <a href="CoG.ModSystem.Factorium.Methods.fromBlueprint">Factorium.fromBlueprint</a>).
    @ret boolean bSuccess True if the class was registered, false otherwise. If false, a message describing the error is returned as well.
    @ret string|nil sError If the class was not registered successfully, this message is returned describing what went wrong.
    @vis static public
    !]]
    registerFactory = function(cChild, sAuthCode, fSchema, fFromBlueprint)
        local bIsChild              = class.is(cChild) and class.ischild(cChild, CoG);
        local bAuthenticated        = class.isstaticconstructorrunning(cChild, sAuthCode);
        local bIsBlueprintfunction  = type(fFromBlueprint) == "function";
        local bIsSchemaFunction     = type(fSchema) == "function";
        local bNoSchemaExists       = _tSchemata[cChild] == nil;
        local bIsPublic             = true;     --TODO FINISH use this when function is complete class.getconstructorvisibility() == "public"; Actually, dop't use this but do add that class helper function
        local bRet = false;
        local sMessage;
                                                --TODO raise errros on bad input
        if (bIsChild and bAuthenticated and bIsBlueprintfunction and
            bIsSchemaFunction and bNoSchemaExists) then
            bRet = true;

            --create the schema info table
            _tSchemata[cChild] = {
                blueprints      = {},
                blueprintsByID  = {},
                factory         = fFromBlueprint,
                schema          = fSchema,
            };

            --create an entry for the ID Bank
            _tBlueprints[cChild] = {};

        else
            sMessage = "Is CoG child class: "..tostring(bIsChild).."\n";
            sMessage = sMessage.."Is called from class static constructor: "..tostring(bAuthenticated).."\n";
            sMessage = sMessage.."Has 'fromBlueprint' method: "..tostring(bIsBlueprintfunction).."\n";
            sMessage = sMessage.."Has schema function : "..tostring(bIsSchemaFunction).."\n";
            sMessage = sMessage.."Schema does not exist: "..tostring(bNoSchemaExists).."\n";
        end

    return bRet, sMessage;
    end,
},
{--PRIVATE
    Factorium = function(this, cdat) end,
},
{--PROTECTED

},
{--PUBLIC
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
