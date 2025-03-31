--[[!
    @fqxn Dox.Components.DoxBlockTag
    @des Used to create DoxBlockTags used in a Dox parser.<br>While Dox ships with many pre-made DoxBlockTags, users may also create and add their own by subclassing Dox.
    @ex
    local tAliases          = {"fqxn"};
    lcoal sDisplay          = "FQXN";
    local bRequired         = true;
    local bMultipleAllowed  = false;
    local bCombined         = false;
    local bUtil             = false;
    local nExtraColumns     = 0;
    local oFQXN             = DoxBlockTag(tAliases, sDisplay, bRequired, bMultipleAllowed, bCombined, bUtil, nExtraColumns);
    --TODO more examples
!]]

--TODO localization
local math = math;

return class("DoxBlockTag",
{--metamethods
    __clone = function(this, cdat)
        local pri = cdat.pri;
        return DoxBlockTag( clone(pri.aliases),     pri.display,    pri.required,
                            pri.multipleAllowed,    pri.combined,   pri.util,
                            pri.columnCount - 1);
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
                pri.combined        == opri.combined        and
                pri.util            == opri.util;
    end,
    __tostring = function(this, cdat)--TODO add column info
        local pri = cdat.pri;
        local sRet = "Display: "..pri.display;
        sRet = sRet.."\nRequired: "..pri.required;
        sRet = sRet.."\nMultiple Allowed: "..pri.multipleAllowed;
        sRet = sRet.."\nCombined: "..pri.combined;
        sRet = sRet.."\nUtil: "..pri.util;
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
    --columnWrappers      = {}, --NOTE: this does NOT include the tag column. That wrapper is set in Dox.
    combined            = false,
    display             = "",
    --items_AUTO          = 0,
    multipleAllowed     = false,
    required            = false,
    util                = false, --if it's util, it's just used as a util tag and shouldn't get added to the finalized data by the builder
},
{--protected

},
{--public
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.DoxBlockTag
    @desc This is the constructor for the class.
    @param table tAliases A table of aliases that may be used. Each alias must be unique to every other DoxBlockTag's alias. There must be at least one alias.
    @param string sDisplay The display text for the tag (as opposed to the alias).
    @param boolean|nil bRequired Whether this DoxBlockTag is required. Defaults to false if nil.
    @param boolean|nil bMultipleAllowed Whether multiple of this DoxBlockTag are permitted in a BoxBlock. Defaults to false if nil.
    @param boolean|nil bCombined Whether the content in each of multiple of this DoxBlockTag should be combined under one section. Defaults to false if nil.
    @param boolean|nil bIsUtil Whether this DoxBlockTag is a utility tag. If so, it may still be used by the builder but its contents should be ignored in the builder's final output. Defaults to false if nil.
    @param number|nil nExtraColumns The number of extra column this DoxBlockTag has. Defaults to 0 if nil. If set to 0, it will have the standard number of 3 total columns (as demonstrated in the \@param DoxBlockTag).
    !]]
    DoxBlockTag = function(this, cdat, tAliases, sDisplay, bRequired, bMultipleAllowed, bCombined, bIsUtil, nExtraColumns)
        local pri = cdat.pri;
        type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.");

        pri.display         = sDisplay;
        pri.multipleAllowed = type(bMultipleAllowed)   == "boolean"  and bMultipleAllowed                       or false;
        pri.combined        = type(bCombined)          == "boolean"  and (bCombined and pri.multipleAllowed)    or false;
        pri.required        = type(bRequired)          == "boolean"  and bRequired                              or false;
        pri.util            = type(bIsUtil)            == "boolean"  and bIsUtil                                or false;

        for _, sAlias in ipairs(tAliases) do
            type.assert.string(sAlias, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
            pri.aliases[#cdat.pri.aliases + 1] = sAlias:lower();
        end

        --set the column count
        pri.columnCount = (rawtype(nExtraColumns) == "number" and nExtraColumns > 0) and
                          (pri.columnCount + math.floor(nExtraColumns))         or
                           pri.columnCount;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.eachAlias
    @desc Returns an iterator that returns each alias in this <strong>DoxBlockTag</strong>.
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
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.getDisplay
    @desc Gets the display title of this <strong>DoxBlockTag</strong>.
    @return boolean bRequired Returns true if it's required, false otherwise.
    !]]
    getDisplay = function(this, cdat)
        return cdat.pri.display;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.getColumnCount
    @desc Gets the total number of text columns in this <strong>DoxBlockTag</strong>.
    <br>For example, the Return(s) <strong>DoxBlockTag</strong> has three total columns:
    <br>The first for the type, the second for example variable name, the third for the description of the return value.
    @return number nColumns The number of the columns in this <strong>DoxBlockTag</strong>.
    !]]
    getColumnCount = function(this, cdat)
        return cdat.pri.columnCount;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.hasAlias
    @desc Determines whether a given alias exists in this <strong>DoxBlockTag</strong>.
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
    @fqxn Dox.Components.DoxBlockTag.Methods.isCombined
    @desc Determines whether all items using this block tag will be combined into one section in the final output.
    <br><strong>Note</strong>: Even if this is set to true upon creation, it will logically auto-set to false if multiple of this <strong>DoxBlockTag</strong> are not allowed.
    @return boolean bCombined Returns true if combined, false otherwise.
    !]]
    isCombined = function(this, cdat)
        return cdat.pri.combined;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.isMultipleAllowed
    @desc Determines whether multiple of this <strong>DoxBlockTag</strong> are allowed.
    @return boolean bCombined Returns true if multiple are allowed, false otherwise.
    !]]
    isMultipleAllowed = function(this, cdat)
        return cdat.pri.multipleAllowed;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.isRequired
    @desc Determines whether this <strong>DoxBlockTag</strong> is required in every block.
    @return boolean bRequired Returns true if it's required, false otherwise.
    !]]
    isRequired = function(this, cdat)
        return cdat.pri.required;
    end,
    --[[!
    @fqxn Dox.Components.DoxBlockTag.Methods.isUtil
    @desc Determines whether this <strong>DoxBlockTag</strong> is utility. Utility tags are used by Builders and their contents should not included in the finalized output by the builder.
    @return boolean bUtil Returns true if it's mere utility, false otherwise.
    !]]
    isUtil = function(this, cdat)
        return cdat.pri.util;
    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
