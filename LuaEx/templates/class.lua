local nSpro	= class.args.staticprotected;
local nPri 	= class.args.private;
local nPro 	= class.args.protected;
local nPub 	= class.args.public;
local nIns	= class.args.instances;

--__metamethod(args, ...)
--nonmetamethod(this, args, ...)
--e.g.

--local spro = args[nSpro];
--local pri = args[nPri];
--local pro = args[nPro];
--local pub = args[nPub];
--local ins = args[nIns];

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
