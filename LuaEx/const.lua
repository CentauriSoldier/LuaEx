local tConst = {
	AllowedValueTypes = {'boolean', 'number', 'string'},
	ThrowErrorsByDefault = true, --this can be changed individually for each CONST type created using :SetThrowErrors(boolean);
	Types = {},
	--IsSubConst = false, --used for creating sub constants (scope demands it remains here)
}

--determines whether or not this CONST type will throw errors
local function GetThrowErrors(sName)
	local bRet = false;

	if (tConst.Types[sName]) then
		bRet = tConst.Types[sName].ThrowErrors;
	end

	return bRet;
end

--determines whether or not the sumbitted type is an allowed CONST value type
local function IsAllowedValueType(sValueType)
	local bRet = false;

	for _, sAllowedValueType in pairs(tConst.AllowedValueTypes) do

		if (sValueType == sAllowedValueType) then
			bRet = true;
			break;
		end

	end

	return bRet;
end



--TODO create destroy function
function tConst.create(sName, sDescription, bIsConstType)
--	local  			= select(1, ...);
--	local 		= select(2, ...);

	--make sure the name input is good
	assert(type(sName) == "string" and sName:gsub("%s", "") ~= "",
		   "Error creating CONST type. Input must be a non-blank string.");
	local tReturnTable = {};

	--ensure the CONST type doesn't already exist
	if (not tConst.Types[sName]) then

		if (type(sDescription) ~= "string") then
			sDescription = "";
		end

		--create the CONST shadow table
		local tShadow = {
			Descriptions = {},
		};

		--store the CONST type name
		tConst.Types[sName] = {
			ThrowErrors = tConst.ThrowErrorsByDefault,  --set the default error flag for this CONST type
			ConstNames = {},
			Description = sDescription,
		};

		--============================================
		-- Begin Metamethods
		--===========================================

		--==========
		-- NewIndex
		--==========
		--this is called whenever a new index is created within the new CONST type table
		local function NewIndex(tTable, vKey, vValue)
			local sType = type(vValue);

			--make sure the CONST has not already been defined
			if (tShadow[vKey]) then

				if (GetThrowErrors(sName)) then
					error('Error creating CONST type. "'..sName..'.'..vKey..
						  '" has already been defined with value "'..
						  tostring(tShadow[vKey])..'" and is of type "'..
						  type(tShadow[vKey])..'".');
				end

			else

				--make sure the CONST is of the correct type
				local sConstType = sName..'.'..vKey;
				local bIsConstType = sType == sConstType or bIsConstType;

				if (IsAllowedValueType(sType) or bIsConstType) then
					tShadow[vKey] = vValue;
					--tShadow.Descriptions[sName] = sDescription;
					--tConst.Types[sName].Description = sDescription;
					--add this CONST name to the list of names for this CONST type
					tConst.Types[sName].ConstNames[#tConst.Types[sName].ConstNames + 1] = vKey;

					if (bIsConstType) then
						--add the CONST as an allowed type
						tConst.AllowedValueTypes[#tConst.AllowedValueTypes + 1] = sConstType;
					end

				else
					--throw an error (if errors are on)
					if (GetThrowErrors(sName)) then
						error('Error creating CONST type. A CONST type "'..sName..
							  '" value may be of type "boolean", "number" or "string" only. Input was of type "'..
							  sType..'".');
					end

				end

			end

		end


		--=========
		-- GetAll
		--=========
		--__call
		local function GetAll()
			local tRet = {};

			for k, v in pairs(tShadow) do
				local sVType = type(v);

				--TODO I have commented out this part to allow for nested CONST tables. Find out if this has any negative affects.
				if (type(k) == "string" and IsAllowedValueType(sVType)) then
					tRet[k] = v;
				end

			end

			return tRet;
		end


		--============================================
		-- End Metamethods
		--
		-- Begin CONST type exposed functions
		--============================================
		--this is the table whose metatable is set and is used to set functions
		local tConstType = {};


		--================
		-- GetDescription
		--================
		function tConstType:getDescription()
			assert(tShadow.Descriptions[type(self)], "Error getting CONST description. CONST does not exist.");
			return tShadow.Descriptions[type(self)];
		end


		--================
		-- SetThrowErrors
		--================
		function tConstType.setThrowErrors(bValue)
			local sType = type(bValue);
			local bFlag = bValue;

			if (sType ~= "boolean") then
				bFlag = false;
			end

			tConst.Types[sName].ThrowErrors = bFlag;
		end

		--================
		-- IsConstOfType
		--[[================
		Note: this method will return true if the
			  input value matches *any* value in the table.
		]]
		function tConstType.isMyConst(vValue)
			local bRet = false;
			local sType = type(vValue);

			if (sType ~= "nil") then

				for sCONST, vConstValue in pairs(tConstType()) do

					if vValue == vConstValue then
						bRet = true;
						break;
					end

				end

			end

			return bRet
		end


		--================
		-- SetDescription
		--================
		function tConstType:SetDescription(sDescription)
			assert(tShadow.Descriptions[self], "Error setting CONST description. CONST does not exist.");
			assert(type(sDescription) == "string", "Error setting CONST description. Description must be a string.");
			tShadow.Descriptions[self] = sDescription;
		end


		--adjust the metatable of the new tConstType and return that value
		tReturnTable = setmetatable(tConstType, {
			__call = GetAll,
			__len = function() return #tConst.Types[sName].ConstNames end,--does not work with Lua Version <= 5.1
			__index = tShadow, --the shadow reference
			__newindex = NewIndex,
			__type = sName,
			__tostring = function() return tConst.Types[sName].Description end,
		});

	else

		tReturnTable = _G[sName];

		if (GetThrowErrors(sName)) then
			error('Error creating CONST type. CONST type "'..sName..'" already exists.');
		end

	end

	return tReturnTable;
end

local const = tConst.create;
return const;
--TOTO check for const keyword and, if present, exlcude this module.
