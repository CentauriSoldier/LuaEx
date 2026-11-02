local type      = type;
local rawtype   = rawtype;
local ipairs    = ipairs;
local table     = table;
local clone     = clone;
local istable   = type.istable;
local isstring  = type.isstring;
local isnumber  = type.isnumber;

local function buildLineTable(nIndex, sLine)
    local tRet = {
        prefix      = "",
        coupler     = "",
        suffix      = "",
        rawIndex    = nIndex,
    };

    local bFound = false;

    if (sLine:match("^%s*#")) then -- comment #
        tRet.prefix     = "#";
        tRet.coupler    = " ";
        tRet.suffix     = sLine:gsub("^%s*#%s*", "");
        bFound = true;
    end

    if (not bFound and sLine:match("^%s*;")) then -- comment ;
        tRet.prefix     = ";";
        tRet.coupler    = " ";
        tRet.suffix     = sLine:gsub("^%s*;%s*", "");
        bFound = true;
    end

    if (not bFound and sLine:match("^%s*$")) then -- blank line
        tRet.prefix     = "";
        tRet.coupler    = "";
        tRet.suffix     = "";
        bFound = true;
    end

    if (not bFound) then
        local sValue, sData = sLine:match("^%s*(.-)%s*=%s*(.-)%s*$");

        if (sValue and sData) then
            tRet.prefix     = sValue;
            tRet.coupler    = " = ";
            tRet.suffix     = sData;
            bFound = true;
        end
    end

    if (not bFound) then
        error("Error deserializing ini.\nMalformed ini line at index "..nIndex..".\n'"..sLine.."'", 3);
    end

    return tRet;
end

local function importString(sInput)
    local tRawData          = sInput:totable("\n", true);
    local tSections         = {};
    local sActiveSection    = nil;
    local tSectionOrder     = {};
    local tTop              = {};
    local bEndingLine       = sInput:match("\n$") ~= nil;

    -- start by creating the sections and inserting their lines
    for nIndex, sLine in ipairs(tRawData) do
        local sSection = sLine:match("^%s*%[(.-)%]%s*$");

        -- if this is a section, create it (or throw a duplicate error)
        if (sSection) then

            if (rawtype(tSections[sSection]) ~= "nil") then
                error("Error deserializing ini.\nDuplicate section in ini string at index "..nIndex..".\n'"..sSection.."'", 3);
            end

            -- log the section order for later encoding
            table.insert(tSectionOrder, sSection);

            tSections[sSection] = {
                ordinal = #tSectionOrder,
                lines   = {},
            };

            sActiveSection = sSection;
        else
            -- create the line and store it in the proper section (or the top)
            local tLine = buildLineTable(nIndex, sLine);

            if (sActiveSection) then
                table.insert(tSections[sActiveSection].lines, tLine);
            else
                table.insert(tTop, tLine);
            end
        end
    end

    -- validate the value names
    for _, sSection in ipairs(tSectionOrder) do
        local tValueNames = {};

        for __, tLine in ipairs(tSections[sSection].lines) do
            local sPrefix = tLine.prefix;

            if (sPrefix ~= "" and sPrefix ~= "#" and sPrefix ~= ";" and tValueNames[sPrefix]) then
                error("Error deserializing ini.\nDuplicate value name in ini string at index "..tLine.rawIndex..".\n'"..sPrefix.."'", 3);
            end

            -- log the value name for duplicate test
            tValueNames[sPrefix] = true;
        end
    end

    return tTop, tSections, tSectionOrder, bEndingLine;
end


local function GetRawValue(pri, sSection, sValue)
    local tSection = nil;
    local sRet = nil;

    if (rawtype(sSection) == "string" and sSection ~= "" and rawtype(sValue) == "string" and sValue ~= "") then
        tSection = pri.sections[sSection];

        if (rawtype(tSection) == "table") then

            for _, tLine in ipairs(tSection.lines) do
                if (tLine.prefix == sValue and tLine.prefix ~= "#" and tLine.prefix ~= ";" and tLine.prefix ~= "") then
                    sRet = tLine.suffix;
                    break;
                end
            end

        end

    end

    return sRet;
end

local function ResolveWriteSection(pri, sSectionName, sValName, tVisited)
    local sRet = tostring(sSectionName or "");
    local sCurSection = tostring(sSectionName or "");
    local sKeyName = tostring(sValName or "");
    local bDone = false;
    local sVisitKey;
    local sRaw;
    local sTrimmed;
    local bIsRef;
    local sRefSection;

    tVisited = istable(tVisited) and tVisited or {};

    while (not bDone and sCurSection ~= "" and sKeyName ~= "") do
        sVisitKey = sCurSection..":"..sKeyName;

        if (tVisited[sVisitKey]) then
            sRet = sCurSection;
            bDone = true;
        else
            tVisited[sVisitKey] = true;

            sRaw = GetRawValue(pri, sCurSection, sKeyName);
            sRaw = isstring(sRaw) and sRaw or "";
            sTrimmed = sRaw:trim();

            bIsRef = (not sTrimmed:isempty())
                 and (sTrimmed:sub(1, 1) == "<")
                 and (sTrimmed:sub(-1) == ">");

            if not (bIsRef) then
                sRet = sCurSection;
                bDone = true;
            else
                sRefSection = sTrimmed:sub(2, -2):trim();

                if (sRefSection:isempty()) then
                    sRet = sCurSection;
                    bDone = true;
                else
                    sCurSection = sRefSection;
                    sRet = sCurSection;
                end

            end

        end

    end

    return sRet;
