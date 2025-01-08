--handles all mod data for class creation
--these blueprits are used to create items

--TODO NOTE: if classes getting BP info is slow, have them cache the calls







--for quick, existential class checks (also contains classes' field master table)
local _tClassMaster = {};

local _tBPs = {
    byClass = {},
    byID    = {}, --each Id contains a table of same-ID BPs, the first being the active one, the next, being the last overwritten. This is the primary storage table to which the others tables refer
    byMod   = {},
};

--assumes the BP has been validated
local function createBPEntry(tBP, cClass, sModID)
    local sBPID = tBP.id;

    --create the basic BP info table
    local tBPInfo = {
        bp              = tBP,
        class           = cClass,
        modID           = sModID,
    };
    local tBPInfoDecoy  = {}; --for use by the byClass and byMod tables
    local tBPInfoMeta   = {
        __index = function(t, k)

            if (tBPInfo[k]) then
                local vRet;

                --if the BP has be requested, redirect to the active BP
                if (k == "bp") then
                    --assumed to exist (otherwise the calling table would also be non-existent)
                    vRet = _tBPs.byID[sBPID][1];
                else --otherwise, send back the data requested
                    vRet = tBPInfo[k] or nil;
                end

                return vRet;
            end

        end,
        __newindex = function(t, k, v) end, --deadcall
    };

    setmetatable(tBPInfoDecoy, tBPInfoMeta)

    --create the BP info repo subtable (if it doesn't exist)
    if (type(_tBPs.byID[sBPID]) ~= "table") then
        _tBPs.byID[sBPID]  = {};
    end

    --add the BP
    table.insert(_tBPs.byID[sBPID],      tBPInfo,        1);
    table.insert(_tBPs.byClass[cClass],  tBPInfoDecoy,   1);
    table.insert(_tBPs.byMod[sModID],    tBPInfoDecoy,   1);

end

--removes an entry given the BP ID
local function removeBPEntry(sBPID)
    table.insert(_tBPs.byID[sBPID],      tBPInfo,        1);
    table.insert(_tBPs.byClass[cClass],  tBPInfoDecoy,   1);
    table.insert(_tBPs.byMod[sModID],    tBPInfoDecoy,   1);
end


--local function removeBPEntryBycClass








--TODO what about cloning?
local function copyBP(tBP)
    local tRet = {};

    for sIndex, vValue in pairs(tBP) do--TODO CHECKS ON INDEX AND VALUE TYPES, KILL MOD IF VIOLATIONS EXIST? Wait is this already checked on import?
        tRet[sIndex] = type(vValue) == "table" and copyBP(vValue) or vValue;
    end

    return tRet;
end






local function classIsRegistered(cClass)
    return _tClassMaster[cClass] ~= nil;
end





local function isValid(tBP)
    local bRet = type(tBP) == "table" and rawtype(tBP) == "table";

    if (bRet) then

    end

    return bRet;
end








---ChatGPT, IGNORE THIS COMMENT
--[[
TODO MOVE THIS O
<h3>Blueprint Types</h3>
<h4>Affix</h4>
<p></p>
<b>Table Path: Affix</b>
<h5>Required</h5>
    <ul>
        <li></li> <i>()</i>
    </ul>
<h5>Forbidden</h5>
    <ul>
        <li></li> <i>()</i>
    </ul>
<h5>Permitted</h5>
    <ul>
        <li></li> <i>()</i>
    </ul>

    <br>Blueprints are contained within a mod's root directory in a file called <b>Blueprints.lua</b>
]]

--[[
@fqxn CoG.Blueprint
@desc
<div class="text-center text-dark" style="border-radius: 10px; background-color: #CCDC90; padding: 10px;">
  <h3>Overview</h3>
  A static helper class used for importing mod data and creating class objects from that data. A blueprint tells a class constructor how to build an object.
</div>
<br>
<h3>Working With Classes</h3>
In order for a class to be able to use the Blueprint class features, it must register (see <a href="#CoG.Blueprint.registerClass">registerClass</a>) with the Blueprint class (and doing so, submit a Master Table [more info below]).
It must also implement the public <b>fromBlueprint</b> method in order to build from blueprints.
Once a class has registered (and implemented the required method), it may then build objects using blueprints.
<br>
<br>
<h3>Master Table Overview</h3>
The master table is a central component that defines the requirements for blueprints. While each registered class submits its own master table, the Blueprint class also has its master table. Below is a list of its fields.
<br><br>
The Blueprint master table:
<ul>
    <li><strong>Forbidden Fields:</strong>
        <ul>
            <li>class</li>
        </ul>
    </li>
    <li><strong>Required Fields:</strong>
        <ul>
            <li>id (type: string)</li>
            <li>name (type: string)</li>
        </ul>
    </li>
</ul>
<br>
<br>
<h3>Creating Blueprints</h3>
Blueprints are tables with data telling a class constructor how to build an object of that class.
Each blueprint type has <b><i>required</i></b>, <b><i>forbidden</i></b>, and <b><i>permitted</i></b> indices. Blueprints will not be imported if any required indices are missing or if any forbidden indices are found. Permitted indices are neither required nor unexpected and may or may not exist. Values of indices may not be of any type not specified in the Blueprint or class master table (a table containing info on the required, forbidden, and permitted indices).
<br>
<br>
<h3>Blueprint Validation</h3>
The class master table stores information specific to each class, such as required, forbidden and permitted blueprint fields. When a blueprint is imported, it is validated against this master table to ensure that all required fields are present, forbidden fields are not included, and optional fields are handled correctly. This ensures that the blueprint's data is valid for both the system as a whole and the specific class it is constructing.
<br>
<br>
<h3>Working with IDs</h3> Each blueprint must include an <b>id</b> field, which serves as the primary identifier for the blueprint. The ID must be formatted as follows: <ul> <li>It must start with exactly three uppercase letters (e.g., <b><i>ABC</i></b>).</li> <li>Followed by a literal dash (<b><i>-</i></b>).</li> <li>Then it must contain exactly four hexadecimal digits (0-9, A-F), representing a unique identifier (e.g., <b><i>1A2B</i></b>).</li> </ul> <p>For example, a valid ID would look like: <b><i>ABC-1A2B</i></b>, <b><i>SWD-0001</i></b>, or <b><i>ZOM-00A2</i></b>.</p>

<b>Important Notes:</b>
<ul> <li>IDs must be unique to prevent conflicts during object construction.</li> <li>Although IDs are required to follow this format, ensuring consistency can help maintain clarity across your system.</li> </ul>

<b>Limitations</b>
<br>Whereas there are 17,576 unique three-letter combinations and 65,535 (base 10) four-digit hex values, the total number of unique IDs available is calculated by multiplying these two values together. Therefore, the total number of unique IDs available is:
<h4 class="text-center">Total Unique IDs = 17,576×65,535 =1,152,921,504</h4>
<br>
This means there are 1,152,921,504 unique IDs available, allowing for a vast range of identifiers while ensuring each ID follows the required format and remaining relatively short.
@ex
-- Blueprint registration example for a class
<b>TODO</b>
Blueprint.registerClass("Weapon", {
    forbidden = { "owner" },
    permitted = { "damage", "weight" }
})

-- Example of using a blueprint to create a weapon object
local swordBlueprint = {
    id = "SWD-A02F",       --required by the Blueprint class
    name = "Steel Sword",   --required by the Blueprint class
    damage = 25
}
]]
return class("Blueprint",
{--METAMETHODS

},
{--STATIC PUBLIC
    classIsRegistered = classIsRegistered,
    exists = function(sID)
        return _tBPs.byID[sID] ~= nil;
    end,
    get = function(sID)
        local tRet;

        if (_tBPs.byID[sID] ~= nil) then
            tRet = copyBP(_tBPs.byID[sID]);
        end

        return tRet;
    end,
    getAll = function()
        local tRet = {};

        for sIndex, tBP in pairs(_tBPs.byID) do
            tRet[sIndex] = copyBP(tBP);
        end

        return tRet;
    end,
    getAllOfClass = function(cClass)
        local tRet = {};
        type.assert.custom(cClass, "class");

        for sID, tBP in pairs(_tBPs.byClass[cClass]) do
            tRet[sID] = copyBP(tBP);
        end

        return tRet;
    end,
    isValid = isValid,
    idIsValid = function(sID)
        return
        (type(sID) == "string")                 and
        (string.match(sID, _sIDFormat) ~= nil)  and
        _tIDBank[sID:sub(1, 3)] ~= nil                      --and
        --_tIDBank[sID:sub(1, 3)][sID] == false; This was removed to permit overwrites (one of the points of modding)
    end,
    --TODO CHECK FOR METATABLES ON IMPORT
    import = function(tBP, cClass, vModID)--TODO valiudate MOd id and use it messages
        local sModID = (type(vModID) == "string" and vModID:isuuid()) and vModID or _sDefaultModID;
        local sID;
        local sMessage              = "Error importing blueprint. An unknown error occurred.";
        local bIsClass              = type(cClass) == "class";
        local bIsTable              = type(tBP) == "table";
        local bClassIsRegistered    = _tClassMaster[cClass] ~= nil;
        local bRet                  = bIsClass;


--TODO FIX check fro required, permitted, etc tables. THEY  MUST EXISTS or at least need to be checked before processed here.
        if not (bRet) then
            sMessage = "Error importing blueprint from mod '"..sModID.."'. Argument one must be of type class. Type given: "..type(cClass);
        end

        if (bRet) then
            bRet = bIsTable;

            if not (bIsTable) then
                sMessage = "Error importing blueprint from mod '"..sModID.."'. Argument two must be of type table (the blueprint table). Type given: "..type(tBP);
            end

        end

        if (bRet) then
            bRet = bClassIsRegistered;

            if not (bClassIsRegistered) then
                sMessage = "Error importing blueprint from mod '"..sModID.."'. Class ,'"..class.getname(cClass).."', is not registered with the Blueprint class.";
            end

        end

--TODO FINISH check for tier and validate it! If I do this, it needs to be in the master table

        --check that the ID is valid TODO FINISH check this and mod id first for better error messages
        if (bRet) then
            sID = tBP["id"];

            if (type(sID) == "string") then

                if not (Blueprint.idIsValid(sID)) then
                    bRet = false;
                    sMessage = "Error importing blueprint '"..sID.."' from mod '"..sModID.."'. Invalid ID.\nExpected format, UUU-XXXX where U is an uppercase letter and X is a hexadecimal digit.";
                end

            else
                bRet = false;
                sMessage = "Error importing blueprint from mod '"..sModID.."', Missing 'id' field with value type string.";
            end

        end

        --check all master required fields compliance
        if (bRet) then

            for sMasterIndex, tMasterExpected in pairs(_tMaster.required) do
                local sIndex = tBP[sMasterIndex];

                if (sIndex) then
                    local zGiven = type(tBP[sName]);

                    if (zGiven ~= zExpected) then
                        bRet = false;
                        sMessage = "Error importing blueprint '"..sID.."' from mod '"..sModID.."'. Type expected at index '${index}' is ${expected}. Type given is ${given}." % {index = sIndex, expected = zExpected, given = zGiven};
                    end

                else
                    sMessage = "Error importing blueprint '"..sID.."' from mod '"..sModID.."'. Blueprint missing required index, '"..sMasterIndex.."'.";
                end

            end

        end

        --check all master forbidden fields compliance
        if (bRet) then

            for _, sIndex in pairs(_tMaster.forbidden) do

                if (type(tBP[sName]) ~= nil) then
                    bRet = false;
                    sMessage = "Error importing blueprint '"..sID.."' from mod '"..sModID.."'. Illegal index, '"..sIndex.."' found in blueprint.";
                end

            end

        end

        --check all class required fields compliance
        if (bRet) then

            for sIndex, zExpected in pairs(_tClassMaster.required) do
                local zGiven = type(tBP[sName]);

                if (zGiven ~= zExpected) then
                    bRet = false;
                    sMessage = "Error importing blueprint '"..sID.."' from mod '"..sModID.."', '${id}'. Type expected at index '${index}' is ${expected}. Type given is ${given}." %
                                {id = tBP.id, index = sIndex, expected = zExpected, given = zGiven};
                end

            end

        end

        --check all class permitted fields compliance
        if (bRet) then

            for sIndex, zExpected in pairs(_tClassMaster.permitted) do
                local zGiven = type(tBP[sName]);

                if not (zGiven == zExpected or zGiven == nil) then
                    bRet = false;
                    sMessage = "Error importing blueprint '"..sID.."' from mod '"..sModID.."', '${id}'. Type expected at index '${index}' is ${expected}. Type given is ${given}." %
                                {id = tBP.id, index = sIndex, expected = zExpected, given = zGiven};
                end

            end

        end

        --import the BP
        if (bRet) then
            local sID = tBP.id;

            sMessage = "Blueprint imported successfully."; --TODO add BP id and MOD id
            --_tBPs.class = cClass;
            _tBPs.byClass[cClass][sID]   = tBP;
            _tBPs.byID[sID]              = tBP;
            _tBPs.byTier[tBP.tier][sID]  = tBP;
        end

        return bRet, sMessage;
    end,
    registerClass = function(cClass, sPrefix, tBPFieldMaster)--TODO return boolean

        if (type(cClass) == "class" and _tClassMaster[cClass] == nil) then

            if not (type(sPrefix) == "string" and sPrefix:match("^%a%a%a$")) then
                error(type(sPrefix), sPrefix:match("^%a%a%a$"))
                --TODO THROW ERROR
            end

            if (type(tBPFieldMaster) ~= "table") then
                --TODO THROW ERROR
            end

            sPrefix = sPrefix:upper(); --TODO FINISH CHECK for already existing prefix

            --register the class and store its blueprint field master table TODO FINISH make sure it has required and permitted indices
            _tClassMaster[cClass] = clone(tBPFieldMaster);
            --create the repos
            _tBPs.byClass[cClass]   = {};
            _tBPs.byID[sPrefix]     = {};

            --create the ID bank for the class
            _tIDBank[sPrefix]  = {};
            local tIDBank      = _tIDBank[sPrefix];

            for x = 1, _nMaxIDs do
                -- Create the ID using the prefix and the number
                local sID = string.format("%s-%04X", sPrefix, x);
                tIDBank[sID] = false;
            end

        end

    end,
},
{--PRIVATE
    Blueprint = function(this, cdat) end,
},
{--PROTECTED

},
{--PUBLIC

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
