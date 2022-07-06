local rawtype 		= rawtype;
local pairs 		= pairs;
local setmetatable 	= setmetatable;
local type 			= type;

local function dummy() end

local function errbit()
	error("Attempt to perform biwise operation on struct factory constructor.", 3);
end

local function errmath()
	error("Attempt to perform mathmatical operation on struct factory constructor.", 3);
end

local function errlen()
	error("Attempt to get length of struct factory constructor.", 3);
end

local function erriterate()
	error("Attempt to iterate over struct factory constructor.", 3);
end

local function errbitinstance()
	error("Attempt to perform biwise operation on struct factory.", 3);
end

local function errmathinstance()
	error("Attempt to perform mathmatical operation on struct factory.", 3);
end

local function errleninstance()
	error("Attempt to get length of struct factory.", 3);
end

local function erriterateinstance()
	error("Attempt to iterate over struct factory.", 3);
end

--metadata of factory factories
local tMetaData = {
	count = 0,
	--[[private = {
		count 		= 0,
		factories 	= {},
	},
	public 	= {
		count 		= 0,
		factories 	= {},
	},]]
};

local function propertiestableisvalid(tProperties)
	local bRet = false;
	local nKeyCount = 0;

	if (type(tProperties) == "table") then

		for vKey, _ in pairs(tProperties) do

			if (rawtype(vKey) == "string") then
				nKeyCount = nKeyCount + 1;
			else
				bRet = false;
				break;
			end

		end

		bRet = nKeyCount > 0;
	end

	return bRet;
end


