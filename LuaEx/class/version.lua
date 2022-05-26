local tVersions = {};

p = function(s)
	Dialog.Message(type(s), tostring(s));
end

local function updatestring(this)
	local oVersion = tVersions[this];
	local sVersion = "";

	for nIndex, nValue in pairs(oVersion.current) do
		local sValue 	= tostring(nValue);

		if (oVersion.expanded) then
			sValue = sValue..string.rep("0", oVersion.layout[nIndex] - #sValue);
		end

		sVersion = sVersion..oVersion.delimiter..sValue;
	end

	oVersion.string = sVersion;
end


local function currentTableIsValid(tFormat)
	local bRet = false;

	if (type(tCurrent) == "table") then
		tFormat

	end

	return bRet;
end

local function formatTableIsValid(tFormat)
	local bRet = false;

	if (type(tFormat) == "table") then
		bRet 			= true;
		local nCount 	= 0;

		for nIndex, nValue in pairs(tFormat) do
			nCount = nCount + 1;

			--make sure the index is numeric
			if (type(nIndex) ~= "number" or type(nValue) ~= "number") then
				bRet = false;
				break;
			end

			--make sure the index is sequential
			if (nIndex ~= nCount) then
				bRet = false;
				break;
			end

			--use only integers
			tFormat[nIndex] = math.ceil(nValue);
		end

	end

	return bRet;
end

return class "version" {
	__construct = function(this, tProt, tCurrent, tFormat)
		local bCurrentIsValid 	= currentTableIsValid(tCurrent);
		local bFormatIsValid 	= formatTableIsValid(tFormat);

		tVersions[this] = {};
		local oVersion = tVersions[this];

		--base 		= 10, 					--the number base (default is 10)
		oVersion.current 	=  and tCurrent or {0,	0,	0,	0	}; 	--leave this as-is (gets input during init)
		oVersion.delimiter	= ".";	--the symbol used to separate the version blocks
		oVersion.expanded 	= true;					--whether there should be trailing zeroes affixed to number blocks with fewer digits than the max value (e.g., 10.010.40 vs. 10.01.4)
		oVersion.format 	=  and tFormat{99, 	99, 99, 999};	--set this to the format you want to use (total number of blocks and max value per block)
		oVersion.layout 	= {0,	0, 	0,	0 	};	--this contains the number of digits per block and is setup automatically during init using the format table
		oVersion.string 	= {};					--this is formatted and updated whenever the version is processed

		--save the number of digits in each block for string formatting later
		for nIndex, v in pairs(oVersion.format) do
			local nFormat = oVersion.format[nIndex];
			local nLength = #tostring(nFormat):gsub("%D", "");
			oVersion.layout[nIndex] = nLength;
		end

		--setup the current table using the input (if any)
		if ( type(tCurrent) == "table" and #tCurrent == oVersion.format) then
			local bCont = true;

			--make sure the values are good
			for nIndex, nValue in pairs(oVersion.format) do

				if not (tCurrent[nIndex]) then
					bCont = false;
					break;
				end

				if not (type(tCurrent[nIndex]) == "number") then
					bCont = false;
					break;
				end

				--save the current value
				tVersion.current[nIndex] = (tCurrent[nIndex] <= tVersion.format[nIndex]) and tCurrent[nIndex] or tVersion.format[nIndex];
			end

			if not (bCont) then
				error("Error initializing 'version'. Input table is not formatted properly.");
			end

		end

		--default the version string (just in case no process action is ever called)
		updatestring(this);
	end,
	display = function(this)
		return tVersions[this].string;
	end,
	process = function(this)

		updatestring();
	end,
	setexpandeddisplay = function(this, bExpanded)
		local bCurrentlyExpanded = tVersions[this].expanded;
		bExpanded = type(bExpanded) == "boolean" and bExpanded or false;

		if not (bCurrentlyExpanded == bExpanded) then
			updatestring(this);
		end

	end,
};
