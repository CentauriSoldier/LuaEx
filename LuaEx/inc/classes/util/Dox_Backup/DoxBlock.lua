return class("DoxBlock",
{--METAMETHODS

},
{--STATIC PUBLIC

},
{--PRIVATE
    --parseBlock

    isModule    = false,
    type        = "",
},
{--PROTECTED

},
{--PUBLIC
    DoxBlock = function(this, cdat, sBlockType, tBlockItems)
        type.assert.string(sBlockType, "%S+", "Block cannot be blank.");
        type.assert.table(tBlockItems, "number", "string", 1);

        local pri       = cdat.pri;
        pri.isModule    = type(bIsModule) == "boolean" and bIsModule or false;
        pri.type        = sBlockType;


        print(sBlockType, serialize(tBlockItems))


    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
