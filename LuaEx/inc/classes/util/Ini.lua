local type = type;

local function buildLineTable(nIndex, sLine)
    local tRet = {
        prefix      = "",
        coupler     = "",
        suffix      = "",
        rawIndex    = nIndex,
    };

    local bFound = false;

    if (sLine:match("^%s*#")) then--comment #
        tRet.prefix     = "#";
        tRet.coupler    = " ";
        tRet.suffix     = sLine:gsub("^%s*#%s*", "");
        bFound = true;
    end

    if (sLine:match("^%s*;")) then--comment ;
        tRet.prefix     = ";";
        tRet.coupler    = " ";
        tRet.suffix     = sLine:gsub("^%s*;%s*", "");
        bFound = true;
    end

    if (not found and sLine:match("^%s*$")) then--blank line
        tRet.prefix     = "";
        tRet.coupler    = "";
        tRet.suffix     = "";
        bFound = true;
    end

    if not (bFound) then
        local sValue, sData = sLine:match("^%s*(.-)%s*=%s*(.-)%s*$");

        if (sValue and sData) then
            tRet.prefix     = sValue;
            tRet.coupler    = " = ";
            tRet.suffix     = sData;
            bFound = true;
        end

    end

    if not (bFound) then
        error("Error deserializing ini.\nMalformed ini line at index "..nIndex..".\n'"..sLine.."'", 3);
    end

    return tRet;
end







local function importString(sInput)
    local tRawData          = sInput:totable("\n", true);
    local tSections         = {};
    local sActiveSection    = nil;
    local tSectionOrder     = {};
    local tTop = {};

    --start by creating the sections and inserting their lines
    for nIndex, sLine in ipairs(tRawData) do
        local sSection = sLine:match("^%s*%[(.-)%]%s*$");

        --if this is a section, create it (or throw a duplicate error)
        if (sSection) then

            if (rawtype(tSections[sSection]) ~= "nil") then
                error("Error deserializing ini.\nDuplicate section in ini string at index "..nIndex..".\n'"..sSection.."'", 3);
            end

            --log the section order for later encoding
            table.insert(tSectionOrder, sSection);

            tSections[sSection] = {
                ordinal     = nSectionOrdinal,
                lines       = {},
            };

            sActiveSection = sSection;
        else
            --create the line and store it in the proper section (or the top)
            local tLine = buildLineTable(nIndex, sLine);

            if sActiveSection then
                table.insert(tSections[sActiveSection].lines, tLine);
            else
                table.insert(tTop, tLine);
            end

        end

    end

    --validate the value names
    for _, sSection in pairs(tSectionOrder) do
        local tValueNames = {};

        for __, tLine in pairs(tSections[sSection].lines) do
            local sPrefix = tLine.prefix;

            if (sPrefix ~= "" and sPrefix ~= "#" and sPrefix ~= ";" and tValueNames[sPrefix]) then
                error("Error deserializing ini.\nDuplicate value name in ini string at index "..tLine.rawIndex..".\n'"..sPrefix.."'");
            end

            --log the value name for duplicate test
            tValueNames[sPrefix] = true;
        end

    end

    return tTop, tSections, tSectionOrder;
end

return class("Ini",
{--METAMETHODS
    __serialize = function(this, cdat)
        local pri = cdat.pri;

        local tData = {
            sectionOrder = pri.sectionOrder,
            sections     = pri.sections,
            top          = pri.top,
            endingLine   = pri.endingLine,
        };
    end,

    __tostring = function(this, cdat)
        local sRet = "";
        local pri = cdat.pri;

        for _, tLine in pairs(pri.top) do
            sRet = sRet..tLine.prefix..tLine.coupler..tLine.suffix.."\n";
        end

        for _, sSection in pairs(pri.sectionOrder) do
            sRet = sRet.."["..sSection..']\n';

            for __, tLine in pairs(pri.sections[sSection].lines) do
                sRet = sRet..tLine.prefix..tLine.coupler..tLine.suffix.."\n";
            end

        end

        if (bExcludeEndLine) then
            sRet = sRet:gsub("\n*$", "");
        end

        return sRet;
    end

},
{--STATIC PUBLIC
    deserialize = function(sData)

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
    Ini = function(this, cdat, vInput)
        local sType = rawtype(vInput);
        local pri = cdat.pri;

        if (sType == "string") then
            pri.top, pri.sections, pri.sectionOrder = importString(vInput);

        elseif (sType == "table") then

        else

        end

    end
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
