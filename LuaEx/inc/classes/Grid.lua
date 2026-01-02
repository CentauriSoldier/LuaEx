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
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --Grid = function(this) end, --static constructor (runs after class object creation)
},
{--PRIVATE

},
{--PROTECTED
    columnCount         = 0,
    rows                = {}, --holds public-facing decoy tables that reference rowsRaw
    --rowsRaw             = {}, --keeps raw row data for adding, removing rows and resetting meta for rows
    rowCount            = 0,

    setRowMeta = function(this, cdat, tRow)
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
                error("Not yet implemented.")


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
        @fqxn LuaEx.Classes.Grid.Methods.Grid
        @des The constructor for the class.
    !]]
    Grid = function(this, cdat)
    end,

    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.columnExists
        @des Detrmines whether a column exists.
        @param number nColumn The index of the column to check.
        @ret boolean bExists A boolean value indicating whether the column exists.
    !]]
    columnExists = function(this, cdat, nColumn)
        return 
    end,
    --TODO
    clear = function(this, cdat)
        error("Not yet implemented.")
    end,
    --TODO
    --@param number|string vColumn The index or name of the column from which to get the data.
    deleteColumn = function(this, cdat, vColumn)
        error("Not yet implemented.")
        local pro = cdat.pro;
        local tColumnInfo   = pro.getColumnInfo(vColumn, true, "Could not delete column.");
        --local nColumnCount

        if (nColumnCount == 0) then
            error("\nGrid Error in 'deleteColumn': There are no columns to delete.");
        end

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

        --remove the row
        table.remove(pro.rows[nRow]);
        table.remove(pro.rowsRaw[nRow]);

        --update the row count
        pro.rowCount = pro.rowCount - 1;

        return this;
    end,


    --TODO
    duplicateRow = function(this, cdat)
        error("Not yet implemented.");
    end,
    --TODO
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
        @fqxn LuaEx.Classes.Grid.Methods.eachColumn
        @des Returns a sequential iterator that steps over each column in the Grid object.
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
        @fqxn LuaEx.Classes.Grid.Methods.eachRow
        @des Returns a sequential iterator that steps over each row in the Grid object.
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


    --[[!
    @fqxn LuaEx.Classes.Grid.Methods.export
    @des Exports the contents of the Grid object to file.
    @pararm string pFile The export file path.
    @param boolean|nil bAppend Whether the Grid contents should be appended to the export file. If appending, the Grid's header will not be included. If no argument is provided, the file will be overwritten by default instead of appended.
    @ret Grid oGrid The Grid object.
    !]]
    export = function(this, cdat, pFile, vAppend)
        --TODO file arg assertions
        local pro               = cdat.pro;
        local bAppend           = rawtype(vAppend) == "boolean" and vAppend or false;
        local sMode             = bAppend and "a+" or "w";
        local tRows             = pro.rowsRaw;
        local sDelimiter        = pro.delimiter;
        local nColumnCount      = pro.columnCount;
        local nRowCount         = pro.rowCount;
        local sNewLine          = "\n";
        local sBlank            = "";
        local sData             = "";
        local bAppendNewline    = true;

        local hFile             = io.open(pFile, sMode);

        if (not hFile) then
            error("bad file stuff here.")--TODO ERROR
        end

        --append the header (if needed) and check for ending newline
        if (bAppend) then
            local sFile = hFile:read("*a");
            bAppendNewline = sFile:sub(-1) ~= "\n";

        else

            for nColumn, sColumn in ipairs(pro.columnNames) do
                sData = sData..sColumn..( (nColumn < nColumnCount) and sDelimiter or sBlank);
            end

        end

        for nRow, tRow in ipairs(tRows) do

            if ( (nRow == 1 and bAppendNewline) or nRow ~= 1) then
                sData = sData..sNewLine;
            end

            for nColumn, sCellData in ipairs(tRow) do
                sData = sData..sCellData..( (nColumn < nColumnCount) and sDelimiter or sBlank);
            end

        end

        --append final newline --TODO allow skipping this
        sData = sData..sNewLine;

        --write and close the file
        hFile:write(sData);
        hFile:close();

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
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount, "\nGrid Error in 'getCell': Row is out of bounds or invalid.", 1);
        local tColumnInfo   = pro.getColumnInfo(vColumn, true, "\nError in 'getCell': Cannot get cell in row "..nRow..'. ');
        return pro.rowsRaw[nRow][tColumnInfo.index];
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

        local nColumnID = tColumnInfo.index;

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
        return cdat.pro.columnIDByName[sColumn] or nil;
    end,


    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getColumnName
        @des Gets the name of a column given its index.
        @param number nColumn The column index.
        @ret string sColumn The name of the column.
    !]]
    getColumnName = function(this, cdat, nColumn)
        local pro = cdat.pro;
        type.assert.number(nColumn, true, true, false, true, false, 1, pro.columnCount, "\nGrid Error in 'getColumnName': Invalid column index given.", 1);
        return cdat.pro.columnNames[nColumn];
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
        type.assert.number(nRow, false, true, false, true, false, -1, pro.rowCount, "\nGrid Error in 'getRow': Invalid row index given.", 1);
        return pro.rows[nRow];
    end,


    --[[!
        @fqxn LuaEx.Classes.Grid.Methods.getRowCount
        @des Gets the total number of rows in the Grid object.
        @ret number nRows The total number of rows in the Grid object.
    !]]
    getRowCount = function(this, cdat)
        return cdat.pro.rowCount;
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

        --determine (or set to default) the row insert position
        if (rawtype(nPosition) ~= "number") then
            nPosition = pro.rowCount + 1;
        else
            type.assert.number(nPosition, false, true, false, true, false, -1, pro.rowCount, "\nGrid Error in 'insertRow': Invalid input for row insert position.", 1);
            nPosition = (nPosition == -1) and (pro.rowCount + 1) or nPosition;
        end

        --verify the table's data if it's a table
        if (bDataIsTable) then

            for nColumnID = 1, nColumnCount do

                if (rawget(vData, nColumnID) == nil) then
                    error("bad things here!!!")--TODO ERROR
                end

            end

        end

        --create the row(s)
        for nRow = 1, nRows do

            --build the row table
            local tRow = {};

            for nColumnIndex = 1, nColumnCount do
                tRow[nColumnIndex] = bDataIsTable and tostring(rawget(vData, nColumnIndex)) or vData;
            end

            --update the actual insert position
            local nIndex = nPosition + nRow - 1;

            --store the row
            table.insert(pro.rowsRaw, nIndex, tRow);

            --create and store the row decoy
            local tDecoy = pro.setRowMeta(tRow);
            table.insert(pro.rows, nIndex, tDecoy);

            --update the row count
            pro.rowCount = pro.rowCount + 1;
        end

        return this;
    end,


    --TODO
    moveColumn = function(this, cdat, vColumn, nPosition)
        type.assert.number(nPosition, false, true, false, true, false, -1, pro.columnCount, "\nGrid Error in 'moveColumn': Invalid input for column position.", 1);
        local tColumnInfo = pro.getColumnInfo(vColumn, true, "\nError in renameColumn: Cannot rename column.");

    end,
