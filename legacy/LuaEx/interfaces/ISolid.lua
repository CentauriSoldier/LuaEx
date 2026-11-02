return interface("ISolid",
{   --metamethods
    --"__clone",
    --"__serialize",
},
{   --static public
    --"deserialize"
},
{}, --private
{}, --protected
{   --public
    "scale",
    "translate",
    "translateTo",
},
nil --ISerializable, ICloneable --extending interface
);
