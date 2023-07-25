local tInterfaces = {};

local function interface(sName, tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic)

--TODO assert variable co,pliant string and does not exist
	--assert(type(sName))
	---assert(type(tInterfaces[sName]) == "nil", "Error creating")
	--assert function names

	tInterfaces[sName] = {
		metamethods 	= {},
		staticprotected = {},
		staticpublic 	= {},
		private			= {},
		protected		= {},
		public			= {},
	};

	local tVisibilties = {
		metamethods 	= tMetamethods,
		staticprotected = tStaticProtected,
		staticpublic 	= tStaticPublic,
		private			= tPrivate,
		protected		= tProtected,
		public			= tPublic,
	};


	for sVisibility, tFunctionNames in pairs(tVisibilties) do

		for _, sFunction in pairs(tFunctionNames) do
			--assert string names here
            assert()
		end

	end

end





--[[
function getArgs(fun)
local args = {}
local hook = debug.gethook()

local argHook = function( ... )
    local info = debug.getinfo(3)
    if 'pcall' ~= info.name then return end

    for i = 1, math.huge do
        local name, value = debug.getlocal(2, i)
        if '(*temporary)' == name then
            debug.sethook(hook)
            error('')
            return
        end
        table.insert(args,name)
    end
end

debug.sethook(argHook, "c")
pcall(fun)

return args
end

and you can use like this:

print(getArgs(fun))




function GetArgs(func)
    local args = {}
    for i = 1, debug.getinfo(func).nparams, 1 do
        table.insert(args, debug.getlocal(func, i));
    end
    return args;
end

function a(bc, de, fg)
end

for k, v in pairs(GetArgs(a)) do
  print(k, v)
end


]]

return interface;
