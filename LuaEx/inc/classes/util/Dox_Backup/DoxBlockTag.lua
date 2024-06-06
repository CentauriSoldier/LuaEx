
return class("DoxBlockTag",
{--metamethods
    __clone = function(this, cdat)
        local pri = cdat.pri;
        return DoxBlockTag(clone(pri.names), pri.display, pri.items, pri.required, pri.multipleAllowed);
    end,
},
{--static public

},
{--private
    display             = "",
    items_AUTO          = 0,
    multipleAllowed     = false,
    names               = {},
    required            = false,
},
{--protected

},
{--public
    DoxBlockTag = function(this, cdat, tNames, sDisplay, nItems, bRequired, bMultipleAllowed)
        type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.");
        type.assert.number(nItems, true, true, false, true);


        cdat.pri.display         = sDisplay;
        cdat.pri.items           = nItems;
        cdat.pri.multipleAllowed = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;
        cdat.pri.required        = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;

        for _, sName in pairs(tNames) do
            type.assert.string(sName, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
            cdat.pri.names[#cdat.pri.names + 1] = sName;
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
    hasName = function(this, cdat, sName)
        local bRet = false;

        for _, sTagName in pairs(cdat.pri.names) do

            if (sTagName:lower() == sName:lower()) then
                bRet = true;
                break;
            end

        end

        return bRet;
    end,
    names = function(this, cdat)
        local nIndex = 0;
        local tNames = cdat.pri.names;
        local nMax   = #tNames;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return tNames[nIndex];
            end

        end

    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
