return class("Vehicle",
{--METAMETHODS

},
{--STATIC PUBLIC
    --Vehicle = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    Vehicle = function(this, cdat, super, eType, eComposition)
        super(eType, eComposition);
    end,
},
{--PUBLIC

},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
