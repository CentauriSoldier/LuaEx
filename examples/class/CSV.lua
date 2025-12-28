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
            local ssChar = sFilenameRAW:sub(x, x);

            if (ssChar:find("[%a]")) then
                sFilename = sFilename.."["..ssChar:upper()..ssChar:lower().."]";
            else
                sFilename = sFilename..ssChar;
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

loadFile = function(sPath)
    local f = assert(io.open(sPath, "rb"));
    local sData = f:read("*a");
    f:close();
    return sData;
end

constant("CSV_BEFORE", 0);
constant("CSV_AFTER", 1);

local CSV = class("CSV",
{--METAMETHODS

},
{--STATIC PUBLIC
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --CSV = function(this) end, --static constructor (runs after class object creation)
},
{--PRIVATE

},
{--PROTECTED
    columnCount     = 0,
    columnIDByName  = {},
    columnNames     = {},
    delimiter       = ",",
    escapeChar      = "\\",
    escapeTempChar  = "CSV__b54484f9__CSV",
    rows            = {},
    rowsRaw         = {}, --keeps raw row data for adding, removing rows and resetting meta for rows
    rowCount        = 0,
    caselessFunction = function() end,

    getColumnInfo = function(this, cdat, vColumn)
        local tRet;
        local pro = cdat.pro;
        local zColumn = rawtype(vColumn);
        local nColumnCount = pro.columnCount;

        if (zColumn == "number") then
            type.assert.number(vColumn, false, true, false, true, false, -1, nColumnCount);

            if (vColumn == -1) then
                tRet = {index = nColumnCount, name = pro.columnNames[nColumnCount]};
            else
                tRet = {index = vColumn, name = pro.columnNames[vColumn]};
            end

        elseif (zColumn == "string") then

            if (pro.columnIDByName[vColumn] ~= nil) then
                tRet = {index = pro.columnIDByName[vColumn], name = vColumn};
            end

        end

        return tRet;
    end,

    parseCallback = function(this, cdat, sInput)
        local sRet = "";
        local pro = cdat.pro;
        local sDelimiter    = pro.delimiter;
        local sEscapeChar   = pro.escapeChar;
        local sSearchString = sEscapeChar..sDelimiter;
        local sEscTempChar  = pro.escapeTempChar;

        sRet, _ = sInput:gsub(sEscTempChar, sSearchString);

        return sRet;
    end,

    parseCSVLine = function(this, cdat, sLine, pCSV)
        local tRet;
        local pro           = cdat.pro;
        local sDelimiter    = pro.delimiter;
        local sEscapeChar   = pro.escapeChar;
        local sSearchString = sEscapeChar..sDelimiter;
        local sEscTempChar  = pro.escapeTempChar;

        --check for escaped commas
        sLine, _ = sLine:gsub(sSearchString, sEscTempChar);
        tRet = sLine:totable(sDelimiter, true, pro.parseCallback);

        return tRet;
    end,

    setRowMeta = function(this, cdat, tRow, nRow)
        local pro = cdat.pro;
        local nColumnCount = pro.columnCount;

        local function fIterator()
        local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nColumnCount) then
                    return nIndex, tRow[nIndex];
                end

            end

        end

        local tDecoy    = {};
        local tMeta     = {
            __index = function(t, k)
                local zKey = type(k);
                local sRet = "";

                if (zKey == "number" and (k == -1 or (k >= 1 and k <= nColumnCount))) then

                    if (k == -1) then
                        sRet = tRow[nColumnCount];
                    else
                        sRet = tRow[k];
                    end

                elseif (zKey == "string") then
                
                    if (pro.columnIDByName[k] ~= nil) then
                        return tRow[pro.columnIDByName[k]];
                    else
                        --TODO ERROR
                    end

                else
                    --TODO ERROR
                end

                return sRet;

            end,
            __newindex = function(t, k, v)
                local zKey = type(k);



            end,
            __call = fIterator,
            __pairs = fIterator,
            __len = function() return nColumnCount end,
            __metatable = false;
            __ipairs
        };

        setmetatable(tDecoy, tMeta);
        return tDecoy;
    end,
},
{--PUBLIC
    CSV = function(this, cdat, sDelimiter, sData)

        if (rawtype(sDelimiter) == "string" and #sDelimiter == 1) then
            cdat.pro.delimiter = sDelimiter;
        end

    end,

    columnExists = function(this, cdat, vColumn)
        return cdat.pro.getColumnInfo(vColumn) ~= nil;
    end,
--TODO
    clear = function(this, cdat)

    end,
--TODO
    deleteColumn = function(this, cdat)
        local pro = cdat.pro;
        local tColumnInfo   = pro.getColumnInfo(vColumn);

        if not (tColumnInfo) then
            local zColumn       = rawtype(vColumn);
            local sColumnError  = "Invalid type given for column. Expected string or number, got "..zColumn..'.';

            if (zColumn == "string" or zColumn == "number") then
                sColumnError = "Column '"..sColumn.."' is not valid.";
            end

            error("CSV Error: Cannot get cell in row "..nRow..'. '..sColumnError, 2);
        end
    end,
--TODO
    deleteRow = function(this, cdat)

    end,
--TODO
    duplicateRow = function(this, cdat)

    end,
--TODO
    duplicateColumn = function(this, cdat)

    end,
--TODO
    eachCell = function(this, cdat, sColumn)
        --It usually returns all the values in a given column across all rows.
    end,

    eachColumn = function(this, cdat)
        local pro       = cdat.pro;
        local tRows     = pro.rowsRaw;
        local nRowCount = pro.rowCount;
        local nColumnID = 0;
        local nMax      = #pro.columnNames;

        return function()
            nColumnID = nColumnID + 1;

            if (nColumnID <= nMax) then
                local tData = {};

                for nRow, tRowData in ipairs(tRows) do
                    tData[nRow] = tRowData[nColumnID];
                end

                return nColumnID, tData;
            end

        end

    end,

    eachRow = function(this, cdat)
        local pro       = cdat.pro;
        local tRows     = pro.rows;
        local nRowID    = 0;
        local nMax      = pro.rowCount;

        return function()
            nRowID = nRowID + 1;

            if (nRowID <= nMax) then
                return nRowID, tRows[nRowID];
            end

        end

    end,
--TODO
    export = function(this, cdat, pFile)

    end,

    getCell = function(this, cdat, nRow, vColumn)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount);

        local tColumnInfo   = pro.getColumnInfo(vColumn);

        if not (tColumnInfo) then
            local zColumn       = rawtype(vColumn);
            local sColumnError  = "Invalid type given for column. Expected string or number, got "..zColumn..'.';

            if (zColumn == "string" or zColumn == "number") then
                sColumnError = "Column '"..sColumn.."' is not valid.";
            end

            error("CSV Error: Cannot get cell in row "..nRow..'. '..sColumnError, 2);
        end

        return pro.rowsRaw[nRow][tColumnInfo.index];
    end,

    --returns all row data a single column
    getColumn = function(this, cdat, vColumn)
        local pro           = cdat.pro;
        local tRet          = {};
        local tRows         = pro.rowsRaw;
        local tColumnInfo   = pro.getColumnInfo(vColumn);

        if not (tColumnInfo) then
            --TODO ERROR
        end

        local nColumnID = tColumnInfo.index;

        for nRow, tRowData in ipairs(tRows) do
            tRet[nRow] = tRowData[nColumnID];
        end

        return tRet;
    end,

    getColumnCount = function(this, cdat)
        return cdat.pro.columnCount;
    end,

    getColumnIndex = function(this, cdat, sColumn)
        return cdat.pro.columnIDByName[sColumn] or nil;
    end,


    --[[!
        @fqxn CSV.getColumnName
        @des Gets the name of a column given its index.
        @param number nColumn The column index.
        @ret string sColumn The name of the column.
    !]]
    getColumnName = function(this, cdat, nColumn)
        local pro = cdat.pro;
        type.assert.number(nColumn, true, true, false, true, false, 1, pro.columnCount);
        return cdat.pro.columnNames[nColumn];
    end,

    getColumnNames = function(this, cdat)
        local tRet = {};

        for nIndex, sName in ipairs(cdat.pro.columnNames) do
            tRet[nIndex] = sName;
        end

        return tRet;
    end,

    getRow = function(this, cdat, nRow)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount);
        return pro.rows[nRow];
    end,

    getRowCount = function(this, cdat)
        return cdat.pro.rowCount;
    end,

    import = function(this, cdat, pCSV, bIgnoreCase)
        type.assert.string(pCSV, "%S+");
        local pro           = cdat.pro;
        local bHasHeader    = #pro.columnNames > 0;
        bIgnoreCase         = rawtype(bIgnoreCase) == "boolean" and bIgnoreCase or false;
        local fCase         = bIgnoreCase and caselessFunction or string.lower;

        --open the file
        local hFile = io.open(pCSV, "r");

        if (hFile) then
            local tImportRows   = {};
            local tImportHeader = {};

            --load the rows from the file into the tImportRows table
            for sRow in hFile:lines() do

                if sRow:match("%S") then --do not allow blank lines
                    table.insert(tImportRows, sRow);
                end

            end

            hFile:close();

            if (tImportRows) then
                --import the header
                local tImportHeader     = pro.parseCSVLine(tImportRows[1], pCSV);
                local nImportColumns    = #tImportHeader;
                local nColumns          = pro.columnCount;

                --check that the header matches and the columns align
                if (bHasHeader) then

                    if (nColumns ~= nImportColumns) then --TODO update errors with concat and file
                        error("CSV Import Error: Column count mismatch — expected "..nColumns.." columns, got "..nImportColumns..'.', 2);
                    end

                    local tHeader = pro.columnNames;
                    for nColumn = 1, nColumns do

                        if (tImportHeader[nColumn]:fCase() ~= tHeader[nColumn]:fCase()) then
                            error("CSV Import Error: Column columnNames name mismatch at index "..nColumn.." — expected \""..tHeader[nColumn]:fCase().."\", got \""..tImportHeader[nColumn]:fCase()..'".', 2);
                        end

                    end

                else
                    pro.columnCount = nImportColumns;
                    nColumns        = nImportColumns;

                    for nColumn, sColumn in ipairs(tImportHeader) do
                        pro.columnNames[nColumn]      = sColumn;
                        pro.columnIDByName[sColumn]   = nColumn;
                    end

                end

                --pro.columnNames =
                table.remove(tImportRows, 1);

                --iterate over the rows, parsing and validating each one
                for nRow, sRow in ipairs(tImportRows) do
                    local tRow = pro.parseCSVLine(sRow);

                    if (#tRow ~= nColumns) then
                        error("CSV Import Error: Malformed row — Expected "..nColumns.." columns in row #"..nRow..", got "..#tRow..'.', 2);
                    end

                    pro.rowCount        = pro.rowCount + 1;
                    local tDecoy        = pro.setRowMeta(tRow, nRow);
                    pro.rows[nRow]      = tDecoy;
                    pro.rowsRaw[nRow]   = tRow;
                    end

            else
                error("CSV Import Error: Failed to read file: \""..pCSV..'\".', 2);
            end

        else
            error("CSV Import Error: File does not exist: \""..pCSV..'\".', 2);
        end

    end,
--TODO
    insertColumn = function(this, cdat, sColumn, vValues, vIndex)
        type.assert.string(sColumn, "%S+");
        local nIndex = rawtype(vIndex) == "number" and vIndex or -1;
        local zValues = type(vValues);

        if zValues == "table" then
            --LEFT OFF HERE
        end

        type.assert.number(vColumn, false, true, false, true, false, -1, nColumnCount);
    end,
--TODO
    insertRow = function(this, cdat, tData, nPosition)
        --nPosition can be nil for at end, -1 for at front or insert value id..can use letters for up, down, left, right etc.
    end,
    --TODO
    moveColumn = function(this, cdat, vColumn, nPosition)
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount);
    end,
--TODO
    moveRow = function(this, cdat, nRow, nPosition)

    end,
--TODO
    renameColumn = function(this, cdat, vColumn, sName)

    end,

    rowExists = function(this, cdat, nRow)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1);
        return pro.rows[nRow] ~= nil;
    end,
--TODO
    sortByColumn = function(this, cdat, nColumn)

    end,
--TODO
    setCell = function(this, cdat, nRow, nColumn)

    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);


local oRes = CSV();
oRes.import(sSourcePath.."\\Resource.csv", true);

oRes.getRow(1).name = "Boots"
oRes.getRow(1).name = "Cats"
local tRow = oRes.getRow(1);
--print((oRes.getRow(1).name))
for k, v in oRes.getRow(1)() do
--print(oRes.getColumnName(k), v)
end

for k, v in ipairs(oRes.getColumnNames()) do
    --print(k, v)
end

for id, data in ipairs(oRes.getColumn(2)) do
    --print(id, data)
end

print(oRes.getCell(1, "name"))

--print(oRes.columnExists("name"));

--print(oRes.getColumnIndex("name"))

return CSV;
