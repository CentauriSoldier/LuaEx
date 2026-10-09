--[[*
@moduleid targetor
@authors Centauri Soldier
@copyright Copyright © 2020 Centauri Soldier
@description <h2>Targetor</h2><h3>Targetor objects for target matching and determination.</p>
<h3>Implentation must create the following enums:</h3>
<ul>
	<li>TARGET <em>(enum type)</em></li>
</ul>
<p>Any number of target types may be created for this constant type. The types may then be assigned to targetor objects and be used to check targetability</p>
<p>IMMUNITY and PREREQ are similar but differ in that ANY immunity makes this object untargetable by an object with the given TARGETOR type. Regarding PREREQs,
a potential targetor of this object must have at least one of the object's TARGTOR type as a TARGETABLE and must also have all PREREQs as TARGETABLEs in order to target this object.</p>
@features
@usage <p>Once a <strong>Targetor</strong> object has been created, it can be operated upon using TARGET types
<em>(or numerically indexed tables containing multiple TARGET types)</em> or other <strong>Targetor</strong> objects.</p>
@todo <p>create <strong>__tostring</strong> metamethod.
@version 0.1
*]]
local tTargetors 	= {};
local tCategoryIdicesByName; 	--used for quick checking existence of a type enum in __add, __sub (each entry will return the order value given the name)
local tCategoryTypesByName;		-- used for getting a type based on its name

local type					= type;
local rawtype				= rawtype;
local tableremove			= table.remove;
local pairs 				= pairs;
local tostring				= tostring;
local isvariablecompliant 	= string.isvariablecompliant;


local function typeTableIsValid(tInput)
	local bRet = false;

	if (rawtype(tInput) == "table") then
		local bError = false;

		for _, sInputType in pairs(tInput) do

			if (type(sInputType) ~= "targetor.TARGET") then
				bError = true;
				break;
			end

		end

		bRet = not bError;
	end

	return bRet;
end

local function importTypes(eTypes)
	local tRet = {
		byIndex 	= {},--values are enums
		byName		= {},--values are enums
		indexByName = {},--values are indices
		nameByIndex = {},--values are names
	};

	for nIndex, eType in pairs(eTypes) do
		--storing all this data makes for fast processing by the functions which use it
		tRet.byIndex[nIndex] 			= eType;
		tRet.byName[eType.name] 		= eType;
		tRet.indexByName[eType.name]	= nIndex;
		tRet.nameByIndex[nIndex]		= eType.name;
	end

	return tRet;
end





local function instanceInputIsValid(tInput)
	local sError 		= "Success";
	local sInputType 	= rawtype(tInput);

	--check the table type
	local bCont = sInputType == "table";
	sError 		= bCont and sError or "Input is of type "..sInputType.."; expected type table.";

	--check the table length
	if (bCont) then
		bCont = #tInput > 0;
		sError 	= bCont and sError or "Input table is empty or is not numerically indexed.";
	end

	--check the indices and values
	if (bCont) then
		local tUnique = {};

		for nIndex, oTarget in pairs(tInput) do

			if (bCont) then
				local sTargetType 	= type(targetor.TARGET);
				bCont				= rawtype(oTarget.isA) == "function" and oTarget:isA(targetor.TARGET);
				sError				= bCont and sError or "Item at index "..nIndex.." is of type "..sTargetType..". Expected type TARGET.";

				--uniqueness
				if (bCont) then
					bCont 	= tUnique[oTarget] == nil;
					sError 	= bCont and sError or "Duplicate target type '"..oTarget.."' at index "..nIndex..".";
					tUnique[oTarget] = true;
				end

			end

		end

	end

	return bCont, sError;
end

local function hasPrereqsFor(oThis, oOther)
	local bRet = true;

	for sPrereq, ePrereq in pairs(oOther[targetor.PREREQ].byName) do

		if (oThis[targetor.TARGETABLE].byName[sPrereq] == nil) then
			bRet = false;
			break;
		end

	end

	return bRet;
end

local function hasTargetableFor(oThis, oOther)
	local bRet = false;

	for sType, eType in pairs(oThis[targetor.TARGETABLE].byName) do

		if (oOther[targetor.TARGETOR].byName[sType] ~= nil) then
			bRet = true;
			break;
		end

	end

	return bRet;
end


