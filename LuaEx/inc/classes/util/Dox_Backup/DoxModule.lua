return class("DoxModule",
{--metamethods

},
{--static public

},
{--private
    moduleBlockTagGroup = null,
    name = "",
    parseBlock = function(this, cdat, tBlock, bIsModule)
        local pri                   = cdat.pri;
        local oModules              = pri.modules;
        local oModuleBlockTagGroup  = pri.moduleBlockTagGroup;
        local fBlockTagGroups       = cdat.pub.blockTagGroups;

        if (bIsModule) then

        else
            --TODO LEFT OFF HERE ...
            for oBlockTagGroup in fBlockTagGroups() do
                print(serialize(tBlock));
            end

        end

    end,
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
    importBlock = function(this, cdat, sBlock)
        type.assert.string(sBlock, "%S+");
        --sBlock--TODO HERE
    end,
},
nil,   --extending class
true,  --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
