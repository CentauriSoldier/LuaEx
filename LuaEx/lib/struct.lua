local pairs 		= pairs;
local setmetatable 	= setmetatable;
local type 			= type;

local function dummy() end

local function errbit()
	error("Attempt to perform biwise operation on struct constructor.", 3);
end

local function errmath()
	error("Attempt to perform mathmatical operation on struct constructor.", 3);
end

local function errlen()
	error("Attempt to get length of struct constructor.", 3);
end

local function erriterate()
	error("Attempt to iterate over struct constructor.", 3);
end

local function errbitinstance()
	error("Attempt to perform biwise operation on struct.", 3);
end

local function errmathinstance()
	error("Attempt to perform mathmatical operation on struct.", 3);
end

local function errleninstance()
	error("Attempt to get length of struct.", 3);
end

local function erriterateinstance()
	error("Attempt to iterate over struct.", 3);
end

local tMetaData = {
	structscount = 0,
};

--TODO go throug this to make sure all the values are accessing the correct tbales (tStruct, tFactory, etc.)
local function createfactory(__callingtable__, sSubType, vInput)
	local tStruct = {};
	assert(rawtype(sSubType) == "string" and sSubType:gsub("[%s]", "") ~= "", "Error creating struct. Argument 1 (Subtype) must be a non-blank string.");
	assert(rawtype(tMetaData[sSubType]) == "nil", "Error creating struct. Struct of subtype '"..sSubType.."' already exists; Cannot overwrite.")
	--TODO assert table, make sure it's good
	--TODO assert overrideing struct (these two items are in the first conditional below and can be moved up here)

	if (type(vInput) == "table") then
		local nKeyCount = 0;

		for sKey, vValue in pairs(vInput) do
			nKeyCount = nKeyCount + 1;

			if (type(sKey) == "string") then
				local sFinalValType = type(vValue);
				local vFinalValue 	= vValue;

				if (sFinalValType == "nil") then--can this ever happen?
					sFinalValType 	= "null";
					vFinalValue 	= null;
				end

				tStruct[sKey] = {
					type 			= sFinalValType,
					defaultvalue 	= vFinalValue,
				};
			end

		end

		--incriment the total number of structs
		tMetaData.structscount = tMetaData.structscount + 1;
		--add this struct's metadata to the list
		tMetaData[sSubType] = {--TODO should i use the V table for the index  here?
			keycount = nKeyCount,
		};
	end

	return setmetatable({},
	{
		__add 		= errmath,--TODO perhaps add the ability to combine them...maybe thruogh concat though, not add
		__band 		= errbit,
		__bor 		= errbit,
		__bnot 		= errbit,
		__bxor 		= errbit,
		--[[
		--this is the call to the factory (the one created by calling the struct() function)
		which creates the struct instance object
		]]
		__call 		= function(this, tInputArgs)
			local tArgs		= type(tInputArgs) == "table" and tInputArgs or nil;
			local tFactory 	= {};

			--seutp the default values first
			for sKey, tVals in pairs(tStruct) do
				tFactory[sKey] = {
					type 	= tVals.type,
					value 	= tVals.defaultvalue,
				};
			end

			--next, try to process any valid input
			if (tArgs) then

				for sKey, vValue in pairs(tArgs) do

					--make certain the key exists in the table
					if (rawtype(tFactory[sKey]) ~= "nil") then
						local vFinalValue 	= vValue;
						local sValType 		= type(vValue);
						local bValueIsNull	= sValType == "null";
						local bValueIsNil	= sValType == "nil";

						--handle cases of default value types being null
						if (tFactory[sKey].type == "null" and not bValueIsNull and not bValueIsNil) then
							tFactory[sKey].type 	= sValType;
						end

						--account for nil values
						if (bValueIsNil) then
							vFinalValue = null;
						end

						--be sure the value type is correct
						if (sValType == tFactory[sKey].type or bValueIsNull) then
							tFactory[sKey] = {
								type 	= sValType,
								value 	= vFinalValue,
							};
						end

					end

				end

			end

			return setmetatable({}, {
				--struct instance object created by a call to the factory
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
				__name		= sSubType,
				__newindex 	= function(t, k, v)

					--make certain the key exists in the table
					if (rawtype(tFactory[k]) ~= "nil") then
						local vFinalValue	= v;
						local sValType 		= type(v);
						local bValueIsNull	= sValType == "null";
						local bValueIsNil	= (not bValueIsNull) and sValType == "nil";

						--handle cases of default value types being null
						if (tFactory[k].type == "null" and not bValueIsNull and not bValueIsNil) then
							print(vFinalValue)
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
		--struct constructor metatable
		__close 	= false,
		__concat	= errmath,
		--__count 	= structscount,
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
		__name		= sSubType.."_factory",
		__newindex 	= dummy,
		__pairs		= erriterate,
		__pow		= errmath,
		__shl  		= errbit,
		__shr  		= errbit,
		__sub		= errbit,
		--__subtype	= sSubType.."_factory",
		__tostring	= function()--TODO finish
			local sRet = "";

			for sKey, tVals in pairs(tStruct) do

				sRet = sRet..""
			end

			return sRet;
		end,
		__type		= sSubType.."_factory",
		__unm		= errmath,
	});
end

local function structscount()
	return tMetaData.structsCountl
end

return setmetatable({
	__count = structscount,
	--istype(sType)--TODO finishb n
},
{
	__call 		= createfactory,
	__index 	= function() end,
	__newindex 	= function() end,
	__type 		= "struct_factory",

});