local function isImmuneTo(oThis, oOther)
	local bRet = false;

	for sImmunity, eImmunity in pairs(oThis[targetor.IMMUNITY].byName) do

		if (oOther[targetor.TARGETOR].byName[sImmunity] ~= nil) then
			bRet = true;
			break;
		end

	end

	return bRet;
end

local function isInterdictedBy(oThis, oOther)
	local bRet = false;

	for sInterdictor, eInterdictor in pairs(oThis[targetor.INTERDICTOR].byName) do

		if (oOther[targetor.TARGETOR].byName[sInterdictor] ~= nil) then
			bRet = true;
			break;
		end

	end

	return bRet;
end



local targetor = class "targetor" {

	__construct = function(this, tProt, ...)--tTheTargetors, tTargetables, tImmunities, tInterdictors, tPrereqs, tProrities, tThreats
		local tArgs = args or {...};
		tTargetors[this] = {};

		for eType, nIndex in pairs(tCategoryIdicesByName) do

			if (nIndex > 0) then --skips the TARGET type since it's not part of the object's types
				local tInput 	= tArgs[nIndex] or nil;

				if (tInput) then
					local bSuccess, sError 		= instanceInputIsValid(tInput);
					assert(bSuccess, "Error creating targetor. "..tostring(eType).." table is not valid.\n"..sError);
				end

				tTargetors[this][tCategoryTypesByName[eType]] = typeTableIsValid(tInput) and
			 													importTypes(tInput)		or
																{byIndex = {}, byName = {}, indexByName = {}, nameByIndex = {}};
			end

		end

	end,
	destroy = function(this)
		tTargetors[this] = nil;
	end,
	get = function(this, eType)

		if (tTargetors[this][eType] ~= nil) then
			local tRet = {};

			for nIndex, eExistingType in pairs(tTargetors[this][eType].byIndex) do
				tRet[nIndex] = eExistingType;
			end

			return tRet;
		end

	end,
	getAll = function()

	end,
	has = function(this, eType)
		return (tTargetors[this][eType.enum].byName[eType.name] ~= nil);
	end,
	hasPrereqsFor = function(this, other)
		return hasPrereqsFor(tTargetors[this], tTargetors[other]);
	end,
	hasTargetableFor = function(this, other)
		return hasTargetableFor(tTargetors[this], tTargetors[other]);
	end,
	isImmuneTo = function(this, other)
		return isImmuneTo(tTargetors[this], tTargetors[other]);
	end,
	isInterdictedBy = function(this, other)
		return isInterdictedBy(tTargetors[this], tTargetors[other]);
	end,
	addAll = function(this, eType)
	end,
	removeAll = function(this, eType)
	end,
	sortByPriority = function(this, ...)
		local tArgs = arg or {...};
		local tRet = {};

		for _, oTargetor in pairs(tArgs) do


		end

		return tRet;
	end,
	sortByThreat = function(this, ...)
		local tArgs = arg or {...};

	end,
	--[[#
	@module targetor
	@func __add
	@scope local
	@desc <p>Adds the given TARGET type to the given target category of the object.</p>
	@ret targetor oTargetor Returns the targetor object.
	!]]
	__add = function(vLeft, vRight)
		local oRet		 	= nil;
		local sLeftType 	= type(vLeft);
		local sRightType 	= type(vRight);

		if (sLeftType == "targetor") then
			oRet = vLeft;

			if (tCategoryIdicesByName[sRightType]) then
				local tType 		= tTargetors[vLeft][vRight.enum];

				if (tType.byName[vRight.name] == nil) then
					local nNextIndex 	= #tType.byIndex + 1;

					tType.byIndex[nNextIndex] 		= vRight;
					tType.byName[vRight.name]		= vRight;
					tType.indexByName[vRight.name] 	= nNextIndex;
					tType.nameByIndex[nNextIndex]	= vRight.name;
				end

			end

		elseif (sRightType == "targetor") then
			oRet = vRight;

			if (tCategoryIdicesByName[sLeftType]) then
				local tType 		= tTargetors[vRight][vLeft.enum];

				if (tType.byName[vLeft.name] == nil) then
					local nNextIndex 	= #tType.byIndex + 1;

					tType.byIndex[nNextIndex] 		= vLeft;
					tType.byName[vLeft.name]		= vLeft;
					tType.indexByName[vLeft.name] 	= nNextIndex;
					tType.nameByIndex[nNextIndex]	= vLeft.name;
				end

			end

		end

		return oRet;
	end,
	--[[$
	@module targetor
	@func __sub
	@scope local
	@desc <p>Removes the given TARGET type in the given target category from the object.</p>
	@ret targetor oTargetor Returns the targetor object.
	!]]
	__sub = function(vLeft, vRight)
		local oRet		 	= nil;
		local sLeftType 	= type(vLeft);
		local sRightType 	= type(vRight);

		if (sLeftType == "targetor") then
			oRet = vLeft;

			if (tCategoryIdicesByName[sRightType]) then
				local tType 	= tTargetors[vLeft][vRight.enum];

				if (tType.byName[vRight.name] ~= nil) then
					local nIndex 	= tType.indexByName[vRight.name];

					tableremove(tType.byIndex, nIndex);
					tType.byName[vRight.name]		= nil;
					tType.indexByName[vRight.name] 	= nil;
					tableremove(tType.nameByIndex, nIndex);
				end

			end

		elseif (sRightType == "targetor") then
			oRet = vRight;

			if (tCategoryIdicesByName[sLeftType]) then
				local tType 	= tTargetors[vRight][vLeft.enum];

				if (tType.byName[vLeft.name] ~= nil) then
					local nIndex 	= tType.indexByName[vLeft.name];

					tableremove(tType.byIndex, nIndex);
					tType.byName[vLeft.name]		= nil;
					tType.indexByName[vLeft.name] 	= nil;
					tableremove(tType.nameByIndex, nIndex);
				end

			end

		end

		return oRet;
	end,
	--[[#
	@module targetor
	@func __lt
	@desc <p>Determines whether the right object can target the left (or, if using the greater-than symbol, whether the left can target the right).
			This function accounts for all assocaiations inlcuding targetable types, prerequisites, immunitites and interdictors.</p>
	@ret boolean bCanTarget Returns true if it can target and false otherwise.
	!]]
	__lt = function(vLeft, vRight)
		local sLeftType 	= type(vLeft);
		local sRightType	= type(vRight);
		assert(sLeftType 	== "targetor", "Left side of operator is of type "..sLeftType..". Expected type targetor.");
		assert(sRightType 	== "targetor", "Right side of operator is of type "..sRightType..". Expected type targetor.");
		local oDefender		= tTargetors[vLeft];
		local oAttacker		= tTargetors[vRight];
		--oLeft < oRight
		--oRight > oLeft
		return 	hasTargetableFor(oAttacker, oDefender) 	and hasPrereqsFor(oAttacker, oDefender) and
		 		(not isImmuneTo(oDefender, oAttacker)) 	and (not isInterdictedBy(oAttacker, oDefender));
	end,
};



