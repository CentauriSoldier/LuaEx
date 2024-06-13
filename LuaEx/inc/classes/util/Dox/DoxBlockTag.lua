--TODO localization
local math = math;

return class("DoxBlockTag",
{--metamethods
    __clone = function(this, cdat)
        local pri = cdat.pri;
        return DoxBlockTag(clone(pri.aliases), pri.display, pri.required, pri.multipleAllowed);
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
    __tostring = function(this, cdat)
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
    columnCount         = 1,
    columnWrappers      = {
        [1] = {
            [1] = "",
            [2] = "",
        },
    },
    display             = "",
    --items_AUTO          = 0,
    multipleAllowed     = false,
    required            = false,
},
{--protected

},
{--public
    DoxBlockTag = function(this, cdat, tAliases, sDisplay, bRequired, bMultipleAllowed, nColumns, ...)
        local pri = cdat.pri;
        type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.");

        pri.display         = sDisplay;
        pri.multipleAllowed = type(bMultipleAllowed)   == "boolean"  and bMultipleAllowed    or false;
        pri.required        = type(bRequired)          == "boolean"  and bRequired           or false;

        for _, sAlias in ipairs(tAliases) do
            type.assert.string(sAlias, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
            pri.aliases[#cdat.pri.aliases + 1] = sAlias:lower();
        end

        pri.columnCount = (rawtype(nColumns) == "number" and nColumns > 0) and math.floor(nColumns) or pri.columnCount;


        for nColumn, tFormat in pairs(arg or {...}) do
            print(sDisplay)
            if (nColumn > 0) then
                print(nColumn, tFormat)
                local _, sError = xpcall(type.assert.table(tFormat, "number", "string", 2, 2));

                if (sError) then --allows nil input
                    pri.columnWrappers[nColumn] = {
                        [1] = {
                            [1] = "",
                            [2] = "",
                        },
                    };
                else
                    pri.columnWrappers[nColumn] = clone(tFormat);
                end

            end

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
        type.assert.number(nColumn, true, true, false, true, false, 2);
        return cdat.pri.columnWrappers[nColumn] or {[1] = "", [2] = ""};
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
