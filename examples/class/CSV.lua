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
--TODO optional read only cells, rows, columns

--[[!
    @fqxn CSV.Constants.CSV_BEFORE
    @des (number) 0
!]]
constant("CSV_BEFORE", 0);
--[[!
    @fqxn CSV.Constants.CSV_AFTER
    @des (number) 1
!]]
constant("CSV_AFTER", 1);

--[[!
    @fqxn CSV
    @des Represents a mutable, in-memory CSV (Comma-Separated Values) data set.
         The CSV class encapsulates tabular data composed of named columns and
         ordered rows, providing both row-oriented and column-oriented access
         patterns. Rows are exposed through protected proxy tables that support
         indexed, named, and iterable access while preserving internal raw data
         structures.

         The class supports importing CSV files using a configurable delimiter
         and escape character, retrieving and mutating individual cells, rows,
         and columns, and iterating sequentially over rows, columns, or cells.
         Column metadata (names, indices, and mappings) is maintained internally
         to allow flexible access by index or name.

         This implementation prioritizes structured access, mutability, and
         iterator-based traversal over strict RFC 4180 compliance.
!]]
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
    caseFunction    = function() end,
    columnCount     = 0,
    columnIDByName  = {},
    columnNames     = {},
    delimiter       = ",",
    escapeChar      = "\\",
    escapeTempChar  = "CSV__b54484f9__CSV",
    rows            = {}, --holds public-facing decoy tables that reference rowsRaw
    rowsRaw         = {}, --keeps raw row data for adding, removing rows and resetting meta for rows
    rowCount        = 0,

    getColumnInfo = function(this, cdat, vColumn, bThrowError, sErrorMessage)
        local tRet;
        local pro = cdat.pro;
        local zColumn = rawtype(vColumn);
        local nColumnCount = pro.columnCount;