local function initInputIsValid(tInput)
	local sError 	= "Success";
	local sType 	= type(tInput);

	--check the table type
	local bCont = sType == "table";
	sError 		= bCont and sError or "Input is of type "..sType.."; expected type table.";

	--check the table length
	if (bCont) then
		bCont = #tInput > 0;
		sError 	= bCont and sError or "Input table is empty or is not numerically indexed.";
	end


	--check the indices and values
	if (bCont) then
		local tUnique = {};

		for nIndex, sTarget in pairs(tInput) do

			if (bCont) then
				--index type
				sType	= type(nIndex);
				bCont	= sType == "number";
				sError	= bCont and sError or "Index is of type "..sType.."; expected type number.";

				--target type
				if (bCont) then
					sType	= type(sTarget);
					bCont	= sType == "string";
					sError	= bCont and sError or "Index is of type "..sType.."; expected type string.";
				end

				--variable compliant
				if (bCont) then
					bCont				= isvariablecompliant(sTarget);
					sError				= bCont and sError or "Value of '"..tostring(sTarget).."' is not a proper variable name.\r\nAll target type names must be variable-compliant strings.";
				end

				--uniqueness
				if (bCont) then
					bCont 	= tUnique[sTarget] == nil;
					sError 	= bCont and sError or "Duplicate target type '"..sTarget.."' at index "..nIndex..".\r\nEach target type must be unique.";
					tUnique[sTarget] = true;
				end

			end

		end

	end

	return bCont, sError;
end

