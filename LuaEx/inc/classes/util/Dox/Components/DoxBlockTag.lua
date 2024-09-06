--[[!
    @fqxn Dox.Components.DoxBlockTag
    @des Used to create BlockTags used in a Dox parser.<br>While Dox ships with many pre-made BlockTags, users may also create and add their own by subclassing Dox.
    @ex
    local bRequired         = true;
    local bMultipleAllowed  = false;
    local bCombined         = false;
    local oFQXN             = DoxBlockTag({"fqxn"}, "FQXN", bRequired, bMultipleAllowed, bCombined);
    --TODO more examples
!]]

--TODO localization
local math = math;

return class("DoxBlockTag",
{--metamethods
    __clone = function(this, cdat)
        local pri = cdat.pri;
        return DoxBlockTag( clone(pri.aliases), pri.display, pri.required,
                            pri.multipleAllowed, pri.combined, pri.columnCount - 1,
                            table.unpack(pri.columnWrappers));
    end,
    __eq = function(left, right, cdat)
        local pri  = cdat.pri;
        local opri = cdat.ins[left].pri;

        if (opri == pri) then
            opri = cdat.ins[right].pri;
        end

        local tMyAliases    = clone(pri.aliases);
        local tOtherAliases = opri.aliases;
        local bAliasesMatch = #tMyAliases == #tOtherAliases;

         if (bAliasesMatch) then

            for nIndex, sOtherAlias in ipairs(tOtherAliases) do

                if (not tMyAliases[nIndex]) then
                    bAliasesMatch = false;
                    break;
                end

                if (tMyAliases[nIndex] ~= sOtherAlias) then
                    bAliasesMatch = false;
                    break;
                end

            end

        end


        return  bAliasesMatch                               and
                pri.display         == opri.display         and
                pri.required        == opri.required        and
                pri.multipleAllowed == opri.multipleAllowed and
                pri.combined        == opri.combined;
    end,
    __tostring = function(this, cdat)--TODO add column info
        local pri = cdat.pri;
        local sRet = "Display: "..pri.display;
        sRet = sRet.."\nRequired: "..pri.required;
        sRet = sRet.."\nMultiple Allowed: "..pri.multipleAllowed;
        sRet = sRet.."\nCombined: "..pri.combined;
        sRet = sRet.."\nAliases:";

        for _, sAlias in pairs(pri.aliases) do
            sRet = sRet.."\n    "..sAlias;
        end

        return sRet;
    end,
},
{--static public

},
{--private
    aliases             = {},
    columnCount         = 1,  --NOTE: this does NOT include the tag column.
    columnWrappers      = {}, --NOTE: this does NOT include the tag column. That wrapper is set in Dox.
    combined            = false,
    display             = "",
    --items_AUTO          = 0,
    multipleAllowed     = false,
    required            = false,
},
{--protected

},
{--public
    DoxBlockTag = function(this, cdat, tAliases, sDisplay, bRequired, bMultipleAllowed, bCombined, nExtraColumns, ...)
        local pri = cdat.pri;
        type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.");

        pri.display         = sDisplay;
        pri.multipleAllowed = type(bMultipleAllowed)   == "boolean"  and bMultipleAllowed                       or false;
        pri.combined        = type(bCombined)          == "boolean"  and (bCombined and pri.multipleAllowed)    or false;
        pri.required        = type(bRequired)          == "boolean"  and bRequired                              or false;

        for _, sAlias in ipairs(tAliases) do
            type.assert.string(sAlias, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
            pri.aliases[#cdat.pri.aliases + 1] = sAlias:lower();
        end

        --set the column count
        pri.columnCount = (rawtype(nExtraColumns) == "number" and nExtraColumns > 0) and
                          (pri.columnCount + math.floor(nExtraColumns))         or
                           pri.columnCount;

        --build the default wrappers for the columns
        for x = 1, pri.columnCount do
            pri.columnWrappers[x] = {
                [1] = "",
                [2] = "",
            };
        end

        --import any wrappers that the user has input
        for nColumn, tFormat in ipairs({...} or arg) do
            type.assert.table(tFormat, "number", "string", 2, 2);
            --set the wrapper for the not-first column
            pri.columnWrappers[nColumn] = clone(tFormat);
        end

    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.isCombined
    @desc Determines whether all items using this block tag will be combined into one section in the final output.
    <br><strong>Note</strong>: Even if this is set to true upon creation, it will logically auto-set to false if multiple of this <strong>BlockTag</strong> are not allowed.
    @return boolean bCombined Returns true if combined, false otherwise.
    !]]
    isCombined = function(this, cdat)
        return cdat.pri.combined;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.isMultipleAllowed
    @desc Determines whether multiple of this <strong>BlockTag</strong> are allowed.
    @return boolean bCombined Returns true if multiple are allowed, false otherwise.
    !]]
    isMultipleAllowed = function(this, cdat)
        return cdat.pri.multipleAllowed;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.isRequired
    @desc Determines whether this <strong>BlockTag</strong> is required in every block.
    @return boolean bRequired Returns true if it's required, false otherwise.
    !]]
    isRequired = function(this, cdat)
        return cdat.pri.required;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.getDisplay
    @desc Gets the display title of this <strong>BlockTag</strong>.
    @return boolean bRequired Returns true if it's required, false otherwise.
    !]]
    getDisplay = function(this, cdat)
        return cdat.pri.display;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.getColumnCount
    @desc Gets the total number of text columns in this <strong>BlockTag</strong>.
    <br>For example, the Return(s) <strong>BlockTag</strong> has three total columns:
    <br>The first for the type, the second for example variable name, the third for the description of the return value.
    @return number nColumns The number of the columns in this <strong>BlockTag</strong>.
    !]]
    getColumnCount = function(this, cdat)
        return cdat.pri.columnCount;
    end,
    getcolumnWrapper = function(this, cdat, nColumn)
        type.assert.number(nColumn, true, true, false, true, false);
        local tRet = {[1] = "", [2] = ""};

        if (cdat.pri.columnWrappers[nColumn]) then
            tRet = clone(cdat.pri.columnWrappers[nColumn]);
        end

        return tRet;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.hasAlias
    @desc Determines whether a given alias exists in this <strong>BlockTag</strong>.
    @param string sAlias The alias to check.
    @return boolean bExists Returns true if the input alias exists, false otherwise.
    !]]
    hasAlias = function(this, cdat, sInputRaw)
        local bRet      = false;
        local sInput    = sInputRaw:lower();

        for _, sAlias in pairs(cdat.pri.aliases) do

            if (sAlias == sInput) then
                bRet = true;
                break;
            end

        end

        return bRet;
    end,
    --[[!
    @fqxn Dox.Methods.eachAlias
    @desc Returns an iterator that returns each alias in this <strong>BlockTag</strong>.
    @return function fIterator The iterator.
    !]]
    eachAlias = function(this, cdat)
        local nIndex    = 0;
        local tAliases  = cdat.pri.aliases;
        local nMax      = #tAliases;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return tAliases[nIndex];
            end

        end

    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
