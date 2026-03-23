--TODO FINISH working to make this a grid class, from wehich CSV will be subclassesd.

--[[!
    @fqxn LuaEx.Classes.Grid.Constants.GRID_BEFORE
    @des (number) 0
!]]
constant("GRID_BEFORE", 0);
--[[!
    @fqxn LuaEx.Classes.Grid.Constants.GRID_AFTER
    @des (number) 1
!]]
constant("GRID_AFTER", 1);

--[[!
    @fqxn LuaEx.Classes.Grid
    @des Represents a mutable, in-memory <strong>Grid</strong> data set. The <strong>Grid</strong> class encapsulates tabular data composed of ordered columns and rows, providing both row-oriented and column-oriented access patterns.
    @TODO Add optional, read only cells, rows, columns
    @TODO Delimiter adjuster method.
    @TODO Escape character adjuster method.
!]]
local Grid = class("Grid",
{--METAMETHODS

},
{--STATIC PUBLIC
},
{--PRIVATE

},
{--PROTECTED
    caseSensitiveLookup = true,
    columnCount         = 0,
    columnIDByName      = {},
    columnNames         = {},
    delimiter           = ",",
    rowCount            = 0,
    rows                = {},
    rowsRaw             = {},

    getColumnInfo = function(this, cdat, vColumn, bErrorOnFail, sPrefix)
        local pro       = cdat.pro;
        local zColumn   = type(vColumn);
        local sErr      = rawtype(sPrefix) == "string" and sPrefix or "";
        local nColumn;
        local sName;

        if (zColumn == "number") then
            type.assert.number(vColumn, false, true, false, true, false, -1, pro.columnCount, sErr.."Invalid column index.", 1);
            nColumn = (vColumn == -1) and pro.columnCount or vColumn;
            sName = pro.columnNames[nColumn];

        elseif (zColumn == "string") then
            local sKey = pro.caseSensitiveLookup and vColumn or vColumn:upper()
            nColumn = pro.columnIDByName[sKey];

            if (nColumn == nil) then
                if (bErrorOnFail) then
                    error(sErr.."Column \""..tostring(vColumn).."\" does not exist.", 2);
                end

                return nil;
            end

            sName = pro.columnNames[nColumn];

        else
            if (bErrorOnFail) then
                error(sErr.."Column must be a number or string. Got "..zColumn..".", 2);
            end

            return nil;
        end

        return {
            index   = nColumn,
            name    = sName,
        };
    end,

    setRowMeta = function(this, cdat, tRow)
        local pro           = cdat.pro;
        local nColumnCount  = pro.columnCount;

        local function fIterator()
            local nIndex = 0;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nColumnCount) then
                    return nIndex, tRow[nIndex];
                end

            end

        end

        local tDecoy = {};
        local tMeta  = {
            __index = function(t, k)
                local zKey = type(k);

                if (zKey == "number") then
                    local nIndex = (k == -1) and nColumnCount or k;

                    if (nIndex >= 1 and nIndex <= nColumnCount) then
                        return tRow[nIndex];
                    end

                    return nil;

                elseif (zKey == "string") then
                    local sKey          = pro.caseSensitiveLookup and k or k:upper()
                    local nColumnID     = pro.columnIDByName[sKey];
                    return nColumnID    ~= nil and tRow[nColumnID] or nil;
                end

                return nil;
            end,
            __newindex = function(t, k, v)
                local zKey = type(k);
                local nColumnID;

                if (zKey == "number") then
                    nColumnID = (k == -1) and nColumnCount or k;
                    type.assert.number(nColumnID, false, true, false, true, false, 1, nColumnCount, "\nGrid Error: Invalid row column index.", 1);

                elseif (zKey == "string") then
                    local sKey = pro.caseSensitiveLookup and k or k:upper()
                    nColumnID = pro.columnIDByName[sKey];

                    if (nColumnID == nil) then
                        error("\nGrid Error: Column \""..tostring(k).."\" does not exist.", 2);
                    end

                else
                    error("\nGrid Error: Invalid row key type \""..zKey.."\".", 2);
                end

                tRow[nColumnID] = tostring(v);
            end,
            __call = fIterator,
            __pairs = fIterator,
            __len = function()
                return nColumnCount;
            end,
            __metatable = false,
        };

        setmetatable(tDecoy, tMeta);
        return tDecoy;
    end,
},
{--PUBLIC

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.Grid
        @des The constructor for the class.
        @param string|nil sDelimiter The delimiter string to use for parsing and export. If omitted, a comma is used.
    !]]
    Grid = function(this, cdat, sDelimiter)
        local pro = cdat.pro;

        if (rawtype(sDelimiter) ~= "nil") then

            if (rawtype(sDelimiter) ~= "string") then
                error("\nGrid Error in 'Grid': Delimiter must be a string or nil. Got "..rawtype(sDelimiter)..".", 2);
            end

            if (#sDelimiter == 0) then
                error("\nGrid Error in 'Grid': Delimiter cannot be empty.", 2);
            end

            pro.delimiter = sDelimiter;

        end
    end,


    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.columnExists
        @des Detrmines whether a column exists.
        @param number|string vColumn The index or name of the column to check.
        @ret boolean bExists A boolean value indicating whether the column exists.
    !]]
    columnExists = function(this, cdat, vColumn)
        local pro = cdat.pro;

        if (type(vColumn) == "number") then
            local nColumn = (vColumn == -1) and pro.columnCount or vColumn;
            return nColumn >= 1 and nColumn <= pro.columnCount;

        elseif (type(vColumn) == "string") then
            local sKey = pro.caseSensitiveLookup and vColumn or vColumn:upper()
            return pro.columnIDByName[sKey] ~= nil;

        end

        return false;
    end,

    clear = function(this, cdat)
        local pro = cdat.pro;
        pro.rows = {};
        pro.rowsRaw = {};
        pro.rowCount = 0;
        return this;
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.deleteRow
        @des Deletes a row from the Grid object.
        @param number nRow The index of the row delete.
        @ret Grid oGrid The Grid object.
    !]]
    deleteRow = function(this, cdat, nRowRaw)
        type.assert.number(nRowRaw, false, true, false, true, false, -1, nil, "\nGrid Error in 'deleteRow': Invalid input for row.", 1);
        local pro       = cdat.pro;
        local nRowCount = pro.rowCount;
        local nRow      = (nRowRaw == -1) and nRowCount or nRowRaw;

        if (nRowCount == 0) then
            error("\nGrid Error in 'deleteRow': There are no rows to delete.");
        end

        type.assert.number(nRow, false, true, false, true, false, 1, nRowCount, "\nGrid Error in 'deleteRow': Row is out of bounds.", 1);

        table.remove(pro.rows, nRow);
        table.remove(pro.rowsRaw, nRow);

        pro.rowCount = pro.rowCount - 1;

        return this;
    end,

    duplicateRow = function(this, cdat)
        error("Not yet implemented.");
    end,

    duplicateColumn = function(this, cdat)
        error("Not yet implemented.");
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.eachCell
        @des Returns a sequential iterator that goes through every cell in the Grid, row by row and column by column.
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
            if (nRowID > nMaxRows) then
                return nil;
            end

            nColumnID = nColumnID + 1;

            if (nColumnID > nMaxColumns) then
                nColumnID = 1;
                nRowID = nRowID + 1;

                if (nRowID > nMaxRows) then
                    return nil;
                end
            end

            return nRowID, nColumnID, tColumnNames[nColumnID], tRows[nRowID][nColumnID];
        end

    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.eachColumn
        @des Returns a sequential iterator that steps over each column in the Grid object.
        @ret function fColumns A sequential iterator function that, when traversed, returns the column index, column name, and column table (whose keys are row indices and values are cell data) on each iteration.
    !]]
    eachColumn = function(this, cdat)
        local pro           = cdat.pro;
        local tRows         = pro.rowsRaw;
        local tColumnNames  = pro.columnNames;
        local nMaxColumns   = pro.columnCount;
        local nColumnID     = 0;

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
        @fqxn LuaEx.Classes.Grid.Methods.eachRow
        @des Returns a sequential iterator that steps over each row in the Grid object.
        @ret function fRows A sequential iterator function that, when traversed, returns the row index and row table (whose keys are column indices and whose values are cell data) on each iteration.
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

    --[[!
    @fqxn LuaEx.Classes.Grid.Methods.export
    @des Exports the contents of the Grid object to file.
    @param string pFile The export file path.
    @param boolean|nil bAppend Whether the Grid contents should be appended to the export file. If appending, the Grid's header will not be included. If no argument is provided, the file will be overwritten by default instead of appended.
    @ret Grid oGrid The Grid object.
    !]]
    export = function(this, cdat, pFile, vAppend)
        local pro               = cdat.pro;
        local bAppend           = rawtype(vAppend) == "boolean" and vAppend or false;
        local sMode             = bAppend and "a+" or "w";
        local tRows             = pro.rowsRaw;
        local sDelimiter        = pro.delimiter;
        local nColumnCount      = pro.columnCount;
        local sNewLine          = "\n";
        local sBlank            = "";
        local sData             = "";
        local bAppendNewline    = true;

        local hFile = io.open(pFile, sMode);

        if (not hFile) then
            error("bad file stuff here.");
        end

        if (bAppend) then
            local sFile = hFile:read("*a");
            bAppendNewline = sFile:sub(-1) ~= "\n";
        else
            for nColumn, sColumn in ipairs(pro.columnNames) do
                sData = sData..sColumn..((nColumn < nColumnCount) and sDelimiter or sBlank);
            end
        end

        for nRow, tRow in ipairs(tRows) do
            if ((nRow == 1 and bAppendNewline) or nRow ~= 1) then
                sData = sData..sNewLine;
            end

            for nColumn, sCellData in ipairs(tRow) do
                sData = sData..sCellData..((nColumn < nColumnCount) and sDelimiter or sBlank);
            end
        end

        sData = sData..sNewLine;

        hFile:write(sData);
        hFile:close();

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.fromFile
        @des Replaces the Grid's contents with data parsed from a delimiter-separated file. This method reads the file contents, then passes the raw text to <strong>fromString</strong>.
        @param string pFile The file path from which to read the Grid data.
        @ret Grid oGrid The Grid object.
    !]]
    fromFile = function(this, cdat, pFile)
        type.assert.string(pFile, "%S+", "\nGrid Error in 'fromFile': Invalid file path.", 1);

        local hFile = io.open(pFile, "r");

        if not (hFile) then
            error("\nGrid Error in 'fromFile': Could not open file \""..tostring(pFile).."\".", 2);
        end

        local sData = hFile:read("*a");
        hFile:close();

        if (rawtype(sData) ~= "string") then
            error("\nGrid Error in 'fromFile': Could not read file \""..tostring(pFile).."\".", 2);
        end

        return this.fromString(sData);
    end,


    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.fromString
        @des Replaces the Grid's contents with data parsed from a delimiter-separated string. The first record is treated as the header row.
        @param string sData The raw delimiter-separated text to parse.
        @ret Grid oGrid The Grid object.
    !]]
    fromString = function(this, cdat, sData)
        type.assert.string(sData, nil, "\nGrid Error in 'fromString': Invalid input for string data.", 1);
        local pro           = cdat.pro;
        local sDelimiter    = pro.delimiter;
        local nDelimiterLen = #sDelimiter;
        local nLength       = #sData;
        local nIndex        = 1;
        local nRecord       = 1;
        local tRecords      = {};

        local function pushField(tFields, tBuffer)
            tFields[#tFields + 1] = table.concat(tBuffer);
        end

        local function pushRecord(tFields)
            local bBlank = (#tFields == 1 and tFields[1] == "");

            if not (bBlank and #tRecords > 0) then
                tRecords[#tRecords + 1] = tFields;
            end
        end

        local function parse()
            local tFields    = {};
            local tBuffer    = {};
            local bInQuotes  = false;

            while (nIndex <= nLength) do
                local sChar = sData:sub(nIndex, nIndex);

                if (bInQuotes) then

                    if (sChar == "\"") then
                        local sNext = sData:sub(nIndex + 1, nIndex + 1);

                        if (sNext == "\"") then
                            tBuffer[#tBuffer + 1] = "\"";
                            nIndex = nIndex + 2;
                        else
                            bInQuotes = false;
                            nIndex = nIndex + 1;
                        end

                    else
                        tBuffer[#tBuffer + 1] = sChar;
                        nIndex = nIndex + 1;
                    end

                else

                    if (sChar == "\"") then
                        bInQuotes = true;
                        nIndex = nIndex + 1;

                    elseif (sData:sub(nIndex, nIndex + nDelimiterLen - 1) == sDelimiter) then
                        pushField(tFields, tBuffer);
                        tBuffer = {};
                        nIndex = nIndex + nDelimiterLen;

                    elseif (sChar == "\r") then
                        pushField(tFields, tBuffer);
                        pushRecord(tFields);
                        tFields = {};
                        tBuffer = {};
                        nRecord = nRecord + 1;

                        if (sData:sub(nIndex + 1, nIndex + 1) == "\n") then
                            nIndex = nIndex + 2;
                        else
                            nIndex = nIndex + 1;
                        end

                    elseif (sChar == "\n") then
                        pushField(tFields, tBuffer);
                        pushRecord(tFields);
                        tFields = {};
                        tBuffer = {};
                        nRecord = nRecord + 1;
                        nIndex = nIndex + 1;

                    else
                        tBuffer[#tBuffer + 1] = sChar;
                        nIndex = nIndex + 1;
                    end

                end

            end

            if (bInQuotes) then
                error("\nGrid Error in 'fromString': Unterminated quoted field in record "..nRecord..".", 2);
            end

            pushField(tFields, tBuffer);
            pushRecord(tFields);
        end

        -- strip UTF-8 BOM if present
        if (sData:sub(1, 3) == "\239\187\191") then
            sData = sData:sub(4);
            nLength = #sData;
        end

        -- reset everything
        pro.rows            = {};
        pro.rowsRaw         = {};
        pro.rowCount        = 0;
        pro.columnCount     = 0;
        pro.columnNames     = {};
        pro.columnIDByName  = {};

        if (sData == "") then
            return this;
        end

        parse();

        if (#tRecords == 0) then
            return this;
        end

        -- build header
        do
            local tHeader = tRecords[1];

            if (#tHeader == 0) then
                error("\nGrid Error in 'fromString': Header row is empty.", 2);
            end

            pro.columnCount = #tHeader;

            for nColumn = 1, pro.columnCount do
                local sColumn = tostring(tHeader[nColumn] or "");
                local sKey    = pro.caseSensitiveLookup and sColumn or sColumn:upper();

                if (pro.columnIDByName[sKey] ~= nil) then
                    error("\nGrid Error in 'fromString': Duplicate column name \""..sColumn.."\" in header.", 2);
                end

                pro.columnNames[nColumn]    = sColumn;
                pro.columnIDByName[sKey]    = nColumn;
            end
        end

        -- build rows
        for nRow = 2, #tRecords do
            local tSourceRow = tRecords[nRow];
            local tRow       = {};

            if (#tSourceRow ~= pro.columnCount) then
                error(
                    "\nGrid Error in 'fromString': Record "..nRow..
                    " has "..#tSourceRow.." field(s); expected "..pro.columnCount..".",
                    2
                );
            end

            for nColumn = 1, pro.columnCount do
                tRow[nColumn] = tostring(tSourceRow[nColumn] or "");
            end

            pro.rowCount = pro.rowCount + 1;
            pro.rowsRaw[pro.rowCount] = tRow;
            pro.rows[pro.rowCount] = pro.setRowMeta(tRow);
        end

        return this;
    end,


    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getCell
        @des Retrieves the cell data given the row and column.
        @param number nRow The index of the row from which to get the data.
        @param number|string vColumn The index or name of the column from which to get the data.
        @ret table tData A numerically-indexed table whose keys are the row indices and whose values are the cell data.
    !]]
    getCell = function(this, cdat, nRow, vColumn)
        local pro = cdat.pro;
        local nRowResolved = (nRow == -1) and pro.rowCount or nRow;
        type.assert.number(nRowResolved, false, true, false, true, false, 1, pro.rowCount, "\nGrid Error in 'getCell': Row is out of bounds or invalid.", 1);
        local tColumnInfo = pro.getColumnInfo(vColumn, true, "\nError in 'getCell': Cannot get cell in row "..nRowResolved..". ");
        return pro.rowsRaw[nRowResolved][tColumnInfo.index];
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getColumn
        @des Retrieves all cell data from all rows in a given column.
        @param number|string vColumn The index or name of the column from which to get the data.
        @ret table tData A numerically-indexed table whose keys are the row indices and whose values are the cell data.
    !]]
    getColumn = function(this, cdat, vColumn)
        local pro           = cdat.pro;
        local tRet          = {};
        local tRows         = pro.rowsRaw;
        local tColumnInfo   = pro.getColumnInfo(vColumn, true, "\nError in getColumn: Cannot get column.");
        local nColumnID     = tColumnInfo.index;

        for nRow, tRowData in ipairs(tRows) do
            tRet[nRow] = tRowData[nColumnID];
        end

        return tRet;
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getColumnCount
        @des Gets the total number of columns in the Grid object.
        @ret number nColumns The total number of columns.
    !]]
    getColumnCount = function(this, cdat)
        return cdat.pro.columnCount;
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getColumnIndex
        @des Gets the index of a column given its name.
        @param string sColumn The column name.
        @ret number nColumn The index of the column or nil if it doesn't exist.
    !]]
    getColumnIndex = function(this, cdat, sColumn)
        local pro = cdat.pro;
        local sKey = pro.caseSensitiveLookup and sColumn or sColumn:upper()
        return cdat.pro.columnIDByName[sKey] or nil;
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getColumnName
        @des Gets the name of a column given its index.
        @param number nColumn The column index.
        @ret string sColumn The name of the column.
    !]]
    getColumnName = function(this, cdat, nColumn)
        local pro = cdat.pro;
        local nResolved = (nColumn == -1) and pro.columnCount or nColumn;
        type.assert.number(nResolved, true, true, false, true, false, 1, pro.columnCount, "\nGrid Error in 'getColumnName': Invalid column index given.", 1);
        return cdat.pro.columnNames[nResolved];
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getColumnNames
        @des Gets the names of all columns in teh Grid object.
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
        @fqxn LuaEx.Classes.Grid.Methods.getRow
        @des Gets the row table for given the row's index.
        @param number nRow The row table to get.
        @ret table tRow The row table whose indices are column indices and whose values are cell data.
    !]]
    getRow = function(this, cdat, nRow)
        local pro = cdat.pro;
        local nResolved = (nRow == -1) and pro.rowCount or nRow;
        type.assert.number(nResolved, false, true, false, true, false, 1, pro.rowCount, "\nGrid Error in 'getRow': Invalid row index given.", 1);
        return pro.rows[nResolved];
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getRowCount
        @des Gets the total number of rows in the Grid object.
        @ret number nRows The total number of rows in the Grid object.
    !]]
    getRowCount = function(this, cdat)
        return cdat.pro.rowCount;
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.insertRow
        @des inserts one to many rows starting at the provided index <em>(or at the end of the Grid rows table if no position is indicated)</em>.
        @param number|nil nPosition The position at which to insert the row(s). If set to nil or -1, appends the rows to the end of the Grid.
        @param string|table|nil vData The value to insert into each of the row's cells. If nothing is provided, a blank string will be inserted. If a non-nil, non-table value is provided, it will be coerced to a string and inserted into each cell. If a table is provided <em>(that has numerical indices equal to the number of columns and whose values are strings or things that can be coerced into a string)</em>, the table's data will be inserted at each relative position.
        @param number|nil The number of rows to insert. By default, if no valid argument is provided, one row will be inserted.
        @ret Grid oGrid The Grid object.
    !]]
    insertRow = function(this, cdat, vPosition, vDataInput, vRows)
        local pro               = cdat.pro;
        local nPosition         = vPosition;
        local zData             = type(vDataInput);
        local bDataIsTable      = zData == "table";
        local vData             = zData ~= "nil" and (bDataIsTable and vDataInput or tostring(vDataInput)) or "";
        local nRows             = (rawtype(vRows) == "number") and (vRows > 0 and vRows or 1) or 1;
        local nColumnCount      = pro.columnCount;

        if (rawtype(nPosition) ~= "number") then
            nPosition = pro.rowCount + 1;
        else
            type.assert.number(nPosition, false, true, false, true, false, -1, pro.rowCount + 1, "\nGrid Error in 'insertRow': Invalid input for row insert position.", 1);
            nPosition = (nPosition == -1) and (pro.rowCount + 1) or nPosition;
        end

        if (bDataIsTable) then
            for nColumnID = 1, nColumnCount do
                if (rawget(vData, nColumnID) == nil) then
                    error("bad things here!!!");
                end
            end
        end

        for nRow = 1, nRows do
            local tRow = {};

            for nColumnIndex = 1, nColumnCount do
                tRow[nColumnIndex] = bDataIsTable and tostring(rawget(vData, nColumnIndex)) or vData;
            end

            local nIndex = nPosition + nRow - 1;

            table.insert(pro.rowsRaw, nIndex, tRow);
            table.insert(pro.rows, nIndex, pro.setRowMeta(tRow));
            pro.rowCount = pro.rowCount + 1;
        end

        return this;
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.rowExists
        @des Detrmines whether a row exists.
        @param number nRow The index of the row to check.
        @ret boolean bExists A boolean value indicating whether the row exists.
    !]]
    rowExists = function(this, cdat, nRow)
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, nil, "\nGrid Error in 'rowExists': Invalid input for row.", 1);
        local nResolved = (nRow == -1) and pro.rowCount or nRow;
        return nResolved >= 1 and nResolved <= pro.rowCount and pro.rows[nResolved] ~= nil;
    end,

    sortByColumn = function(this, cdat, nColumn)
        error("Not yet implemented.");
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.setCell
        @des Sets the cell data given the row and column.
        @param number nRow The index of the row at which to set the data.
        @param number|string vColumn The index or name of the column at which to set the data.
        @param Any vData The cell data <em>(that will be coerced into a string if not already)</em>.
        @ret boolean bExists A boolean value indicating whether the row exists.
    !]]
    setCell = function(this, cdat, nRow, vColumn, vValue)
        local pro           = cdat.pro;
        local nRowResolved  = (nRow == -1) and pro.rowCount or nRow;
        type.assert.number(nRowResolved, false, true, false, true, false, 1, pro.rowCount, "\nGrid Error in 'setCell': Invalid input for row.", 1);
        local tColumnInfo = cdat.pro.getColumnInfo(vColumn, true, "\nError in 'setCell'.");
        pro.rowsRaw[nRowResolved][tColumnInfo.index] = tostring(vValue);

        return this;
    end,

},
nil,
false,
nil
);

return Grid;
