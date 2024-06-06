local rawsetmetatable   = rawsetmetatable;
local string            = string;
local table             = table;
local type              = type;





return class("DoxBlockTagGroup",
{--metamethods
    __clone = function(this, cdat)
        local pri = cdat.pri;

        local tBlockTags = {};

        for _, oBlockTag in pairs(pri.blockTags) do
            table.insert(tBlockTags, clone(oBlockTag));
        end

        return DoxBlockTagGroup(pri.name, pri.namePlural, pri.isModule,
                                pri.language, pri.open, pri.close,
                                table.unpack(tBlockTags));
    end,
},
{--static public

},
{--private
    blockTags = {},
    close       = "",
    isModule    = false,
    language    = null,
    name        = "",
    namePlural  = "",
    open        = "",
},
{--protected

},
{--public
    DoxBlockTagGroup = function(this, cdat, sName, sNamePlural, bIsModule, eLanguage, sOpen, sClose, ...)
        type.assert.string(sName,         "%S+", "Dox block tag group name must not be blank.");
        type.assert.string(sNamePlural,   "%S+", "Dox block tag group plural name must not be blank.");
        cdat.pri.isModule = rawtype(bIsModule) == "boolean" and bIsModule or false;
        type.assert.custom(eLanguage,     "DoxLanguage");
        --type.assert.string(sCommentOpen, "%S+", "Dox block tag group comment open symbol(s) must not be blank.");
        --type.assert.string(sCommentClose,"%S+", "Dox block tag group comment close symbol(s) must not be blank.");
        type.assert.string(sOpen,         "%S+", "Dox block tag group open symbol(s) must not be blank.");
        type.assert.string(sClose,        "%S+", "Dox block tag group close symbol(s) must not be blank.");

        local pri = cdat.pri;
        pri.language       = eLanguage;
        pri.name           = sName;
        pri.namePlural     = sNamePlural
        --oDoxLanguage       = eLanguage.value;
        pri.open           = sOpen;
        pri.close          = sClose;
    --    print(pri.open, pri.close)
        --a table to track all required tags
        local nRequiredNames         = #Dox.RequiredNames;
        local tRequiredNamesFound    = -Dox.RequiredNames;

        local tBlockTags = pri.blockTags;
        for _, oBlockTag in pairs({...} or arg) do

            if (type(oBlockTag) ~= "DoxBlockTag") then
                error("Error creating DoxBlockTagGroup: "..sName..".\nType expected in var args: DoxBlockTag. Type given: "..type(oBlockTag).." - rawtype ("..rawtype(oBlockTag)..").");--.."\n"..serialize(oBlockTag));
            end

            for nIndex, sTag in Dox.RequiredNames() do

                if (not (tRequiredNamesFound[nIndex]) and oBlockTag.hasName(sTag) ) then
                    tRequiredNamesFound[nIndex] = true;
                end

            end

            type.assert.custom(oBlockTag, "DoxBlockTag");
            tBlockTags[#tBlockTags + 1] = oBlockTag.clone();
        end

        --check that every required tag has been created in the group
        for nIndex, bFound in pairs(tRequiredNamesFound) do

            if (not bFound) then
                error(  "Error creating Block Tag Group, '${taggroup}'.\nA '${tag}' tag is required (though its Display may be any string)." %
                        {taggroup = sName, tag = tRequiredNames[nIndex]});
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
    getBlockClose = function(this, cdat)
        return cdat.pri.close;
    end,
    getBlockOpen = function(this, cdat)
        return cdat.pri.open;
    end,
    getName = function(this, cdat)
        return cdat.pri.name;
    end,
    getNamePlural = function(this, cdat)
        return cdat.pri.namePlural;
    end,
    isModule = function(this, cdat)
        return cdat.pri.isModule;
    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
