--__metamethod(this, [other], cdat, ...)
--nonmetamethod(this, cdat, ...)
--e.g.

return class("myclass",
{--metamethods

},
{--static public

},
{--private

},
{--protected

},
{--public

},
nil,    --extending class
false,   --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