--TODO

    moveRow = function(this, cdat, nRow, nPosition)

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
        return pro.rows[nRow] ~= nil;
    end,
    --TODO
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
        local pro = cdat.pro;
        type.assert.number(nRow, false, true, false, true, false, -1, nil, "\nGrid Error in 'setCell': Invalid input for row.", 1);
        local tColumnInfo = cdat.pro.getColumnInfo(vColumn, true, "\nError in 'setCell'.");
        pro.rowsRaw[nRow][tColumnInfo.index] = tostring(vValue);

        return this;
    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);


local oRes = Grid();
oRes.import(io.normalizepath(sSourcePath.."\\..\\resources\\Grid_Read_Test.csv"), false);

--TODO __newindex
--oRes.getRow(1).name = "Boots"
--oRes.getRow(1).name = "Cats"


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
    --print(row, column, name, data)
end

--oRes.setCell(1, 2, "BoogA!")
--oRes.insertRow(2, 67, 2);
--print(oRes.getCell(1, 2))
--print(oRes.getCell(2, 2))
--print(oRes.getCell(3, 2))
--print(oRes.getCell(4, 2))

--oRes.insertRow(7, "e", 4)
oRes.renameColumn("Symbol", "Booga44!");
oRes.export(io.normalizepath(sSourcePath.."\\..\\resources\\Grid_Write_Test.csv"), false);
--oRes.deleteRow(118);



oGrid = Grid();
--print(oGrid.getColumn(1))

--print(oRes.columnExists("name"));

--print(oRes.getColumnIndex("name"))

return Grid;
