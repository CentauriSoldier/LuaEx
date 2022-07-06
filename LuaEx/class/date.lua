local tDates = {};

constant("YYYYMMDD", "YYYYMMDD");
constant("YYYYDDMM", "YYYYDDMM");
constant("MMYYYYDD", "MMYYYYDD");
constant("MMDDYYYY", "MMDDYYYY");
constant("DDYYYYMM", "DDYYYYMM");
constant("DDMMYYYY", "DDMMYYYY");

local YYYYMMDD = YYYYMMDD;
local YYYYDDMM = YYYYDDMM;
local MMYYYYDD = MMYYYYDD;
local MMDDYYYY = MMDDYYYY;
local DDYYYYMM = DDYYYYMM;
local DDMMYYYY = DDMMYYYY;

local tDate = {
	DefaultOrder 	= MMDDYYYY,
	DayValue		= {
		["Monday"] 		= 1,
		["Tuesday"] 	= 2,
		["Wednesday"] 	= 3,
		["Thursday"] 	= 4,
		["Friday"] 		= 5,
		["Saturday"] 	= 6,
		["Sunday"] 		= 7,
	},
	DayName			= {
		[1]	= "Monday",
		[2]	= "Tuesday",
		[3]	= "Wednesday",
		[4]	= "Thursday",
		[5]	= "Friday",
		[6]	= "Saturday",
		[7]	= "Sunday",
	},
	DayMin 			= 1,
	DayMax 			= 31,
	DayMaxAJSN		= 30, --for apr, jun, sep and oct
	DayMaxFeb		= 28,
	DayMaxFebLeap	= 29,
	LeapYearFactor	= 4,
	MonthMin 		= 1,
	MonthMax		= 12,
	MonthName		= {
		[1] 	= "January",
		[2] 	= "February",
		[3] 	= "March",
		[4] 	= "April",
		[5] 	= "May",
		[6] 	= "June",
		[7] 	= "July",
		[8] 	= "August",
		[9] 	= "September",
		[10] 	= "October",
		[11] 	= "November",
		[12] 	= "December",
	},
	MonthValue	= {
		["January"] 	= 1,
		["February"] 	= 2,
		["March"] 		= 3,
		["April"] 		= 4,
		["May"] 		= 5,
		["June"] 		= 6,
		["July"] 		= 7,
		["August"] 		= 8,
		["September"] 	= 9,
		["October"] 	= 10,
		["November"] 	= 11,
		["December"] 	= 12,
	},
	Order 		= {--indices 1, 2 = day, 3, 4 month, 5, 6 four-digit year, 7, 8 two-digit year
		YYYYMMDD = {7, 8, 5, 6, 1, 4, 3, 4},
		YYYYDDMM = {5, 6, 7, 8, 1, 4, 3, 4},
		MMYYYYDD = {7, 8, 1, 2, 3, 6, 5, 6},
		MMDDYYYY = {3, 4, 1, 2, 5, 8, 7, 8},
		DDYYYYMM = {1, 2, 7, 8, 3, 6, 5, 6},
		DDMMYYYY = {1, 2, 3, 4, 5, 8, 7, 8},
	},
	YearMin	= 1,
	YearMax	= 999999999,
}
--https://www.wikihow.com/Calculate-the-Day-of-the-Week
local function purgeInput(vInput, nMin, nMax, bIsYear)--TODO fix this., it needs to account for sinle-digit months and days
	local nRet 	= nMin;
	local sType = type(vInput);
	local nExpectedLength = bIsYear and 4 or 2;

	if (sType == "string") then
		local nLength = #vInput;

		if (nLength > 0 and nLength <= nExpectedLength) then
			nRet = tonumber(vInput);
			nRet = nRet >= nMin or nMin;
			nRet = nRet <= nMax or nMax;
		end

	elseif (sType == "number") then
		nRet = nRet >= nMin or nMin;
		nRet = nRet <= nMax or nMax;

	end

	return nRet;
