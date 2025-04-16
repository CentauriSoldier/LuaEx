local _sBuilderName = "PulsarLua";

--[[
@fxqn Dox.DoxBuilder  TODO DOCS getBlocksToPrep
@desc Looks for the PulsarLua tag name and adds the entire block to the return table for processing if found.
!]]
local function getBlocksToPrep(tAllBlocks)
    local tRet = {};

    --determine which blocks are eligible for processing
    for _, oBlock in ipairs(tAllBlocks) do

        for oBlockTag, sRawInnerContent in oBlock.eachItem() do
            local sDisplay = oBlockTag.getDisplay();

            --add eligible blocks to the processing table
            if (sDisplay == _sBuilderName) then
                tRet[#tRet + 1] = oBlock;
                break;
            end

        end

    end

    return tRet;
end


local function prepBlocks(tBlocksToPrep, fProcessBlockItem)
    local tPreppedBlocks    = {};
    local nIndex            = 0;

    --prep eligible blocks
    for _, oBlock in ipairs(tBlocksToPrep) do
        nIndex = nIndex + 1;

        tPreppedBlocks[nIndex] = {
            blockItems = {},
            pulsarLua  = {
                name = "NOT SET",
                type = "NOT SET",
            },
        };

        local tPrepped = tPreppedBlocks[nIndex];

        for oBlockTag, sRawInnerContent in oBlock.eachItem() do

            if (oBlockTag.isUtil() and oBlockTag.getDisplay() == _sBuilderName) then
                local tInfoRAW  = fProcessBlockItem(oBlockTag, sRawInnerContent);
                local tInfo     = tInfoRAW.content:totable(' ');
                tPrepped.pulsarLua.name = tInfo[2];
                tPrepped.pulsarLua.type = tInfo[1];

                --TODO FINISH Check and THROW ERROR on bad values data..eg, type can be only function and table atm...more later perhaps

            else
                sInnerContent = string.htmltomd(sRawInnerContent);
                tPrepped.blockItems[#tPrepped.blockItems + 1] = fProcessBlockItem(oBlockTag, sInnerContent);

            end

        end

    end

    return tPreppedBlocks;
end

--sorts the blocks into a table format based on type (table, function, etc.)
local function organizeBlocks(tPreppedBlocks)
    local tRet = {};

    for _, tBlockData in ipairs(tPreppedBlocks) do
        local tBlockItems   = tBlockData.blockItems;
        local tPulsarLua    = tBlockData.pulsarLua;
        local sType         = tPulsarLua.type;
        local sName         = tPulsarLua.name;
        local tName         = sName:totable(); --TODO THROW ERROR ON Non-table return
        local nNameCount    = #tName;
        local tEntry        = tRet;

        for nIndex, sNamePart in ipairs(tName) do
            --if this is the last item in the name table,
            --store the data in its metatable for later retrieval
            local tCallReturn = (nIndex == nNameCount) and tBlockItems or {};

            --if the table entry doesn't exist, create it
            if (tEntry[sNamePart] == nil) then
                local tMeta = {
                    __call = function(t)
                        return tCallReturn;
                    end,
                    __newindex = function() end,
                };

                tEntry[sNamePart] = setmetatable({}, tMeta);
            end

            --update the current entry location
            tEntry = tEntry[sNamePart];
        end

    end

    return tRet;
end


return class("DoxBuilderPulsarLua",
{--METAMETHODS

},
{--STATIC PUBLIC
    --__INIT = function(stapub) end, --static initializer (runs before class object creation)
    --DoxBuilderPulsarLua = function(this) end, --static constructor (runs after class object creation)
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    DoxBuilderPulsarLua = function(this, cdat, super)
        local tColumnWrappers = {

        };

        super("DoxBuilderPulsarLua", DoxBuilder.MIME.LUACOMPLETERC, "", "", "\n", tColumnWrappers);
    end,
    build = function()

    end,
    buildOLD = function(this, cdat, sTitle, sIntro, tFinalizedData)
        --[[ Initialize the result string
        local sRet = ""

        -- Recursive function to traverse through tables and handle sorting
        local function fTraverseTable(tData, sIndent)
            local sResult = "";

            -- Get and sort the keys of the table
            local tSortedKeys = {};
            for sKey in pairs(tData) do
                table.insert(tSortedKeys, sKey);
            end
            table.sort(tSortedKeys);

            -- Process each key in sorted order
            for _, sKey in ipairs(tSortedKeys) do
                local fSubtable = tData[sKey];
                local sSubData = fSubtable();  -- Call the table to get its data (using __call metamethod)

                -- Append the key and its data in a structured format
                sResult = sResult .. sIndent .. sKey .. ": ";
                if sSubData then

                    local function fHasTagContent(sText, sCheck)
                        return sText:find(sCheck, 1, true) ~= nil
                    end

                    if fHasTagContent(sSubData, "PulsarLua") then
                        print(sKey, sSubData)
                    end

                else
                    --print(type(sSubData))
                end
                sResult = sResult .. "\n";  -- Add newline after each key's data

                -- Recursively process any subtables, appending them directly under the parent
                if type(fSubtable) == "table" then
                    sResult = sResult .. fTraverseTable(fSubtable, sIndent .. "  ");  -- Add indentation for clarity
                end
            end

            return sResult;
        end

        -- Start the recursion with the provided table
        sRet = fTraverseTable(tFinalizedData, "");

        return sRet;]]
        local sRet = [[
{
    "global": {
        "type": "table",
        "fields": {
        ]];

        for sTypeIndex, tItems in pairs(tFinalizedData) do

            if (sTypeIndex == "function") then

                for _, tData in ipairs(tItems) do

                    local sFunctionText = [[

                "${name}": {
                    "type": "function",
                    "description": "${desc}",
                    ${args}
                }]] % {
                        args = tData.args,
                        name = tData.name,
                        desc = tData.description,
                    };

                    sRet = sRet..sFunctionText;

                end

            elseif (sTypeIndex == "table") then

            else
                --TODO THROW ERROR
            end



        end

        return sRet..[[

        }
    }
}]];
    end,
    formatBlockContent = function(this, cdat, sID, sDisplay, sContent)
        --local sIDSection = (not sID:isempty()) and "[!¬"..sID.."_¬_" or "[!¬";
        return "__!¬"..sDisplay.."__¬_!_"..sContent.."!¬";
    end,
    formatCombinedBlockContent = function(this, cdat, sDisplay, sCombinedContent)
        --TODO note somewhere that combined items cannot have IDs (they are simply blank...all non examples are...but code should have IDs!!!! TODO that)
        return "__!¬"..sDisplay.."__¬_!_"..sCombinedContent.."!¬";
    end,
    refresh = function(this, cdat, tAllBlocks, fProcessBlockItem)
        local tFinalized        = {};
        local tBlocksToPrep     = getBlocksToPrep(tAllBlocks);
        local tPreppedBlocks    = prepBlocks(tBlocksToPrep, fProcessBlockItem);
        local tOrganizedBlocks  = organizeBlocks(tPreppedBlocks);

        --LEFT OFF HERE
        for k, v in pairs(tOrganizedBlocks) do
            --print(k, #v)
            for kk, vv in pairs(v()) do
                print(kk, vv)
            end
        end



        return tFinalized;
    end,
    refreshOOLD = function(this, cdat, tBlocks, fProcessBlockItem)
        local tFinalized = {};
        local tBlocksToProcess = {};

        --determine which blocks are eligible for processing
        for _, oBlock in ipairs(tBlocks) do

            for oBlockTag, sRawInnerContent in oBlock.eachItem() do
                local sDisplay = oBlockTag.getDisplay();

                --add eligible blocks to the processing table
                if (sDisplay == "PulsarLua") then
                    tBlocksToProcess[#tBlocksToProcess + 1] = oBlock;
                    break;
                end

            end

        end

        local tPreppedBlocks = {};
        local nIndex = 0;

        --prep eligible blocks
        for _, oBlock in ipairs(tBlocksToProcess) do
            nIndex = nIndex + 1;

            tPreppedBlocks[nIndex] = {
                blockItems = {},
                pulsarLua  = {
                    name = "NOT SET",
                    type = "NOT SET",
                },
            };

            local tPrepped = tPreppedBlocks[nIndex];

            for oBlockTag, sRawInnerContent in oBlock.eachItem() do

                if (oBlockTag.isUtil()) then --TODO THROW ERROR on bad data
                    --break the util blockline up, and get & store the info QUESTION what if there are ither util lines?>
                    local tInfoRAW  = fProcessBlockItem(oBlockTag, sRawInnerContent);
                    local tInfo     = tInfoRAW.content:totable(' ');
                    tPrepped.pulsarLua.name = tInfo[2];
                    tPrepped.pulsarLua.type = tInfo[1];

                else
                    sInnerContent = string.htmltomd(sRawInnerContent);
                    tPrepped.blockItems[#tPrepped.blockItems + 1] = fProcessBlockItem(oBlockTag, sInnerContent);

                end

            end

        end

        tFinalized = {
            ["function"]    = {},
            --table           = {},
        };

        local tFunctions = tFinalized["function"];

        --process prepped blocks
        for _, tData in ipairs(tPreppedBlocks) do
            local sDescription          = "";
            local sParamDescriptions    = "";
            local sArgs                 = "";
            local tArgNames             = {};
            local sName                 = tData.pulsarLua.name;
            local sType                 = tData.pulsarLua.type;

            if (sType == "function") then

                local tBlockItems = tData.blockItems;

                for _, tItem in ipairs(tBlockItems) do
                    --print(tItem.content:htmltomd())
                    if (tItem.display == "Parameter(s)") then

                        local function splitBySpaceLimit(input, limit)
                          local result = {}
                          local i = 1
                          for word in input:gmatch("%S+") do
                            if i < limit then
                              table.insert(result, word)
                            else
                              -- Grab the rest of the string from the remaining position
                              local pos = 0
                              for _ = 1, i - 1 do
                                pos = input:find("%S+%s*", pos + 1)
                              end
                              table.insert(result, input:sub(pos + 1):match("^%s*(.-)%s*$"))
                              break
                            end
                            i = i + 1
                          end
                          return result
                        end


                        local tArg = splitBySpaceLimit(tItem.content, 3);
                        --print(#tArg)

                        tArgNames[#tArgNames + 1] = tArg[2];
                        sParamDescriptions = sParamDescriptions.."\\n"..tItem.content;
                        --print(_, tItem)
                        --print(tItem.content:htmltomd())
                    elseif (tItem.display == "Description") then
                        sDescription = tItem.content:trim():htmltomd():gsub("\n", "\\n");
                    end

                end

                if (#tArgNames > 0) then
                    local function formatArgs(paramNames)
                        local parts = { '"args": [' }

                        for i, name in ipairs(paramNames) do
                            local comma = (i < #paramNames) and "," or ""
                            table.insert(parts, string.format('  { "name": "%s" }%s', name, comma))
                        end

                        table.insert(parts, "],")

                        return table.concat(parts, "\n")
                    end

                    sArgs = formatArgs(tArgNames);
                end

                tFunctions[#tFunctions + 1] = {
                    description = (sDescription.."\\n"..sParamDescriptions:trim()):gsub("\n", "\\n"),
                    name        = sName,
                    args        = sArgs,
                };
            else
                --TODO THROW ERROR for non-existent type
            end

        end

        return tFinalized;
    end,
},
DoxBuilder,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
