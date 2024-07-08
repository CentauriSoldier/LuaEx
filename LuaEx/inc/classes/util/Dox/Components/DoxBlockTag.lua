--[[!
    @fqxn LuaEx.Classes.Utility.Dox.Components.DoxBlockTag
    @des Used to create BlockTags used in a Dox parser.<br>While Dox ships with many pre-made BlockTags, users may also create and add their own by subclassing Dox.
    @ex
    local bRequired         = true;
    local bMultipleAllowed  = true;
    local oFQXN = DoxBlockTag({"fqxn"}, "FQXN", bRequired, -bMultipleAllowed);
    @author <a href="https://github.com/CentauriSoldier" target="_blank">Centauri Soldier</a>
    @github <a href="https://github.com/CentauriSoldier/LuaEx" target="_blank">Visit the LuaEx Github</a>
!]]

--TODO localization
local math = math;

return class("DoxBlockTag",
{--metamethods
    __clone = function(this, cdat)
        local pri = cdat.pri;
        return DoxBlockTag( clone(pri.aliases), pri.display, pri.required,
                            pri.multipleAllowed, pri.columnCount - 1,
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
                pri.multipleAllowed == pri.multipleAllowed;
    end,
    __tostring = function(this, cdat)--TODO add column info
        local pri = cdat.pri;
        local sRet = "Display: "..pri.display;
        sRet = sRet.."\nRequired: "..pri.required;
        sRet = sRet.."\nMultiple Allowed: "..pri.multipleAllowed;
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
    display             = "",
    --items_AUTO          = 0,
    multipleAllowed     = false,
    required            = false,
},
{--protected

},
{--public
    DoxBlockTag = function(this, cdat, tAliases, sDisplay, bRequired, bMultipleAllowed, nExtraColumns, ...)
        local pri = cdat.pri;
        type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.");

        pri.display         = sDisplay;
        pri.multipleAllowed = type(bMultipleAllowed)   == "boolean"  and bMultipleAllowed    or false;
        pri.required        = type(bRequired)          == "boolean"  and bRequired           or false;

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
    isMultipleAllowed = function(this, cdat)
        return cdat.pri.multipleAllowed;
    end,
    isRequired = function(this, cdat)
        return cdat.pri.required;
    end,
    clone = function(this, cdat) --OMG TODO
        return this;
    end,
    getDisplay = function(this, cdat)
        return cdat.pri.display;
    end,
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
    aliases = function(this, cdat)
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