--[[#@
@module targetor
@func init
@scope global
@desc <p>Initializes the targetor class using the given target type strings.</p>
@param table tTargets A numically-indexed table whose values are variable-name-compliant strings (e.g., DOG, HUMAN | ).
@ret Nil nil Returns nothing.
!]]
function targetor.init(tTargets)
	local bSuccess, sError = initInputIsValid(tTargets);
	assert(bSuccess, "Error initializing targetor system.\r\nInput must be a numerically-indexed table whose values are variable-compliant strings.\r\n"..sError);

	--localize the unpack function
	local unp = unpack or table.unpack;

	--create the class enums
	targetor.TARGET 		= enum("targetor.TARGET", 		{unp(tTargets)}, nil, true);
	targetor.TARGETABLE 	= enum("targetor.TARGETABLE", 	{unp(tTargets)}, nil, true);
	targetor.TARGETOR 		= enum("targetor.TARGETOR", 	{unp(tTargets)}, nil, true);
	targetor.IMMUNITY 		= enum("targetor.IMMUNITY", 	{unp(tTargets)}, nil, true);
	targetor.INTERDICTOR	= enum("targetor.INTERDICTOR", 	{unp(tTargets)}, nil, true);
	targetor.PREREQ 		= enum("targetor.PREREQ", 		{unp(tTargets)}, nil, true);
	targetor.PRIORITY 		= enum("targetor.PRIORITY", 	{unp(tTargets)}, nil, true);
	targetor.THREAT 		= enum("targetor.THREAT", 		{unp(tTargets)}, nil, true);

	local sTarget 		= type(targetor.TARGET[1]);
	local sTargetor		= type(targetor.TARGETOR[1]);
	local sTargetable 	= type(targetor.TARGETABLE[1]);
	local sImmunity 	= type(targetor.IMMUNITY[1]);
	local sInterdictor 	= type(targetor.INTERDICTOR[1]);
	local sPrereq 		= type(targetor.PREREQ[1]);
	local sPriority 	= type(targetor.PRIORITY[1]);
	local sThreat 		= type(targetor.THREAT[1]);

	tCategoryIdicesByName = {
		[sTarget] 		= 0;
		[sTargetor] 	= 1;
		[sTargetable] 	= 2;
		[sImmunity] 	= 3;
		[sInterdictor] 	= 4;
		[sPrereq] 		= 5;
		[sPriority] 	= 6;
		[sThreat] 		= 7;
	};

	tCategoryTypesByName = {
		[sTarget] 		= targetor.TARGET;
		[sTargetor] 	= targetor.TARGETOR;
		[sTargetable] 	= targetor.TARGETABLE;
		[sImmunity] 	= targetor.IMMUNITY;
		[sInterdictor] 	= targetor.INTERDICTOR;
		[sPrereq] 		= targetor.PREREQ;
		[sPriority] 	= targetor.PRIORITY;
		[sThreat] 		= targetor.THREAT;
	};

	--setup the help system
	local tHelp = {
		["TARGET"]		= {desc = "Generic target types used in creation of a targetor object."},
		["TARGETOR"]	= {desc = "What kind of target types I am (my types)."},
		["TARGETABLE"]	= {desc = "Types I can target (if the target is not immune and I have no interdictor for it) (inclusive list). In order for me to target something, it is nessecary that my potential target have at least one of these as a TARGETOR type."},
		["IMMUNITY"]	= {desc = "Target types that cannot target me regardless of any other factors (highest precendence)."},
		["INTERDICTOR"]	= {desc = "Target types that I cannot target regardless of any other factors (highest precendence)."},
		["PREREQ"]		= {desc = "The must-have type(s) required in order to target me (exclusive list); does not guarantee aquisition by a potential targetor; that is, it's nessecary, for the object attempting to target me, to have every PREREQ but not sufficient; they must also possess at least one proper targetable type that matches one of my TARGETOR types."},
		["PRIORITY"]	= {desc = "What I try to target first. Items in this list are considered most important to least important, from first to last respectively (ascending in index value)."},
		["THREAT"]		= {desc = "What I try to avoid first. Items in this list are considered most important to least important, from first to last respectively (ascending in index value)."},
		["init"]		= {desc	= "Sets up the targetor system. This must be setup before instantiating any targetor objects."},
	};

	--create the help system
	--print(type(comhelp(targetor, {}, tHelp)))
	targetor.help = infusedhelp(targetor, {}, tHelp);
end

return targetor;