end


local Ini;

return class("Ini",
{--METAMETHODS
    __serialize = function(this, cdat)
        local pri = cdat.pri;

        return {
            sectionOrder    = pri.sectionOrder,
            sections        = pri.sections,
            top             = pri.top,
            endingLine      = pri.endingLine,
        };
    end,

    __tostring = function(this, cdat)
        local sRet = "";
        local pri = cdat.pri;

        for _, tLine in ipairs(pri.top) do
            sRet = sRet..tLine.prefix..tLine.coupler..tLine.suffix.."\n";
        end

        for _, sSection in ipairs(pri.sectionOrder) do
            sRet = sRet.."["..sSection.."]\n";

            for __, tLine in ipairs(pri.sections[sSection].lines) do
                sRet = sRet..tLine.prefix..tLine.coupler..tLine.suffix.."\n";
            end
        end

        if (not pri.endingLine) then
            sRet = sRet:gsub("\n$", "");
        end

        return sRet;
    end
},
{--STATIC PUBLIC
    Ini = function(cIni)
        Ini = cIni;
    end,

    deserialize = function(tData)
        return Ini(tData);
    end,
},
{--PRIVATE
    sectionOrder    = {},
    sections        = {},
    top             = {},
    endingLine      = false,
},
{--PROTECTED

},
{--PUBLIC
    Ini = function(this, cdat, vInput, bFromFile)
        local pri = cdat.pri;
        local sType = rawtype(vInput);

        if (bFromFile) then
            if (sType ~= "string") then
                error("Ini constructor: file mode requires string path.", 2);
            end

            local hFile, sErr = io.open(vInput, "rb");

            if not (hFile) then
                error("Ini constructor: failed to open file '"..vInput.."'. "..tostring(sErr), 2);
            end

            local sText = hFile:read("*a");
            hFile:close();

            if not (rawtype(sText) == "string") then
                error("Ini constructor: failed to read file '"..vInput.."'.", 2);
            end

            pri.top, pri.sections, pri.sectionOrder, pri.endingLine = importString(sText);

        elseif (sType == "string") then
            pri.top, pri.sections, pri.sectionOrder, pri.endingLine = importString(vInput);

        elseif (sType == "table") then
            pri.sectionOrder = rawtype(vInput.sectionOrder) == "table" and clone(vInput.sectionOrder) or {};
            pri.sections     = rawtype(vInput.sections) == "table" and clone(vInput.sections) or {};
            pri.top          = rawtype(vInput.top) == "table" and clone(vInput.top) or {};
            pri.endingLine   = vInput.endingLine and true or false;

        else
            error("Ini constructor: expected string, table, or file path. Got "..sType..".", 2);
        end
    end,
    DeleteSection = function(this, cdat, sSection)
        local pri = cdat.pri;
        local bRet = false;

        if (rawtype(sSection) == "string" and sSection ~= "") then

            if (rawtype(pri.sections[sSection]) ~= "nil") then
                pri.sections[sSection] = nil;

                for nIndex, sName in ipairs(pri.sectionOrder) do
                    if (sName == sSection) then
                        table.remove(pri.sectionOrder, nIndex);
                        break;
                    end
                end

                bRet = true;
            end

        end

        return bRet;
    end,

    DeleteValue = function(this, cdat, sSection, sValue)
        local pri = cdat.pri;
        local tSection = nil;
        local bRet = false;

        if (rawtype(sSection) == "string" and sSection ~= "" and rawtype(sValue) == "string" and sValue ~= "") then
            tSection = pri.sections[sSection];

            if (rawtype(tSection) == "table") then

                for nIndex, tLine in ipairs(tSection.lines) do
                    if (tLine.prefix == sValue and tLine.prefix ~= "#" and tLine.prefix ~= ";" and tLine.prefix ~= "") then
                        table.remove(tSection.lines, nIndex);
                        bRet = true;
                        break;
                    end
                end

            end

        end

        return bRet;
    end,

    GetSectionNames = function(this, cdat)
        local pri = cdat.pri;
        local tRet = {};

        for _, sSection in ipairs(pri.sectionOrder) do
            table.insert(tRet, sSection);
        end

        table.sort(tRet);

        return tRet;
    end,

    GetValue = function(this, cdat, sSection, sValue, bInherit, tVisited, tChain)
        local pri           = cdat.pri;
        local sRet          = "";
        local sRaw          = nil;
        local sTrimmed      = "";
        local bIsRef        = false;
        local sRefSection   = "";
        local sVisitKey     = "";
        local tOutChain     = nil;

        if (rawtype(sSection) == "string" and sSection ~= "" and rawtype(sValue) == "string" and sValue ~= "") then

            if not (bInherit == true) then
                sRet = GetRawValue(pri, sSection, sValue);
                sRet = isstring(sRet) and sRet or "";
            else
                tVisited = istable(tVisited) and tVisited or {};
                sVisitKey = tostring(sSection)..":"..tostring(sValue);

                if (tVisited[sVisitKey]) then
                    sRet = "";
                    tOutChain = istable(tChain) and tChain or nil;
                else
                    tVisited[sVisitKey] = true;

                    sRaw = GetRawValue(pri, sSection, sValue);
                    sRaw = isstring(sRaw) and sRaw or "";
                    sTrimmed = sRaw:trim();

                    bIsRef = (not sTrimmed:isempty())
                         and (sTrimmed:sub(1, 1) == "<")
                         and (sTrimmed:sub(-1) == ">");

                    if (bIsRef) then
                        sRefSection = sTrimmed:sub(2, -2):trim();

                        if not (sRefSection:isempty()) then
                            tChain = istable(tChain) and tChain or {};
                            tChain[#tChain + 1] = sRefSection;
                            sRet, tOutChain = this.GetValue(sRefSection, sValue, true, tVisited, tChain);
                            sRet = isstring(sRet) and sRet or "";
                        else
                            sRet = "";
                            tOutChain = istable(tChain) and tChain or nil;
                        end
                    else
                        sRet = sRaw;
                        tOutChain = istable(tChain) and tChain or nil;
                    end

                    tVisited[sVisitKey] = nil;
                end

            end

        end

        sRet = isstring(sRet) and sRet or "";
        return sRet, tOutChain;
    end,

    GetValueBoolean = function(this, cdat, sSection, sValue, bInherit)
        local sRaw = nil;
        local bRet = false;

        sRaw = this.GetValue(sSection, sValue, bInherit);

        if (isstring(sRaw)) then
            bRet = sRaw:lower() == "true" and true or false;
        end

        return bRet;
    end,

    GetValueNumber = function(this, cdat, sSection, sValue, nDefault, bInherit)
        local sRaw = nil;
        local nValue = nil;
        local nRet = rawtype(nDefault) == "number" and nDefault or 0;

        sRaw = this.GetValue(sSection, sValue, bInherit);

        if (isstring(sRaw)) then
            nValue = tonumber(sRaw);

            if (isnumber(nValue)) then
                nRet = nValue;
            end

        end

        return nRet;
    end,

    GetValueNames = function(this, cdat, sSection)
        local pri = cdat.pri;
        local tRet = {};
        local tSection = nil;

        if (rawtype(sSection) == "string" and sSection ~= "") then
            tSection = pri.sections[sSection];

            if (rawtype(tSection) == "table") then

                for _, tLine in ipairs(tSection.lines) do
                    if (tLine.prefix ~= "" and tLine.prefix ~= "#" and tLine.prefix ~= ";") then
                        table.insert(tRet, tLine.prefix);
                    end
                end

                table.sort(tRet);
            end

        end

        return tRet;
    end,

    SetValue = function(this, cdat, sSection, sValue, sData, bRespectChain)
        local pri = cdat.pri;
        local tSection = nil;
        local sDataType = rawtype(sData);
        local bRet = false;
        local sTargetSection = sSection;

        if (rawtype(sSection) == "string" and sSection ~= "" and rawtype(sValue) == "string" and sValue ~= "" and sValue ~= "#" and sValue ~= ";") then

            if (sDataType == "string" or sDataType == "number" or sDataType == "boolean") then

                if (bRespectChain == true) then
                    sTargetSection = ResolveWriteSection(pri, sSection, sValue, {});
                end

                tSection = pri.sections[sTargetSection];

                if (rawtype(tSection) ~= "table") then
                    table.insert(pri.sectionOrder, sTargetSection);
                    pri.sections[sTargetSection] = {
                        ordinal = #pri.sectionOrder,
                        lines   = {},
                    };
                    tSection = pri.sections[sTargetSection];
                end

                sData = tostring(sData);

                for _, tLine in ipairs(tSection.lines) do
                    if (tLine.prefix == sValue and tLine.prefix ~= "#" and tLine.prefix ~= ";" and tLine.prefix ~= "") then
                        tLine.suffix = sData;
                        bRet = true;
                        break;
                    end
                end

                if not (bRet) then
                    table.insert(tSection.lines, {
                        prefix      = sValue,
                        coupler     = " = ",
                        suffix      = sData,
                        rawIndex    = 0,
                    });
                    bRet = true;
                end

            end

        end

        return bRet;
    end,
},
nil,   -- extending class
true,  -- if the class is final
nil    -- interface(s)
);
