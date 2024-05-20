--[[TODO
    Use MD for text
    Allow internal anchor links
    Allow external links
]]

local assert    = assert;
local class     = class;
local rawtype   = rawtype;
local table     = table;
local type      = type;


local function extractblocksOLD(sInput, sOpen, sClose)
    local tRet = {};
    local nStart, nEnd = 1, 1;

    --loop through the string
    while (nStart and nEnd) do
        --find the next occurrence of the open tag
        nStart = str:find(sOpen, nEnd, true);

        if not (nStart) then --break if not found
            break;
        end

        nEnd = str:find(sClose, nStart + #sOpen, true);

        if not (nEnd) then--break if not found
            break;
        end

        --extract the substring between the open and close tags
        local sExtracted = str:sub(nStart + #sOpen, nEnd - 1)
        --add the sExtracted substring to the tRet table
        table.insert(tRet, sExtracted);
    end

    return tRet;
end

local function escapePattern(pattern)
    return pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

local function extractblocks(sInput, sOpen, sClose)
    local tRet = {}

    -- Escape patterns to handle special characters
    local escapedOpen = escapePattern(sOpen)
    local escapedClose = escapePattern(sClose)

    -- Use escaped patterns to find matches
    for sMatch in sInput:gmatch(escapedOpen .. "(.-)" .. escapedClose) do
        table.insert(tRet, sMatch)
    end

    return tRet
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
            --TODO type checking/validating
            cdat.pri.display         = sDisplay;
            cdat.pri.items           = nItems;
            cdat.pri.multipleallowed = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;
            cdat.pri.required        = type(bMultipleAllowed) == "boolean" and bMultipleAllowed or false;

            for _, sName in pairs(tNames) do
                cdat.pri.names[#cdat.pri.names + 1] = sName;
            end

        end,
        ismultipleallowed = function(this, cdat)
            return cdat.pri.multipleallowed;
        end,
        clone = function(this, cdat) --OMG TODO
            return this;
        end,
        getdisplay = function(this, cdat)
            return cdat.pri.display;
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
            type.check.string(sName,        "%S+");
            type.check.string(sNamePlural,  "%S+");
            type.check.string(sOpen,        "%S+");
            type.check.string(sClose,       "%S+");


            local pri = cdat.pri;
            pri.name           = sName;
            pri.nameplural     = sNamePlural
            pri.open           = sOpen;
            pri.close          = sClose;

            --TODO auto-insret @mod/@module tags--these are required!Also, delete the user-input of these tags (if any exist)
            local tBlockTags = pri.blocktags;
            for _, oBlockTag in pairs({...} or args) do
                type.check.custom(oBlockTag, "doxblocktag");
                tBlockTags[#tBlockTags + 1] = oBlockTag.clone();
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

},
{--protected

},
{--public
    doxmodule = function(this, cdat)

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
    groupindexbyname  = {}, --this contains groups of block tags group objects
    modules             = {}, -- a list of module objects
    moduleclose         = "",
    moduleopen          = "",
    name                = "",
    snippetclose        = "", --QUESTION How will this work now that we're using mutiple tag groups?
    snippetopen         = "", --TODO add snippet info DO NOT ALLOW USER TO SET/GET THIS
    --Start 	= "##### START DOX [SUBCLASS NAME] SNIPPETS -->>> ID: ",
    --End 	= "#####   <<<-- END DOX [SUBCLASS NAME] SNIPPETS ID: ",
    tagopen             = "",
    toprocess           = {}, --this is a holding table for string which need to be parsed for blocks
    importblocktag      = function(this, cdat)

    end,
    extractmoduletext = function(this, cdat, sInput)

    end,
},
{--protected
    blocktag        = doxblocktag,
    blocktaggroup   = doxblocktaggroup,
},
{--public
    dox = function(this, cdat, sName, sTagOpen, oModuleBlockTagGroup, ...)--TODO take moduleinfo, struct, enum and constant block tags too
        type.check.string(sName,    "%S+");
        type.check.string(sTagOpen, "%S+");
        type.check.custom(oModuleBlockTagGroup, "doxblocktaggroup");

        local pri   = cdat.pri;
        pri.name    = sName;
        pri.tagopen = sTagOpen;

        --TODO put block tags in order of display (as input)!
        --TODO clone these properly
        local tBlockTagGroups = pri.blocktaggroups;

        for _, oBlockTagGroup in pairs({...} or args) do
            type.check.custom(oBlockTagGroup, "doxblocktaggroup");
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
    importstring = function(this, cdat, sBlockTagGroupName, sInput)
        type.check.string(sInput);
        type.check.string(sBlockTagGroupName);
        local oBlockTagGroup = nil;

        for oBTG in this.blocktaggroups() do

            if (oBTG.getname() == sBlockTagGroupName) then--TODO should htese be case sensitive?
                oBlockTagGroup = oBTG;
                break;
            end

        end

        assert( type(oBlockTagGroup) == "doxblocktaggroup",
                "Error importing string. Block Tag Group name, '${name}', does not exist." % {name = sBlockTagGroupName});

        local pri = cdat.pri;
        print(oBlockTagGroup.getblockopen(), oBlockTagGroup.getblockclose())
        local tBlocks = extractblocks(sInput, oBlockTagGroup.getblockopen(), oBlockTagGroup.getblockclose());


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

    return result
end






        for k, v in pairs(tBlocks) do
            local tTags = parseText(v);

            for kk, vv in pairs(tTags) do


                for kkk, vvv in pairs(vv) do
                    print(kkk, vvv)
                end

            end

        end




        --local tModuleInfo = extractblocks(pri);
        --local tFunctionBlocks = extractblocks(sInput, pri.blco);

    end,
},
nil,    --extending class
nil,    --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
false   --if the class is final
);
