return class("MyClass",
{--METAMETHODS

},
{--STATIC PUBLIC
    --MyClass = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    MyClass = function(this, cdat)

    end,
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
