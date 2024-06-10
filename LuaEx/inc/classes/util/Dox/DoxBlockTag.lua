
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
    display             = "",
    --items_AUTO          = 0,
    multipleAllowed     = false,
    required            = false,
},
{--protected

},
{--public
    DoxBlockTag = function(this, cdat, tAliases, sDisplay, bRequired, bMultipleAllowed)
        type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.");
        --type.assert.number(nItems, true, true, false, true);


        cdat.pri.display         = sDisplay;
        --cdat.pri.items           = nItems;--TODO what is this?
        cdat.pri.multipleAllowed = type(bMultipleAllowed)   == "boolean"  and bMultipleAllowed    or false;
        cdat.pri.required        = type(bRequired)          == "boolean"  and bRequired           or false;

        for _, sAlias in ipairs(tAliases) do
            type.assert.string(sAlias, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
            cdat.pri.aliases[#cdat.pri.aliases + 1] = sAlias:lower();
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
