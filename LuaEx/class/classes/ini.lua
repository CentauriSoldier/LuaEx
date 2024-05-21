-------------------------------------------------------------------------------
---
---
---
----------------------------------------------------------------------------------
local tINIs = {};

local assert 	= assert;
local table 	= table;
local type 		= type;
local isnil		= isnil;

--TODO should this auto-detect type and serialize properly?
--TODO trim leading/trailing space on section, value names.
--[[
	INI Module
	Original by Dynodzzo, Sledmine
	Modified by Centauri Soldier

	Copyright (c) 2012 Carreras Nicolas

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER G
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

--- Returns a ini encoded string given data
---@param data table Table containing all data from the ini file
---@return string String encoded as an ini file
local function encode(data)
    local content = ""
    for section, param in pairs(data) do
        content = content .. ("[%s]\n"):format(section)
        for key, value in pairs(param) do
            content = content .. ("%s=%s\n"):format(key, tostring(value))
        end
        content = content .. "\n"
    end

    return content
end

--- Returns a table containing all the data from an ini string
---@param fileString string Ini encoded string
---@return table Table containing all data from the ini string
local function decode(fileString)--todo does this set the proper type?
    local position, lines = 0, {}
    for st, sp in function()
        return string.find(fileString, "\n", position, true)
    end do
        table.insert(lines, string.sub(fileString, position, st - 1))
        position = sp + 1
    end
    table.insert(lines, string.sub(fileString, position))
    local data = {}
    local section
    for lineNumber, line in pairs(lines) do
        local tempSection = line:match("^%[([^%[%]]+)%]$")
        if (tempSection) then
            section = tonumber(tempSection) and tonumber(tempSection) or tempSection
            data[section] = data[section] or {}
        end
        local param, value = line:match("^([%w|_]+)%s-=%s-(.+)$")
        if (param and value ~= nil) then
            if (tonumber(value)) then
                value = tonumber(value)
            elseif (value == "true") then
                value = true
            elseif (value == "false") then
                value = false
            end
            if (tonumber(param)) then
                param = tonumber(param)
            end
            data[section][param] = value
        end
    end
    return data
end

--- Returns a table containing all the data from an ini file
---@param fileName string Path to the file to load
---@return table Table containing all data from the ini file
local function load(pFile)
	assert(type(pFile) == "string", "Argument 1 must be of type string.\nGot type ${type}." % {type=type(pFile)});
	local file = assert(io.open(pFile, "r"), "Error loading file : " .. pFile);
	local data = decode(file:read("a"));
	file:close();
	return data;
end

--- Saves all the data from a table to an ini file
---@param fileName string The name of the ini file to fill
---@param data table The table containing all the data to store
local function save(pFile, tTable)
	assert(type(pFile) == "string", "Argument 1 must be of type string.\nGot type ${type}." % {type=type(pFile)});
	assert(type(tTable) == "table", "Argument 2 must be of type table.\nGot type ${type}." % {type=type(tTable)})
	local file = assert(io.open(pFile, "w+b"), "Error loading file :" .. pFile);
	file:write(encode(tTable));
	file:close();
end

local ini = class "ini" {
	__construct = function(this, tProt, sFilepath, bAutoLoad, bAutoSave)
		tINIs[this] = {
			autoload	= type(bAutoLoad == "boolean" and bAutoLoad) and bAutoLoad or false,
			autosave	= type(bAutoSave == "boolean" and bAutoSave) and bAutoSave or false,
			ini 		= {},
			filepath 	= type(sFilepath) == "string" and sFilepath or "",
			issaved		= false, --indicates whether it's been saved since it last changed
		};

		local tData = tINIs[this];

		if (tData.autoload and tData.filepath:gsub("%s","") ~= "") then
			tData.ini = load(tData.filepath);
			tData.issaved = true;
		end

	end,
	__tostring = function(this)
		return encode(tINIs[this].ini);
	end,
	--[[!
	@func deleteall
	@desc A thing
	!]]
	deleteall = function(this)
		local tData = tINIs[this];
		tData.ini = {};

		tData.issaved = false;

		if (tData.autosave) then
			save(tData.filepath, tData.ini);
			tData.issaved = true;
		end
	end,
	deletesection = function(this, sSection)
		local bRet = false;
		local tData = tINIs[this];
		local tINI 		= tData.ini;

		assert(type(sSection) 	== "string", 	"Section name must be of type string.");

		if (type(tINI[sSection]) ~= "nil") then
			bRet = table.remove(tINI, sSection);
			tData.issaved = false;

			if (tData.autosave) then
				save(tData.filepath, tData.ini);
				tData.issaved = true;
			end

		end

		return bRet;
	end,
	deletevalue = function(this, sSection, sValue)
		local tData = tINIs[this];
		local tINI 		= tData.ini;

		assert(type(sSection) 	== "string", 	"Section name must be of type string.");
		assert(type(sValue) 	== "string", 	"Value name must be of type string.");

		if (type(tINI[sSection]) ~= "nil" and type(tINI[sSection][sValue]) ~= "nil") then
			table.remove(tINI[sSection], sValue);
			tData.issaved = false;

			if (tData.autosave) then
				save(tData.filepath, tData.ini);
				tData.issaved = true;
			end

		end
	end,
	getfilepath = function(this)
		return tINIs[this].filepath;
	end,
	getsectionnames = function(this)
		local tData = tINIs[this];
		local tINI 		= tData.ini;
		local tRet = {};

		for sExistingSection, _ in pairs(tINI) do
			tRet[#tRet + 1] = sExistingSection;
		end

		return tRet;
	end,
	getsectioncount = function(this)
		local tData = tINIs[this];
		local tINI 	= tData.ini;
		local nRet = 0;

		for _, __ in pairs(tINI) do
			nRet = nRet + 1;
		end

		return nRet;
	end,
	doesautosave = function(this)
		return tINIs[this].autosave;
	end,
	getall = function(this)
		return table.clone(tINIs[this].ini, true);
	end,
	getvalue = function(this, sSection, sValue)
		local vRet 	= "";
		local tData = tINIs[this];
		local tINI 	= tData.ini;

		if (type(tINI[sSection]) ~= "nil") then

			if (type(tINI[sSection][sValue]) ~= "nil") then
				vRet = tINI[sSection][sValue];
			end
		end

		return vRet;
	end,
	getvaluecount = function(this, sSection)
		local nRet 	= -1;
		local tData = tINIs[this];
		local tINI 	= tData.ini;

		if (type(tINI[sSection]) ~= "nil") then
			nRet = 0;

			for _, __ in pairs(tINI[sSection]) do
				nRet = nRet + 1;
			end
		end

		return nRet;
	end,
	getvaluenames = function(this, sSection)
		local tRet 	= nil;
		local tData = tINIs[this];
		local tINI 	= tData.ini;

		if (type(tINI[sSection]) ~= "nil") then
			tRet = {};

			for sValue, _ in pairs(tINI[sSection]) do
				tRet[#tRet + 1] = sValue;
			end
		end

		return tRet;
	end,
	importstring = function(this, sString, bOverwrite)
		local tData = tINIs[this];
		local tINI 	= tData.ini;
		assert(type(sString) 	== "string", "Argument 1 must be of type string.");

		if (bOverwrite) then
			tINI = decode(sString);--TODO validate this string!@!!!????? Does decode do this?
		else

			for sSection, tSection in pairs(decode(sString)) do
				tINI[sSection] = isnil(tINI[sSection]) and {} or tINI[sSection];

				for sValueName, vValue in pairs(tSection) do
					tINI[sSection][sValueName] = vValue;
				end

			end

		end

		tData.issaved = false;

		if (tData.autosave) then
			save(tData.filepath, tData.ini);
			tData.issaved = true;
		end
	end,
	importtable = function(this, tTable, bDoNotOverwrite)
		local tData = tINIs[this];
		local tINI 		= tData.ini;

		assert(type(tTable) 	== "string", 	"Argument 1 must be of type table.");
		--TODO assert table contents

		--TODO do stuff here!!!!

		tData.issaved = false;

		if (tData.autosave) then
			save(tData.filepath, tData.ini);
			tData.issaved = true;
		end
	end,
	issaved = function(this)
		return tINIs[this].issaved;
	end,
	load = function(this, pFile)
		local tData = tINIs[this];
		tData.ini = load(pFile)
		tData.filepath = pFile;
	end,
	save = function(this)
		local tData = tINIs[this];

		if not (tINIs.issaved) then
			save(tData.filepath, tData.ini);
			tData.issaved = true;
		end

		return tData.issaved;
	end,
	setautosave = function(this, bAutoSave)
		local tData = tINIs[this];
		tData.autosave = type(bAutoSave) == "boolean" and bAutoSave or tData.autosave;
	end,
	setfilepath = function(this, sFilepath)
		local tData = tINIs[this];
		tData.filepath = type(sFilepath) == "string" and sFilepath or tData.filepath;
	end,
	setvalue = function(this, sSection, sValue, vData)
		local tData = tINIs[this];
		local tINI 		= tData.ini;

		assert(type(sSection) 	== "string", 	"Section name must be of type string.");
		assert(type(sValue) 	== "string", 	"Value name must be of type string.");
		assert(type(vData) 		~= "nil", 		"Data cannot be nil.");

		if (type(tINI[sSection]) == "nil") then
			tINI[sSection] = {};
		end

		tINI[sSection][sValue] = vData;

		tData.issaved = false;

		if (tData.autosave) then
			save(tData.filepath, tData.ini);
			tData.issaved = true;
		end
	end,
};

--set up static functions in case the client does not want to use the class

function ini.encode(tTable)
	return encode(tTable);
end

function ini.decode(sString)
	return decode(sString);
end

function ini.load(pFile)
	load(pFile);
end

function ini.save(pFile, tTable)
	save(pFile);
end

return ini;
