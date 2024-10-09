--handles all mod data for class creation
--these blueprits are used to create items

--TODO NOTE: if classes getting BP info slow, have them cache the calls

local _nMaxIDs  = 65535; --WARNING: DO NOT CHANGE UNLESS YOU ALSO CHANGE THE ID FORMAT AND LENGTH
local _tIDBank  = {
    --byClass     = {},
    --byString    = {},
};

--for quick, existential class checks (also contains classes' field master table)
local _tClassMasterTable = {};

local _tBPs = {
    byClass = {}, --[class][id] = bp
    byID    = {}, --[id]        = bp
    byTier  = {}, --[tier][id]  = bp
};

local _tMasterTable = {
    forbidden = {
        "class"
    },
    required = {
        id   = {"string"},
        name = {"string"},
    },
};


local function copyBP(tBP)
    local tRet = {};

    for sIndex, vValue in pairs(tBP) do
        tRet[sIndex] = type(vValue) == "table" and copyBP(vValue) or vValue;
    end

    return tRet;
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

    <br>Blueprints are contained within a mod's root directory in a file called <b>Blueprints. TODO prbably best to remove this sentence unkuss incorporating the mod system into CoGlua</b>
]]

--[[!
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
    id = "sword_001",       --required by the Blueprint class
    name = "Steel Sword",   --required by the Blueprint class
    damage = 25
}
!]]
return class("Blueprint",
{--METAMETHODS

},
{--STATIC PUBLIC
    Blueprint = function(stapub)

        for nOrdinal, eItem in TIER() do
            _tBPs.byTier[eItem] = {};
        end
    end,
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
    getAllOfTier = function(eTier)
        local tRet = {};
        type.assert.custom(eTier, "TIER");

        for sID, tBP in pairs(_tBPs.byTier[eTier]) do
            tRet[sID] = copyBP(tBP);
        end

        return tRet;
    end,
    getAllOfClassAndTier = function(cClass, eTier)
        local tRet = {};
        type.assert.custom(cClass, "class");
        type.assert.custom(eTier, "TIER");

        for sID, tBP in pairs(_tBPs.byClass[cClass]) do

            if (tBP.tier == eTier) then
                tRet[sID] = copyBP(tBP);
            end

        end

        return tRet;
    end,
    idIsValid = function(sID)
        -- Pattern explanation:
        -- ^        : start of the string
        -- %u%u%u  : exactly three uppercase letters (XXX)
        -- %-       : literal dash (-)
        -- [%x]+    : one or more hexadecimal digits (0-9, A-F)
        -- %x%x%x%x : exactly four hexadecimal digits (DDDD)
        -- $        : end of the string
        return
        (type(sID) == "string")                             and
        (string.match(sID, "^%u%u%u%-%x%x%x%x$") ~= nil)    and
        _tIDBank[sID:sub(1, 3)] ~= nil                      --and
        --_tIDBank[sID:sub(1, 3)][sID] == false; This was removed to permit overwrites (one of the points of modding)
    end,
    import = function(cClass, tBP)
        local sMessage = "";
        local bRet =    type(cClass)    == "class" and --TODO break this up and adjust message
                        type(tBP)       == "table" and
                        _tClassMasterTable[cClass] ~= nil;


        --check that the ID is valid
        if (bRet) then

            if not (Blueprint.idIsValid(tBP.id)) then
                bRet = false;
                local sID = type(tBP.id) == "string" and tBP.id or "UNKNOWN"
                sMessage = "Error loading blueprint, '"..sID.."'. Invalid ID.\nExpected format, UUU-XXXX where U is an uppercase letter and X is a hexadecimal digit.";
            end

        end

        --check all master required fields compliance
        if (bRet) then

            for sIndex, zExpected in pairs(_tMasterTable.required) do
                local zGiven = type(tBP[sName]);

                if (zGiven ~= zExpected) then
                    bRet = false;
                    sMessage = "Error loading blueprint. Type expected at index '${index}' is ${expected}. Type given is ${given}." % {index = sIndex, expected = zExpected, given = zGiven};
                end

            end

        end

        --check all master forbidden fields compliance
        if (bRet) then

            for _, sIndex in pairs(_tMasterTable.forbidden) do

                if (type(tBP[sName]) ~= nil) then
                    bRet = false;
                    sMessage = "Error loading blueprint. Illegal index, '"..sIndex.."' found in blueprint.";
                end

            end

        end

        --check all class required fields compliance
        if (bRet) then

            for sIndex, zExpected in pairs(_tClassMasterTable.required) do
                local zGiven = type(tBP[sName]);

                if (zGiven ~= zExpected) then
                    bRet = false;
                    sMessage = "Error loading blueprint, '${id}'. Type expected at index '${index}' is ${expected}. Type given is ${given}." %
                                {id = tBP.id, index = sIndex, expected = zExpected, given = zGiven};
                end

            end

        end

        --check all class permitted fields compliance
        if (bRet) then

            for sIndex, zExpected in pairs(_tClassMasterTable.permitted) do
                local zGiven = type(tBP[sName]);

                if not (zGiven == zExpected or zGiven == nil) then
                    bRet = false;
                    sMessage = "Error loading blueprint, '${id}'. Type expected at index '${index}' is ${expected}. Type given is ${given}." %
                                {id = tBP.id, index = sIndex, expected = zExpected, given = zGiven};
                end

            end

        end

        --import the BP
        if (bRet) then
            local sID = tBP.id;
            _tBPs.class = cClass;

            _tBPs.byClass[cClass][sID]   = tBP;
            _tBPs.byID[sID]              = tBP;
            _tBPs.byTier[tBP.tier][sID]  = tBP;
        end

        return bRet, sMessage;
    end,
    registerClass = function(cClass, sPrefix, tBPFieldMaster)--TODO return boolean

        if (type(cClass) == "class" and _tClassMasterTable[cClass] == nil) then

            if not (type(sPrefix) == "string" and sPrefix:match("^%a%a%a$")) then
                --TODO THROW ERROR
            end

            if (type(tBPFieldMaster) ~= "table") then
                --TODO THROW ERROR
            end

            sPrefix = sPrefix:upper();

            --register the class and store its blueprint field master table TODO FINISH make sure it has required and permitted indices
            _tClassMasterTable[cClass] = clone(tBPFieldMaster);
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