--TODO FINISH account for case here and whereever else is needed!!! !
        if (zColumn == "number") then
            type.assert.number(vColumn, false, true, false, true, false, -1, nColumnCount, 2);

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

        if (not tRet and bThrowError)  then
            local sColumnError  = "CSV Error: Invalid type given for column. Expected string or number, got "..zColumn..'.';

            if (zColumn == "string" or zColumn == "number") then
                sColumnError = "CSV Error: Column '"..tostring(vColumn).."' is not valid.";
            end

            error(sColumnError.."\n"..sErrorMessage, 3);
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

    --[[!
        @fqxn CSV.Methods.CSV
        @des The constructor for the class.
        @param string|nil sDelimiter The delimiter to use for the object. If nothing is provided, the default (comma [,]) will be used.
    !]]
    CSV = function(this, cdat, sDelimiter, sData)

        if (rawtype(sDelimiter) == "string" and #sDelimiter == 1) then
            cdat.pro.delimiter = sDelimiter;
        end

    end,

    --[[!
        @fqxn CSV.Methods.columnExists
        @des Detrmines whether a column exists.
        @param number|string vColumn The index or name of the column to check.
        @ret boolean bExists A boolean value indicating where the column exists.
    !]]
    columnExists = function(this, cdat, vColumn)
        return cdat.pro.getColumnInfo(vColumn) ~= nil;
    end,
--TODO
    clear = function(this, cdat)

    end,
--TODO
    deleteColumn = function(this, cdat, vColumn)
        local pro = cdat.pro;
        local tColumnInfo   = pro.getColumnInfo(vColumn, true, "Could not delete column.");
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


    --[[!
        @fqxn CSV.Methods.eachCell
        @des Returns a sequential iterator that goes through every cell in the CSV, row by row and column by column.
        @ret function fCells A sequential iterator function that, when traversed, returns for each iteration:
        <ul>
            <li>Row Index</li>
            <li>Column Index</li>
            <li>Column Name</li>
            <li>Cell Value</li>
        </ul>
    !]]
    eachCell = function(this, cdat)
        local pro           = cdat.pro;
        local tRows         = pro.rowsRaw;
        local nRowID        = 1;
        local nColumnID     = 0;
        local nMaxRows      = pro.rowCount;
        local nMaxColumns   = pro.columnCount;
        local tColumnNames  = pro.columnNames;

        return function()

            if (nRowID <= nMaxRows) then
                nColumnID = nColumnID + 1;

                if (nColumnID <= nMaxColumns) then
                    return nRowID, nColumnID, tColumnNames[nColumnID], tRows[nRowID][nColumnID];
                else
                    nColumnID = 1;
                    nRowID = nRowID + 1;

                    if (nRowID <= nMaxRows) then
                        return nRowID, nColumnID, tColumnNames[nColumnID], tRows[nRowID][nColumnID];
                    end

                end

            end

        end

    end,


    --[[!
        @fqxn CSV.Methods.eachColumn
        @des Returns a sequential iterator that steps over each column in the CSV object.
        @ret function fColumns A sequential iterator function that, when traversed, returns the column index, column name, and column table (whose keys are row indices and values are cell data) on each iteration.
    !]]
    eachColumn = function(this, cdat)
        local pro           = cdat.pro;
        local tRows         = pro.rowsRaw;
        local nRowCount     = pro.rowCount;
        local nColumnID     = 0;
        local tColumnNames  = pro.columnCount;
        local nMaxColumns   = #tColumnNames;

        return function()
            nColumnID = nColumnID + 1;

            if (nColumnID <= nMaxColumns) then
                local tData = {};

                for nRow, tRowData in ipairs(tRows) do
                    tData[nRow] = tRowData[nColumnID];
                end

                return nColumnID, tColumnNames[nColumnID], tData;
            end

        end

    end,


    --[[!
        @fqxn CSV.Methods.eachRow
        @des Returns a sequential iterator that steps over each row in the CSV object.
        @ret function fRows A sequential iterator function that, when traversed, returns the row index and row table (whose keys are column indices and values are cell data) on each iteration.
    !]]
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


    --[[!
        @fqxn CSV.Methods.getCell
        @des Retrieves the cell data given the row and column.
        @param number nRow The index of the row from which to get the data.
        @param number|string vColumn The index or name of the column from which to get the data.
        @ret table tData A numerically-indexed table whose keys are the row indices and whose values are the cell data.
    !]]
    getCell = function(this, cdat, nRow, vColumn)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount, "\nCSV Error in 'getCell': Row is out of bounds or invalid.", 1);
        local tColumnInfo   = pro.getColumnInfo(vColumn, true, "\nCSV Error in 'getCell': Cannot get cell in row "..nRow..'. ');
        return pro.rowsRaw[nRow][tColumnInfo.index];
    end,


    --[[!
        @fqxn CSV.Methods.getColumn
        @des Retrieves all cell data from all rows in a given column.
        @param number|string vColumn The index or name of the column from which to get the data.
        @ret table tData A numerically-indexed table whose keys are the row indices and whose values are the cell data.
    !]]
    getColumn = function(this, cdat, vColumn)
        local pro           = cdat.pro;
        local tRet          = {};
        local tRows         = pro.rowsRaw;
        local tColumnInfo   = pro.getColumnInfo(vColumn);

        local nColumnID = tColumnInfo.index;

        for nRow, tRowData in ipairs(tRows) do
            tRet[nRow] = tRowData[nColumnID];
        end

        return tRet;
    end,


    --[[!
        @fqxn CSV.Methods.getColumnCount
        @des Gets the total number of columns in the CSV object.
        @ret number nColumns The total number of columns.
    !]]
    getColumnCount = function(this, cdat)
        return cdat.pro.columnCount;
    end,


    --[[!
        @fqxn CSV.Methods.getColumnIndex
        @des Gets the index of a column given its name.
        @param string sColumn The column name.
        @ret number nColumn The index of the column or nil if it doesn't exist.
    !]]
    getColumnIndex = function(this, cdat, sColumn)
        return cdat.pro.columnIDByName[sColumn] or nil;
    end,


    --[[!
        @fqxn CSV.Methods.getColumnName
        @des Gets the name of a column given its index.
        @param number nColumn The column index.
        @ret string sColumn The name of the column.
    !]]
    getColumnName = function(this, cdat, nColumn)
        local pro = cdat.pro;
        type.assert.number(nColumn, true, true, false, true, false, 1, pro.columnCount, "\nCSV Error in 'getColumnName': Invalid column index given.", 1);
        return cdat.pro.columnNames[nColumn];
    end,


    --[[!
        @fqxn CSV.Methods.getColumnNames
        @des Gets the names of all columns in teh CSV object.
        @ret table tColumnNames A numerically-indexed table whose keys are column indices and whose values are column names.
    !]]
    getColumnNames = function(this, cdat)
        local tRet = {};

        for nIndex, sName in ipairs(cdat.pro.columnNames) do
            tRet[nIndex] = sName;
        end

        return tRet;
    end,


    --[[!
        @fqxn CSV.Methods.getRow
        @des Gets the row table for given the row's index.
        @param number nRow The row table to get.
        @ret table tRow The row table whose indices are column indices and whose values are cell data.
    !]]
    getRow = function(this, cdat, nRow)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount, "\nCSV Error in 'getRow': Invalid row index given.", 1);
        return pro.rows[nRow];
    end,


    --[[!
        @fqxn CSV.Methods.getRowCount
        @des Gets the total number of rows in the CSV object.
        @ret number nRows The total number of rows in the CSV object.
    !]]
    getRowCount = function(this, cdat)
        return cdat.pro.rowCount;
    end,


    import = function(this, cdat, pCSV, bIgnoreCase)
        type.assert.string(pCSV, "%S+", "\nCSV Error in 'import':Filepath cannot be blank.", 1);
        local pro           = cdat.pro;
        local bHasHeader    = #pro.columnNames > 0;
        bIgnoreCase         = rawtype(bIgnoreCase) == "boolean" and bIgnoreCase or false;
        local fCase         = bIgnoreCase and pro.caseFunction or string.lower;

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
                        error("CSV Import Error in 'import': Column count mismatch — expected "..nColumns.." columns, got "..nImportColumns..'.', 2);
                    end

                    local tHeader = pro.columnNames;
                    for nColumn = 1, nColumns do

                        if (tImportHeader[nColumn]:fCase() ~= tHeader[nColumn]:fCase()) then
                            error("CSV Import Error in 'import': Column name mismatch at index "..nColumn.." — expected \""..tHeader[nColumn]:fCase().."\", got \""..tImportHeader[nColumn]:fCase()..'".', 2);
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

        type.assert.number(vColumn, false, true, false, true, false, -1, nColumnCount, 2);
    end,