end

local animal = class "animal" {

	__construct = function(this, protected, sName, bIsBiped)
		--setup the protected table for this instance (or import the given one if it's not nil)
		tProtectedRepo[this] = rawtype(protected) == "table" and protected or {};

		--for readability
		local tProt = tProtectedRepo[this];

		--create the protected properties
		tProt.name 		= type(sName) 		== "string" and sName 		or "";
		tProt.isBiped 	= type(bIsBiped)	== "string" and bIsBiped 	or false;

	end,


};


local date = class "date" {

	__construct = function(this, null, vDay, vMonth, vYear, sOrder)
		tDates[this] = {
			day		= purgeInput(sDay, 		tDate.DayMin, 	tDate.DayMax),
			month 	= purgeInput(vMonth, 	tDate.MonthMin, tDate.MonthMax),
			year	= purgeInput(vYear, 	tDate.YearMin, 	tDate.YearMax, true),
			order 	= tDate.Order[sOrder] ~= nil and sOrder or tDate.DefaultOrder,
		};

		local oDate = tDates[this];

		oDate.isLeapYear = oDate.year % tDate.LeapYearFactor == 0;
	end,

	getdayofweek = function(this)

	end,

	getdayname = function(this)

	end,

	getweekname = function(this)

	end,

	getweekofmonth = function(this)

	end,

	isleapyear = function(this)
		return tDates[this].isLeapYear;
	end,

	--TODO allow for calcs with numbers too
	__add = function(this, oOther)

	end,

	__mul = function(this, oOther)

	end,

	__sub = function(this, oOther)

	end,

	__lt = function(this, oOther)

	end,

	__eq = function(this, oOther)

	end,
	--add functions for inc/decrementing

	set = function(this, vDay, vMonth, vYear, sOrder)
		vDay = type(vDay) == "string" and tonumber(vDay) or vDay;

		--if (type(vDay) == "number") then

	end,

	setday = function(this, nDay)
	end,

	setmonth = function(this, nMonth)
	end,

	setyear = function(this, nYear)
	end,
};

function date.validate(sDate, sOrder)
	--todo check for date object input as well

	local bRet 					= false;
	local tOrder 				= tDate.Order[sOrder] ~= nil and tDate.Order[sOrder] or tDate.Order[tDate.DefaultOrder];
	local nExpectedDateLength 	= 8;
	local nLeapYearFactor 		= 4;
	local sType 				= type(sDate);
	local bIsNumber				= sType == "number";
	local bCont					= sType == "string" or bIsNumber;
	local tMonthsOf30			= {4, 6, 9, 11};
	local nDay 					= 0;
	local nMonth 				= 0;
	local nYear					= 0;
	local bIsLeapYear 			= 0;

	if (bIsNumber) then
		sDate = string.format("%08d", sDate);
	end

	if (bCont) then
		--remove non-numeric characters
		sDate = sDate:gsub("[^%d]", "");
		bCont = #sDate == nExpectedDateLength;
	end

	if (bCont) then
		nDay 		= tonumber(sDate:sub(tOrder[1], tOrder[2]));
		nMonth 		= tonumber(sDate:sub(tOrder[3], tOrder[4]));
		nYear		= tonumber(sDate:sub(tOrder[5], tOrder[6]));
		bIsLeapYear = tonumber(sDate:sub(tOrder[7],	tOrder[8])) % nLeapYearFactor == 0;

		bCont = (nDay > 0 and nDay < 32) and (nMonth > 0 and nMonth < 13) and (nYear ~= 0);
	end

	if (bCont) then

		if (nMonth == 2) then
			bRet = (nDay <= 28) or (nDay <= 29 and bIsLeapYear);
		else

			for x = 1, #tMonthsOf30 do
				bRet = true;

				if (nMonth == tMonthsOf30[x] and nDay > 30) then
					bRet = false;
					break;
				end

			end

		end

	end

	return bRet;
end

return date;
