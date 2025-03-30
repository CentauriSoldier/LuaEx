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
        super(DoxBuilder.MIME.LUACOMPLETERC, "", "", "\n");
    end,
    build = function(this, cdat, sTitle, sIntro, tFinalizedData)
        -- Initialize the result string
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

        return sRet;
    end,
    formatBlockContent = function(this, cdat, sID, sDisplay, sContent)
        --local sIDSection = (not sID:isempty()) and "[!¬"..sID.."_¬_" or "[!¬";
        return "__!¬"..sDisplay.."__¬_!_"..sContent.."!¬";
    end,
    formatCombinedBlockContent = function(this, cdat, sDisplay, sCombinedContent)
        --TODO note somewhere that combined items cannot have IDs (they are simply blank...all non examples are...but code should have IDs!!!! TODO that)
        return "__!¬"..sDisplay.."__¬_!_"..sCombinedContent.."!¬";
    end,
    refresh = function(this, cdat, tBlocks, tFinalized, fProcessBlockItem)
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

        --process eligible blocks
        for _, oBlock in ipairs(tBlocksToProcess) do

            for oBlockTag, sRawInnerContent in oBlock.eachItem() do
                --TODO LEFT OFF HERE
                print(sRawInnerContent)
            end

        end

    end,
},
DoxBuilder,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