--TODO
    insertRow = function(this, cdat, tData, nPosition)
        --nPosition can be nil for at end, -1 for at front or insert value id..can use letters for up, down, left, right etc.
    end,
    --TODO
    moveColumn = function(this, cdat, vColumn, nPosition)
        type.assert.number(nPosition, false, true, false, true, false, -1, pro.rowCount, "\nCSV Error in 'moveColumn': Invalid input for column position.", 1);
    end,
--TODO
    moveRow = function(this, cdat, nRow, nPosition)

    end,
--TODO
    renameColumn = function(this, cdat, vColumn, sName)

    end,


    --[[!
        @fqxn CSV.Methods.rowExists
        @des Detrmines whether a row exists.
        @param number nRow The index of the row to check.
        @ret boolean bExists A boolean value indicating where the row exists.
    !]]
    rowExists = function(this, cdat, nRow)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, nil, "\nCSV Error in 'rowExists': Invalid input for row.", 1);
        return pro.rows[nRow] ~= nil;
    end,
--TODO
    sortByColumn = function(this, cdat, nColumn)

    end,
--TODO
    setCell = function(this, cdat, nRow, vColumn, vValue)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, nil, "\nCSV Error in 'setCell': Invalid input for row.", 1);
        local tColumnInfo = cdat.pro.getColumnInfo(vColumn, true, "\nError in 'setCell'.");
        pro.rowsRaw[nRow][tColumnInfo.index] = tostring(vValue);
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

for row, column, name, data in oRes.eachCell() do
    print(row, column, name, data)
end

--oRes.setCell(1, 2, "BoogA!")
--print(oRes.getCell(1, 2))


--print(oRes.columnExists("name"));

--print(oRes.getColumnIndex("name"))

return CSV;
