return class("Vehicle",
{--METAMETHODS

},
{--STATIC PUBLIC
    --MyClass = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED
    MyClass = function(this, cdat, super, eType, eComposition)
        super(eType, eComposition);
    end,
},
{--PUBLIC

},
Actor,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
