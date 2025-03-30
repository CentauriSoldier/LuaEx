--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then
    --sSourccePath = "";

    function getsourcepath()
        --determine the call location
        local sPath = debug.getinfo(1, "S").source;
        --remove the calling filename
        local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
        --make a pattern to account for case
        local sFilename = "";
        for x = 1, #sFilenameRAW do
            local sChar = sFilenameRAW:sub(x, x);

            if (sChar:find("[%a]")) then
                sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
            else
                sFilename = sFilename..sChar;
            end

        end
        sPath = sPath:gsub("@", ""):gsub(sFilename, "");
        --remove the "/" at the end
        sPath = sPath:sub(1, sPath:len() - 1);

        return sPath;
    end

    --determine the call location
     sSourcePath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sSourcePath.."\\..\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================
local function row()

    local tRow      = {};
    local tRowMeta  = {

    };
    setmetatable(tRow, tRowMeta);
end

return class("CSV",
{--METAMETHODS

},
{--STATIC PUBLIC
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --CSV = function(this) end, --static constructor (runs after class object creation)
},
{--PRIVATE
    columnCount = 0,
    columnOrder = {},
    rowCount    = 0,
    rowOrder    = {},
},
{--PROTECTED
    rows = {},
},
{--PUBLIC
    CSV = function(this, cdat, sData)

    end,

    addColumn = function(this, cdat, sColumn, tValues)

    end,

    addRow = function(this, cdat, bPosition)
        --bPosition can be nil for at end, -1 for at frront or insert value id..can use letters for up, down, left, right etc.
    end,

    columnExists = function(this, cdat, nColumn)

    end,

    getColumn = function(this, cdat, nColumn) --get all data in the column for each row

    end,

    getColumnName = function(this, cdat, nColumn)

    end,

    getColumnNames = function(this, cdat)

    end,

    getColumnPos = function(this, cdat, sColumn)

    end,

    getRow = function(this, cdat, nRow)

    end,

    moveColumn = function(this, cdat, sColumn, nPosition)

    end,

    moveRow = function(this, cdat, nRow, nPosition)

    end,

    rowExists = function()

    end,

    sortByColumn = function(this, cdat, nColumn)

    end,

    setValue = function(this, cdat, nRow, nColumn)

    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
