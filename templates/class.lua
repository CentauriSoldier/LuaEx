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
nil,    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
false   --if the class is final
);
