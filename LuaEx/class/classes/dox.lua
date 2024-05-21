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
local doxblocktag = class("doxblocktag",
    {--metamethods

    },
    {--static public

    },
    {--private
        display             = "",
        items_AUTO          = 0,
        multipleallowed     = false,
        names               = {},
        required            = false,
    },
    {--protected

    },
    {--public
        doxblocktag = function(this, cdat, tNames, sDisplay, nItems, bRequired, bMultipleAllowed)
            type.assert.string(sDisplay, "%S+", "Block tag display name cannot be blank.")
            type.assert.number(nItems, true, true, false, true);


            cdat.pri.display         = sDisplay;
            cdat.pri.items           = nItems;
            cdat.pri.multipleallowed = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;
            cdat.pri.required        = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;

            for _, sName in pairs(tNames) do
                type.assert.string(sName, "^[^%s]+$", "Block tag must be a non-blank string containing no space characters.");
                cdat.pri.names[#cdat.pri.names + 1] = sName;
            end

        end,
        ismultipleallowed = function(this, cdat)
            return cdat.pri.multipleallowed;
        end,
        isrequired = function(this, cdat)
            return cdat.pri.required;
        end,
        clone = function(this, cdat) --OMG TODO
            return this;
        end,
        getdisplay = function(this, cdat)
            return cdat.pri.display;
        end,
        hasrequired = function(this, cdat, sRequired)
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
    nil, nil, true
);


--[[
██████╗ ██╗      ██████╗  ██████╗██╗  ██╗████████╗ █████╗  ██████╗  ██████╗ ██████╗  ██████╗ ██╗   ██╗██████╗
██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝╚══██╔══╝██╔══██╗██╔════╝ ██╔════╝ ██╔══██╗██╔═══██╗██║   ██║██╔══██╗
██████╔╝██║     ██║   ██║██║     █████╔╝    ██║   ███████║██║  ███╗██║  ███╗██████╔╝██║   ██║██║   ██║██████╔╝
██╔══██╗██║     ██║   ██║██║     ██╔═██╗    ██║   ██╔══██║██║   ██║██║   ██║██╔══██╗██║   ██║██║   ██║██╔═══╝
██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗   ██║   ██║  ██║╚██████╔╝╚██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║
╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ]]
local doxblocktaggroup = class("doxblocktaggroup",
    {--metamethods

    },
    {--static public

    },
    {--private
        blocktags = {},
        close       = "",
        name        = "",
        nameplural  = "",
        open        = "",
    },
    {--protected

    },
    {--public
        doxblocktaggroup = function(this, cdat, sName, sNamePlural, sOpen, sClose, ...)
            type.assert.string(sName,        "%S+", "Dox block tag group name must not be blank.");
            type.assert.string(sNamePlural,  "%S+", "Dox block tag group plural name must not be blank.");
            type.assert.string(sOpen,        "%S+", "Dox block tag group open symbol(s) must not be blank.");
            type.assert.string(sClose,       "%S+", "Dox block tag group close symbol(s) must not be blank.");


            local pri = cdat.pri;
            pri.name           = sName;
            pri.nameplural     = sNamePlural
            pri.open           = sOpen;
            pri.close          = sClose;

            --a table to track all required tags
            local nRequiredTags         = #tRequiredGroupBlockTags;
            local tRequiredTagsFound    = -tRequiredGroupBlockTags;

            local tBlockTags = pri.blocktags;
            for _, oBlockTag in pairs({...} or args) do
                --TODO QUESTION should i check that this tag is set to bRequired in the input?
                for nIndex, sTag in tRequiredGroupBlockTags() do

                    if (not (tRequiredTagsFound[nIndex]) and oBlockTag.hasrequired(sTag) ) then
                        tRequiredTagsFound[nIndex] = true;
                    end

                end

                type.assert.custom(oBlockTag, "doxblocktag");
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
        blocktags = function(this, cdat)
            local tBlockTags    = cdat.pri.blocktags;
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
        getblockclose = function(this, cdat)
            return cdat.pri.close;
        end,
        getblockopen = function(this, cdat)
            return cdat.pri.open;
        end,
        getname = function(this, cdat)
            return cdat.pri.name;
        end,
    },
    nil, nil, true
);


--[[
███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗     ███████╗
████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔════╝
██╔████╔██║██║   ██║██║  ██║██║   ██║██║     █████╗
██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══╝
██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗███████╗
╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝]]
local doxmodule = class("doxmodule",
{--metamethods

},
{--static public

},
{--private
    moduleblocktaggroup = null,
    name = "",
},
{--protected

},
{--public
    doxmodule = function(this, cdat, sName, sBlock, oModuleBlockTagGroup)--sBlock
        type.assert.string(sName, "%S+");
        type.assert.custom(oModuleBlockTagGroup, "doxblocktaggroup");

        local pri = cdat.pri;

        pri.name = sName;
        pri.moduleblocktaggroup = oModuleBlockTagGroup;
    end,
    importblock = function(this, cdat)
        type.assert.string(sBlock, "%S+");
        --sBlock
    end,
},
nil,    --extending class
nil,    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
false   --if the class is final
);


--[[
██████╗  ██████╗ ██╗  ██╗
██╔══██╗██╔═══██╗╚██╗██╔╝
██║  ██║██║   ██║ ╚███╔╝
██║  ██║██║   ██║ ██╔██╗
██████╔╝╚██████╔╝██╔╝ ██╗
╚═════╝  ╚═════╝ ╚═╝  ╚═╝]]
return class("dox",
{--metamethods
    __tostring = function()
        --TODO this should display the open/close stuff +
    end,
},
{--static public
    MIME = enum("MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
},
{--private
    blocktaggroups      = {}, --this contains groups of block tags group objects
    moduleblocktaggroup = null,
    modules             = {}, --a list of module objects indexed by module names
    name                = "",
    snippetclose        = "", --QUESTION How will this work now that we're using mutiple tag groups?
    snippetopen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    --Start 	= "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	= "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagopen             = "",
    --toprocess           = {}, --this is a holding table for strings which need to be parsed for blocks
    extractblocks = function(this, cdat, sInput)
        local tModuleBlocks = null;
        local tBlocks       = {};
        local fTrim         = string.trim;

        local oModuleBlockTagGroup  = cdat.pri.moduleblocktaggroup;
        local fBlockTagGroups       = cdat.pub.blocktaggroups;

        -- Helper function to extract blocks from input based on open and close tags
        local function extractfencedblocks(sBlockTagGroupName, sInput, sOpen, sClose)
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
            local sModuleOpen   = oModuleBlockTagGroup.getblockopen();
            local sModuleClose  = oModuleBlockTagGroup.getblockclose();
            tModuleBlocks       = extractfencedblocks(oModuleBlockTagGroup:getname(), sInput, sModuleOpen, sModuleClose);

            -- Extract other blocks
            for oBlockTagGroup in fBlockTagGroups() do
                local sOpen         = oBlockTagGroup.getblockopen();
                local sClose        = oBlockTagGroup.getblockclose();
                local tGroupBlocks  = extractfencedblocks(oBlockTagGroup.getname(), sInput, sOpen, sClose);
                table.insert(tBlocks, tGroupBlocks);
            end

        return tModuleBlocks, tBlocks;
    end,
    parseblock = function(this, cdat, sBlock, bIsModule)

    end,
    processstring = function(this, cdat, sInput)
        local pri                   = cdat.pri;
        local oModuleBlockTagGroup  = pri.moduleblocktaggroup;

        --get all blocks from the string
        local tModuleBlocks, tBlocks = pri.extractblocks(sInput);

        --process each module block
        for sName, sBlock in pairs(tModuleBlocks) do

            --WTF LEFT OFF HERE ...need to get the name of the module
            --create the module (if it doesn't exist)
            if not (pri.modules[sName]) then
                pri.modules[sName] = doxmodule(sName, sBlock, oModuleBlockTagGroup);
            end

            --create the "Orphaned" module for items that name a non-existent module

            --local sOpen                 = oModuleBlockTagGroup:getopen();
            --local sClose                = oModuleBlockTagGroup:getclose();
        --    local oUnknownModule        = doxmodule("Orphaned");


            --process all other types of blocks and import them into modules
            for _, sBlock in pairs(tBlocks) do

            end

        end

    end,
},
{--protected
    blocktag        = doxblocktag,
    blocktaggroup   = doxblocktaggroup,
},
{--public
    dox = function(this, cdat, sName, sTagOpen, oModuleBlockTagGroup, ...)--TODO take moduleinfo, struct, enum and constant block tags too
        type.assert.string(sName,    "%S+", "Dox subclass name must not be blank.");
        type.assert.string(sTagOpen, "%S+", "Open tag symbol must not be blank.");
        type.assert.custom(oModuleBlockTagGroup, "doxblocktaggroup");

        local pri               = cdat.pri;
        pri.name                = sName;
        pri.tagopen             = sTagOpen;
        pri.moduleblocktaggroup = oModuleBlockTagGroup;


        --TODO put block tags in order of display (as input)!
        --TODO clone these properly
        local tBlockTagGroups = pri.blocktaggroups;

        for _, oBlockTagGroup in pairs({...} or args) do
            type.assert.custom(oBlockTagGroup, "doxblocktaggroup");
            tBlockTagGroups[#tBlockTagGroups + 1] = oBlockTagGroup.clone();
        end

    end,
    blocktaggroups = function(this, cdat)
        local tBlockTagGroups = cdat.pri.blocktaggroups;
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
    getmoduleclose = function(this, cdat)
        return cdat.pri.moduleclose;
    end,
    getmoduleopen = function(this, cdat)
        return cdat.pri.moduleopen;
    end,
    getname = function(this, cdat)
        return cdat.pri.name;
    end,
    gettagopen = function(this, cdat)
        return cdat.pri.tagopen;
    end,
    importdirectory = function(this, cdat, bRecurse)

    end,
    importfile = function(this, cdat)

    end,
    importstring = function(this, cdat, sInput)
        type.assert.string(sInput);
        --type.assert.string(sBlockTagGroupName);
        --local oBlockTagGroup = nil;

        --for oBTG in this.blocktaggroups() do

        --    if (oBTG.getname() == sBlockTagGroupName) then--TODO should htese be case sensitive?
        --        oBlockTagGroup = oBTG;
        --        break;
        --    end

        --end

        --assert( type(oBlockTagGroup) == "doxblocktaggroup",
        --        "Error importing string. Block Tag Group name, '${name}', does not exist." % {name = sBlockTagGroupName});

        --local pri = cdat.pri;
        --print(oBlockTagGroup.getblockopen(), oBlockTagGroup.getblockclose())
        --local tBlocks = extractblocks(sInput, oBlockTagGroup.getblockopen(), oBlockTagGroup.getblockclose());

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

    return cdat.pri.processstring(sInput);

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

        --local tModuleInfo = extractblocks(pri);
        --local tFunctionBlocks = extractblocks(sInput, pri.blco);

    end,
},
nil,    --extending class
nil,    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
false   --if the class is final
);
