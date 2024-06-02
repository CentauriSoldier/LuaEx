--OMG use queues for output
--[[TODO
    Use MD for text
    Allow internal anchor links
    Allow external links
]]

local assert    = assert;
local class     = class;
local rawtype   = rawtype;
local string    = string;
local table     = table;
local type      = type;

local tRequiredGroupBlockTags;
tRequiredGroupBlockTags = setmetatable(--these block tags must exist within each dox block tag group
{
    [1] = "mod",
    [2] = "name",
},
{
    __call = function(__IGNORE__)
        local nIndex    = 0;
        local nMax      = #tRequiredGroupBlockTags;

        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                return nIndex, tRequiredGroupBlockTags[nIndex];
            end

        end

    end,
    __unm = function()
        local tRet = {};

        for nIndex, sName in tRequiredGroupBlockTags() do
            tRet[nIndex] = false;
        end

        return tRet;
    end,
});

--[[f!
    @mod dox
    @func escapePattern
    @desc Escapes special characters in a string so it can be used in a Lua pattern match.
    @param pattern A string containing the pattern to be escaped.
    @ret Returns the escaped string with special characters prefixed by a `%`.
!f]]
local function escapePattern(pattern)
    return pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end


--[[
██████╗ ██╗      ██████╗  ██████╗██╗  ██╗████████╗ █████╗  ██████╗
██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝╚══██╔══╝██╔══██╗██╔════╝
██████╔╝██║     ██║   ██║██║     █████╔╝    ██║   ███████║██║  ███╗
██╔══██╗██║     ██║   ██║██║     ██╔═██╗    ██║   ██╔══██║██║   ██║
██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗   ██║   ██║  ██║╚██████╔╝
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ]]
local DoxBlockTag = class("DoxBlockTag",
    {--metamethods

    },
    {--static public

    },
    {--private
        display             = "",
        items_AUTO          = 0,
        multipleAllowed     = false,
        names               = {},
        required            = false,
    },
    {--protected

    },
    {--public
        DoxBlockTag = function(this, cdat, tNames, sDisplay, nItems, bRequired, bMultipleAllowed)
            type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.")
            type.assert.number(nItems, true, true, false, true);


            cdat.pri.display         = sDisplay;
            cdat.pri.items           = nItems;
            cdat.pri.multipleAllowed = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;
            cdat.pri.required        = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;

            for _, sName in pairs(tNames) do
                type.assert.string(sName, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
                cdat.pri.names[#cdat.pri.names + 1] = sName;
            end

        end,
        isMultipleAllowed = function(this, cdat)
            return cdat.pri.multipleAllowed;
        end,
        isRequired = function(this, cdat)
            return cdat.pri.required;
        end,
        clone = function(this, cdat) --OMG TODO
            return this;
        end,
        getDisplay = function(this, cdat)
            return cdat.pri.display;
        end,
        hasRequired = function(this, cdat, sRequired)
            local bRet = false;

            for _, sTagName in pairs(cdat.pri.names) do

                if (sTagName:lower() == sRequired:lower()) then
                    bRet = true;
                    break;
                end

            end

            return bRet;
        end,
        names = function(this, cdat)
            local nIndex = 0;
            local tNames = cdat.pri.names;
            local nMax   = #tNames;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nMax) then
                    return tNames[nIndex];
                end

            end

        end
    },
    nil, true
);


--[[
██████╗ ██╗      ██████╗  ██████╗██╗  ██╗████████╗ █████╗  ██████╗  ██████╗ ██████╗  ██████╗ ██╗   ██╗██████╗
██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝╚══██╔══╝██╔══██╗██╔════╝ ██╔════╝ ██╔══██╗██╔═══██╗██║   ██║██╔══██╗
██████╔╝██║     ██║   ██║██║     █████╔╝    ██║   ███████║██║  ███╗██║  ███╗██████╔╝██║   ██║██║   ██║██████╔╝
██╔══██╗██║     ██║   ██║██║     ██╔═██╗    ██║   ██╔══██║██║   ██║██║   ██║██╔══██╗██║   ██║██║   ██║██╔═══╝
██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗   ██║   ██║  ██║╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ]]
local DoxBlockTagGroup = class("DoxBlockTagGroup",
    {--metamethods

    },
    {--static public

    },
    {--private
        blockTags = {},
        close       = "",
        name        = "",
        namePlural  = "",
        open        = "",
    },
    {--protected

    },
    {--public
        DoxBlockTagGroup = function(this, cdat, sName, sNamePlural, sOpen, sClose, ...)
            type.assert.string(sName,        "%S+", "Dox block tag group name must not be blank.");
            type.assert.string(sNamePlural,  "%S+", "Dox block tag group plural name must not be blank.");
            type.assert.string(sOpen,        "%S+", "Dox block tag group open symbol(s) must not be blank.");
            type.assert.string(sClose,       "%S+", "Dox block tag group close symbol(s) must not be blank.");


            local pri = cdat.pri;
            pri.name           = sName;
            pri.namePlural     = sNamePlural
            pri.open           = sOpen;
            pri.close          = sClose;

            --a table to track all required tags
            local nRequiredTags         = #tRequiredGroupBlockTags;
            local tRequiredTagsFound    = -tRequiredGroupBlockTags;

            local tBlockTags = pri.blockTags;
            for _, oBlockTag in pairs({...} or arg) do
                --TODO QUESTION should i check that this tag is set to bRequired in the input?
                for nIndex, sTag in tRequiredGroupBlockTags() do

                    if (not (tRequiredTagsFound[nIndex]) and oBlockTag.hasRequired(sTag) ) then
                        tRequiredTagsFound[nIndex] = true;
                    end

                end

                type.assert.custom(oBlockTag, "DoxBlockTag");
                tBlockTags[#tBlockTags + 1] = oBlockTag.clone();
            end

            --check that every required tag has been created in the group
            for nIndex, bFound in pairs(tRequiredTagsFound) do

                if (not bFound) then
                    error(  "Error creating Block Tag Group, '${taggroup}'.\nA '${tag}' tag is required (though its Display may be any string)." %
                            {taggroup = sName, tag = tRequiredGroupBlockTags[nIndex]});
                end

            end

        end,
        blockTags = function(this, cdat)
            local tBlockTags    = cdat.pri.blockTags;
            local nIndex        = 0;
            local nMax          = #tBlockTags;

            return function()
                nIndex = nIndex + 1;

                if (nIndex <= nMax) then
                    return tBlockTags[nIndex];
                end

            end

        end,
        clone = function(this, cdat) --OMG TODO
            return this;
        end,
        getBlockClose = function(this, cdat)
            return cdat.pri.close;
        end,
        getBlockOpen = function(this, cdat)
            return cdat.pri.open;
        end,
        getName = function(this, cdat)
            return cdat.pri.name;
        end,
    },
    nil, true
);


--[[
███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗     ███████╗
████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔════╝
██╔████╔██║██║   ██║██║  ██║██║   ██║██║     █████╗
██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══╝
██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗███████╗
╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝]]
local DoxModule = class("DoxModule",
{--metamethods

},
{--static public

},
{--private
    moduleBlockTagGroup = null,
    name = "",
},
{--protected

},
{--public
    DoxModule = function(this, cdat, sName, sBlock, oModuleBlockTagGroup)--sBlock
        type.assert.string(sName, "%S+");
        type.assert.custom(oModuleBlockTagGroup, "DoxBlockTagGroup");

        local pri = cdat.pri;

        pri.name = sName;
        pri.moduleBlockTagGroup = oModuleBlockTagGroup;
    end,
    importBlock = function(this, cdat)
        type.assert.string(sBlock, "%S+");
        --sBlock
    end,
},
nil,    --extending class
false,   --if the class is final
nil    --interface(s) (either nil, or interface(s))
);


--[[
██████╗  ██████╗ ██╗  ██╗
██╔══██╗██╔═══██╗╚██╗██╔╝
██║  ██║██║   ██║ ╚███╔╝
██║  ██║██║   ██║ ██╔██╗
██████╔╝╚██████╔╝██╔╝ ██╗
╚═════╝  ╚═════╝ ╚═╝  ╚═╝]]
return class("Dox",
{--metamethods
    __tostring = function()
        --TODO this should display the open/close stuff +
    end,
},
{--static public
    MIME = enum("MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
},
{--private
    blockTagGroups      = {}, --this contains groups of block tags group objects
    moduleBlockTagGroup = null,
    mimeTypes           = null,
    modules             = sorteddictionary(), --a list of module objects indexed by module names
    name                = "",
    snippetClose        = "", --QUESTION How will this work now that we're using mutiple tag groups?
    snippetOpen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    --Start 	= "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	= "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagOpen             = "",
    --toprocess           = {}, --this is a holding table for strings which need to be parsed for blocks
    extractBlocks = function(this, cdat, sInput)
        local tModuleBlocks = null;
        local tBlocks       = {};
        local fTrim         = string.trim;

        local oModuleBlockTagGroup  = cdat.pri.moduleBlockTagGroup;
        local fBlockTagGroups       = cdat.pub.blockTagGroups;

        -- Helper function to extract blocks from input based on open and close tags
        local function extractFenceBlocks(sBlockTagGroupName, sInput, sOpen, sClose)
            local tRet           = {};
            local sEscapedOpen   = escapePattern(sOpen);
            local sEscapedClose  = escapePattern(sClose);

            if not (tRet[sBlockTagGroupName]) then
                tRet[sBlockTagGroupName] = {};
            end

            for sMatch in sInput:gmatch(sEscapedOpen .. "(.-)" .. sEscapedClose) do
                table.insert(tRet[sBlockTagGroupName], fTrim(sMatch));
            end

                return tRet;
            end

            -- Extract module blocks
            local sModuleOpen   = oModuleBlockTagGroup.getBlockOpen();
            local sModuleClose  = oModuleBlockTagGroup.getBlockClose();
            tModuleBlocks       = extractFenceBlocks(oModuleBlockTagGroup:getName(), sInput, sModuleOpen, sModuleClose);

            -- Extract other blocks
            for oBlockTagGroup in fBlockTagGroups() do
                local sOpen         = oBlockTagGroup.getBlockOpen();
                local sClose        = oBlockTagGroup.getBlockClose();
                local tGroupBlocks  = extractFenceBlocks(oBlockTagGroup.getName(), sInput, sOpen, sClose);
                table.insert(tBlocks, tGroupBlocks);
            end

        return tModuleBlocks, tBlocks;
    end,
    parseBlock = function(this, cdat, sBlock, bIsModule)

    end,
    processString = function(this, cdat, sInput)
        local pri                   = cdat.pri;
        local oModuleBlockTagGroup  = pri.moduleBlockTagGroup;
        --get all blocks from the string
        local tModuleBlocks, tBlocks = pri.extractBlocks(sInput);

        --TODO process \@ symbols?
        --process each module block
        for sName, sBlock in pairs(tModuleBlocks) do

            --WTF LEFT OFF HERE ...need to get the name of the module
            --create the module (if it doesn't exist)
            if not (pri.modules[sName]) then
                pri.modules[sName] = DoxModule(sName, sBlock, oModuleBlockTagGroup);
            end

            --create the "Orphaned" module for items that name a non-existent module

            --local sOpen                 = oModuleBlockTagGroup:getopen();
            --local sClose                = oModuleBlockTagGroup:getclose();
        --    local oUnknownModule        = doxmodule("Orphaned");


            --process all other types of blocks and import them into modules

        end

        for _, sBlock in pairs(tBlocks) do

        end

        return tModuleBlocks, tBlocks;
    end,
},
{--protected
    blockTag        = DoxBlockTag,
    blockTagGroup   = DoxBlockTagGroup,
},
{--public
    Dox = function(this, cdat, sName, tMimeTypes, sTagOpen, oModuleBlockTagGroup, ...)--TODO take moduleinfo, struct, enum and constant block tags too
        type.assert.string(sName,    "%S+", "Dox subclass name must not be blank.");
        type.assert.string(sTagOpen, "%S+", "Open tag symbol must not be blank.");
        type.assert.custom(oModuleBlockTagGroup, "DoxBlockTagGroup");
        type.assert.table(tMimeTypes, "number", "string", 1);

        local pri               = cdat.pri;
        pri.mimeTypes           = Set(tMimeTypes);
        pri.name                = sName;
        pri.tagOpen             = sTagOpen;
        pri.moduleBlockTagGroup = oModuleBlockTagGroup;

        --TODO put block tags in order of display (as input)!
        --TODO clone these properly
        local tBlockTagGroups = pri.blockTagGroups;

        for _, oBlockTagGroup in pairs({...} or arg) do
            type.assert.custom(oBlockTagGroup, "DoxBlockTagGroup");
            tBlockTagGroups[#tBlockTagGroups + 1] = oBlockTagGroup.clone();
        end

    end,
    addMineType = function(this, cdat, sType)
        type.assert.string(sType,    "%S+", "Mime type must not be blank.");
        cdat.pri.mimeTypes.add(sType);
    end,
    blockTagGroups = function(this, cdat)
        local tBlockTagGroups = cdat.pri.blockTagGroups;
        local nIndex            = 0;
        local nMax              = #tBlockTagGroups;


        return function()
            nIndex = nIndex + 1;

            if (nIndex <= nMax) then
                --print(nIndex)
                return tBlockTagGroups[nIndex];
            end

        end

    end,
    export = function(this, cdat, pDir, eMimeType, bPulsar)

    end,
    getModuleClose = function(this, cdat)
        return cdat.pri.moduleClose;
    end,
    getModuleOpen = function(this, cdat)
        return cdat.pri.moduleOpen;
    end,
    getName = function(this, cdat)
        return cdat.pri.name;
    end,
    getTagOpen = function(this, cdat)
        return cdat.pri.tagOpen;
    end,
    importDirectory = function(this, cdat, bRecurse)

    end,
    importFile = function(this, cdat)

    end,
    importString = function(this, cdat, sInput)
        type.assert.string(sInput);
        --type.assert.string(sBlockTagGroupName);
        --local oBlockTagGroup = nil;

        --for oBTG in this.BlockTagGroups() do

        --    if (oBTG.getname() == sBlockTagGroupName) then--TODO should htese be case sensitive?
        --        oBlockTagGroup = oBTG;
        --        break;
        --    end

        --end

        --assert( type(oBlockTagGroup) == "DoxBlockTagGroup",
        --        "Error importing string. Block Tag Group name, '${name}', does not exist." % {name = sBlockTagGroupName});

        --local pri = cdat.pri;
        --print(oBlockTagGroup.getblockopen(), oBlockTagGroup.getblockclose())
        --local tBlocks = extractBlocks(sInput, oBlockTagGroup.getblockopen(), oBlockTagGroup.getblockclose());

--[[
        function parseText(text)
    local result = {}
    local escaped = false
    local currentItem = ""

    for i = 1, #text do
        local char = text:sub(i, i)
        if char == "\\" then
            -- Toggle escape mode
            escaped = not escaped
        elseif char == "@" and not escaped then
            -- Start a new item
            if currentItem ~= "" then
                table.insert(result, { currentItem })
                currentItem = ""
            end
        else
            -- Append character to current item
            currentItem = currentItem .. char
            -- Reset escape mode if character is not an escape character
            escaped = false
        end
    end

    -- Insert the last item
    if currentItem ~= "" then
        table.insert(result, { currentItem:gsub("\\@", "@") })
    end
]]

    return cdat.pri.processString(sInput);

    --return result
--end





--[[
        for k, v in pairs(tBlocks) do
            local tTags = parseText(v);

            for kk, vv in pairs(tTags) do


                for kkk, vvv in pairs(vv) do
                    print(kkk, vvv)
                end

            end

        end


]]

        --local tModuleInfo = extractBlocks(pri);
        --local tFunctionBlocks = extractBlocks(sInput, pri.blco);

    end,
    mineTypes = function(this, cdat)--TODO should I clone the set? probably/
        return cdat.pri.mimeTypes;
    end,
},
nil,    --extending class
false,   --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
