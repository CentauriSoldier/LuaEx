local nSpro	= class.args.staticprotected;
local nPri 	= class.args.private;
local nPro 	= class.args.protected;
local nPub 	= class.args.public;
local nIns	= class.args.instances;

--__metamethod(args, ...)
--nonmetamethod(this, args, ...)
--e.g. 

--spro = args[nSpro];
--pri = args[nPri];
--pro = args[nPro];
--pub = args[nPub];
--ins = args[nIns];

local myclass = class(
"myclass",
{--metamethods

},
{--static protected

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
nil,    --interface(s) (either nil, an interface or a table of interfaces)
false  --if the class is final
);

return myclass;
