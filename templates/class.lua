return class("MyClass",
{--METAMETHODS

},
{--STATIC PUBLIC
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --MyClass = function(this) end, --static constructor (runs after class object creation)
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
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