--TODO go throug this to make sure all the values are accessing the correct tbales (tfactory, tFactory, etc.)
local function createfactory(sSubType, tProperties)--, bPrivate)
	--[[
	 ______            _                         _____                    _                       _
	 |  ____|          | |                       / ____|                  | |                     | |
	 | |__  __ _   ___ | |_  ___   _ __  _   _  | |      ___   _ __   ___ | |_  _ __  _   _   ___ | |_  ___   _ __
	 |  __|/ _` | / __|| __|/ _ \ | '__|| | | | | |     / _ \ | '_ \ / __|| __|| '__|| | | | / __|| __|/ _ \ | '__|
	 | |  | (_| || (__ | |_| (_) || |   | |_| | | |____| (_) || | | |\__ \| |_ | |   | |_| || (__ | |_| (_) || |
	 |_|   \__,_| \___| \__|\___/ |_|    \__, |  \_____|\___/ |_| |_||___/ \__||_|    \__,_| \___| \__|\___/ |_|
	                                      __/ |
	                                     |___/
	--creates the factory object
	]]
	local tConstraint = {};
	assert(rawtype(sSubType) == "string" and sSubType:gsub("[%s]", "") ~= "", "Error creating factory. Argument 1 (Subtype) must be a non-blank string.");
	assert(rawtype(tMetaData[sSubType]) == "nil", "Error creating struct factory. Factory of subtype '"..sSubType.."' already exists; Cannot overwrite.")
	assert(propertiestableisvalid(tProperties), "Error creating struct factory. Argument 2 (Properies Input Table) must be of type table and have at least one key.");

	local nKeyCount = 0;

	for vKey, vValue in pairs(tProperties) do
		nKeyCount = nKeyCount + 1;
		tConstraint[vKey] = {
			type 			= type(vValue),
			defaultvalue 	= vValue,
		};
	end

	--[[
	______            _
	|  ____|          | |
	| |__  __ _   ___ | |_  ___   _ __  _   _
	|  __|/ _` | / __|| __|/ _ \ | '__|| | | |
	| |  | (_| || (__ | |_| (_) || |   | |_| |
	|_|   \__,_| \___| \__|\___/ |_|    \__, |
										__/ |
									   |___/
	this is the factory which creates the factory instance objects
	]]
	local tFactory = setmetatable({},
	{
		__add 		= errmath,--TODO perhaps add the ability to combine them...maybe thruogh concat though, not add
		__band 		= errbit,
		__bor 		= errbit,
		__bnot 		= errbit,
		__bxor 		= errbit,
		--[[

		]]
		__call 		= function(this, tInputArgs)
			local tArgs		= type(tInputArgs) == "table" and tInputArgs or nil;
			local tFactory 	= {};

			--setup the default values first
			for sKey, tVals in pairs(tConstraint) do
				tFactory[sKey] = {
					type 	= tVals.type,
					value 	= tVals.defaultvalue,
				};
			end

			--next, try to process any valid input
			if (tArgs) then

				for sKey, vValue in pairs(tArgs) do

					--make certain the key exists in the tConstraint table
					if (rawtype(tConstraint[sKey]) ~= "nil") then
						local vFinalValue 	= vValue;
						local sValType 		= type(vValue);
						local bValueIsNull	= sValType == "null";

						--handle cases of default tConstraint value types being null
						if (tConstraint[sKey].type == "null" and not bValueIsNull) then
							tFactory[sKey].type = sValType;
						end

						--be sure the value type is correct
						if (sValType == tConstraint[sKey].type or bValueIsNull) then
							tFactory[sKey] = {
								type 	= sValType,
								value 	= vFinalValue,
							};
						end

					end

				end

			end
			--[[
			_____              _
			|_   _|            | |
			 | |   _ __   ___ | |_  __ _  _ __    ___  ___
			 | |  | '_ \ / __|| __|/ _` || '_ \  / __|/ _ \
			_| |_ | | | |\__ \| |_| (_| || | | || (__|  __/
			|_____||_| |_||___/ \__|\__,_||_| |_| \___|\___|
			--factory instance object created by a call to the factory
			]]
			return setmetatable({}, {
				__close 	= false,
				__concat	= errmathinstance,
				__div		= errmathinstance,
				__eq 		= eq,--TODO finish
				__gc		= false,
				__idiv		= errmathinstance,
				__ipairs	= erriterateinstance,
				__le		= le,--TODO finish
				__len 		= errleninstance,
				__lt		= lt,--TODO finish
				__mod		= errmathinstance,
				__call 		= function()--TODO finish
					---TODO make ieterator
				end,
				__index 	= function(t, k)
					return tFactory[k].value;
				end,
				__lt = function(l, r)
					return false;
				end,
				__mul		= errmathinstance,
				__name		= sSubType.." struct",
				__newindex 	= function(t, k, v)

					--make certain the key exists in the table
					if (rawtype(tFactory[k]) ~= "nil") then
						local vFinalValue	= v;
						local sValType 		= type(v);
						local bValueIsNull	= sValType == "null";
						local bValueIsNil	= (not bValueIsNull) and sValType == "nil";

						--handle cases of default value types being null
						if (tFactory[k].type == "null" and not bValueIsNull and not bValueIsNil) then
							tFactory[k].type = sValType;
						end

						--account for nil values
						if (bValueIsNil) then
							vFinalValue = null;
						end
--TODO handle nulls separately!!!!!!!!! This is gummin gup the works
						--be sure the value type is correct
						if (sValType == tFactory[k].type or bValueIsNull or tFactory[k] == null) then
							tFactory[k] = {
								--type 	= sValType,
								value 	= vFinalValue,
							};
						end

					end

				end,
				__pairs		= erriterateinstance,
				__pow		= errmathinstance,
				__shl  		= errbitinstance,
				__shr  		= errbitinstance,
				__sub		= errbitinstance,
				__subtype	= sSubType,
				__tostring	= tostr,--TODO finish
				__type		= "struct",
				__unm		= errmathinstance,
			});
		end,
		--factory constructor metatable
		__close 	= false,
		__concat	= errmath,
		--__count 	= factoryscount,
		__div		= errmath,
		__eq 		= eq,
		__gc		= false,
		__idiv		= errmath,
		__index 	= dummy,
		__ipairs	= erriterate,
		__le		= le,--TODO finish
		__len 		= errlen,
		__lt		= lt,--TODO finish
		__mod		= errmath,
		--__mode,
		--__metatable	= nil,
		__mul		= errmath,
		__name		= sSubType.." struct factory",
		__newindex 	= dummy,
		__pairs		= erriterate,
		__pow		= errmath,
		__shl  		= errbit,
		__shr  		= errbit,
		__sub		= errbit,
		__subtype	= sSubType,
		__tostring	= function()--TODO finish
			local sRet = "";

			for sKey, tVals in pairs(tConstraint) do

				sRet = sRet..""
			end

			return sRet;
		end,
		__type		= "struct factory",
		__unm		= errmath,
	});

	--save the metadata
	--local sMetaKey = bPrivate and "private" or "public";
	--tMetaData[sMetaKey].count = tMetaData[sMetaKey].count + 1;
	--tMetaData[sMetaKey].factories[sSubType] = {
	--	factory = tFactory,
	--	name 	= sSubType,
	--};
	tMetaData.count = tMetaData.count + 1;

	return tFactory;
end

local function factorycount()
	--return tMetaData.public.count;
	return tMetaData.count;
end

local function getfactory(t, k)
	local tRet = nil;

	if (tMetaData.public.factories[k]) then
		tRet = tMetaData.public.factories[k].factory;
	end

	return tRet;
end

return setmetatable({
	--istype(sType)--TODO finishb n
	factory = createfactory,
},
{
	__call 		= dummy,
	__index 	= dummy,--getfactory,
	__len 	 	= factorycount,
	__newindex 	= dummy,
	__subtype	= "struct",
	__type 		= "factory constructor",
});
