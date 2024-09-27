--[[
Brainstorming

an affix (equipment):
Applies to Rings, Boots, Belts and Armour
Grants +20% to Max Life.
Needs the life pool as input.
]]
--TODO WARNING FINISH need to do implicit/explicit mods on items
local _tCoGConfig       = luaex.cog.config;
local _eMaxTier         = _tCoGConfig.Rarity.Affix.maxTier;
local _sDefaultSortTag  = "ZZZ UNSORTED";

local class         = class;
local envrepo       = envrepo;
local pairs         = pairs;
local type          = type;
local AffixSystem   = AffixSystem;

local _eType = enum("Affix.TYPE", {"PREFIX", "SUFFIX"}, nil, true);

local function placeholder() end

return class("Affix",
{--METAMETHODS
},
{--STATIC PUBLIC
    Affix = function(stapub)
        stapub.MAX_TIER = _eMaxTier;
    end,
    --[[!
    @fqxn CoG.Affix.Enums.TYPE
    @desc Used for setting an <a href="#CoG.Affix.Methods.Affix">Affix's</a> type.
    <hr>
    <ul>
        <li><b>PREFIX</b></li>
        <li><b>SUFFIX</b></li>
    </ul>
    !]]
    TYPE = _eType,
},
{--PRIVATE
    appliesTo           = {},
    activator__RO       = null,
    deactivator__RO     = null,
    Environment__autoRA = null,
    --environment     = null,
    --[[!
    @fqxn CoG.Affix.Fields.journal
    @desc A table to be used as a journal of changes the affix makes for use in undoing them upon removeal. It is used by the activator and deactivator functions. It's a way of preserving affix data created in these functions across sessions.
    @vis Private
    !]]
    journal = {},
    --[[!
    @fqxn CoG.Affix.Fields.sortTags
    @desc A TagSystem that used to properly sort the affixes for display purposes.
    @vis Private
    !]]
    sortTags__RO = null,
    --[[!
    @fqxn CoG.Affix.Methods.getTier
    @desc Gets the <a href="#CoG.Enums.TIER">TIER</a> of the affix.
    @ret TIER eTier The <b>TIER</b> of the affix.
    !]]
    Tier__autoR_ = null,
    --[[!
    @fqxn CoG.Affix.Methods.getType
    @desc Gets the <a href="#CoG.Affix.Enums.TYPE">TYPE</a> of affix this is.
    @ret Affix.TYPE eType The <b>TYPE</b> of the affix.
    !]]
    Type__autoR_ = null,
},
{--PROTECTED
    --[[!
    @fqxn CoG.Affix.Methods.getName
    @desc Gets the name of the affix.
    @ret string sName The name of the affix.
    !]]
    Name__autoRA        = null,
    --[[!
    @fqxn CoG.Affix.Methods.getDescription
    @desc Gets the description of the affix.
    @ret string sDescription The description of the affix.
    !]]
    --[[!
    @fqxn CoG.Affix.Methods.Affix
    @desc The constructor for the Affix class.
    @vis Protected
    @param Affix.TYPE eType The type of the affix <em>(either <a href="#CoG.Affix.Enums.TYPE.PREFIX">PREFIX</a> or <a href=".Affix.Enums.TYPE.SUFFIX">SUFFIX</a>)</em>.
    @param string sName The name of the affix. It should be a unique name among other affixes.
    @param string sDescription The description of the affix. It should explain precisely what the affix does.
    @param TIER eTier The <a href="#CoG.Enums.TIER">TIER</a> of the affix.
    @param table tAppliesTo The classes with which the affix is compatible. It must be a numerically-indexed table whose values are classes and there must be at least one entry.
    @param function fActivator The activator function that is fired when the Affix is applied by the owner object. The activator function must accept the following parameters.
        <ol>
            <li>The object upon which the Affix is applied (a descendant of the BaseObject).</li>
            <li>Any other arguments you want passed to the activator function by the object's call to its ApplyAffix method. Essentially, the object's ApplyAffix method's varargs are sent directly to the Affix's onApply method that, in turn, inputs them in this activator function allowing you to pass whatever data you want to the activator during application of the Affix.</li>
        </ol>
        If a return is provided by the activator function, it must be a table whose keys are enumitems and values are numerically-indexed tables with event hook function values. This tables is used by the calling object to add events to the object's eventrix during application of the Affix.
    TODO FINISH OTHER PARAMS
    <br><strong>Note</strong>: the handler of the item/monster/etc. that hosts the affix is responsible for calling this function and determining when it should be called.
    !]]
    Affix = function(   this, cdat, eType, sName, eTier,
                        tAppliesTo, fActivator, fDeactivator, tSortTags, sEnv)
        local pri = cdat.pri;
        local pro = cdat.pro;

        type.assert.custom(eType, "Affix.TYPE");
        type.assert.string(sName, "%S+");
        type.assert.custom(eTier, "TIER");
        type.assert["function"](fActivator);
        type.assert["function"](fDeactivator);

        if (eTier > _eMaxTier) then
            error("Error creating Affix.\nMax TIER is "..tostring(eMaxTier)..'. TIER given: '..tostring(eTier)..'.');
        end

        pri.Tier            = eTier;
        pri.Type            = eType;
        pri.activator       = fActivator;
        pri.deactivator     = fDeactivator;

        --set the env in which the activator/deactivator functions will fire
        local wEnv          = envrepo[sEnv];
        pri.Environment     = sEnv and sEnv or envrepo.getDefaultName();

        pro.sortTags        = TagSystem();

        local tMyAppliesTo  = pri.appliesTo;

        --TODO assert tAppliesTo
        for _, cTypeAppliesTo in pairs(tAppliesTo) do
            tMyAppliesTo[cTypeAppliesTo] = true;
        end

        local oSortTags     = pro.sortTags;
        if (type(tSortTags) == "table") then

            for k, v in pairs(tSortTags) do

                if (type(v) == "string") then
                    oSortTags.add(v);
                end

            end

        else
            oSortTags.add(_sDefaultSortTag);
        end

    end,
},
{--PUBLIC
    --[[!
    @fqxn CoG.Affix.Methods.eachCompatibleClass
    @desc An iterator that iterates over each class with which this affix is compatible.
    @ret function fIterator The iterator function.
    !]]
    eachCompatibleClass__FNL = function()
        return next, cdat.pri.appliesTo, nil;
    end,
    --[[!
    @fqxn CoG.Affix.Methods.isCompatibleWithClass
    @desc Determines whether this affix can be used with a given class.
    @param class cType The class to check.
    @ret boolean bIsCompatible True if compatible, false otherwise.
    !]]
    isCompatibleWithClass__FNL = function(this, cdat, cType)
        local bRet = class.is(cType);

        if (bRet) then

            for cMyType, _ in pairs(cdat.pri.appliesTo) do

                if (class.ischildorself(cMyType, cType)) then
                    bRet = true;
                    break;
                end

            end

        end

        return bRet;
    end,
    --[[!
    @fqxn CoG.Affix.Methods.isPrefix
    @desc Determines whether this affix is a prefix.
    @ret boolean bIsPrefix True if it's a prefix, false otherwise.
    !]]
    isPrefix__FNL = function(this, cdat)
        return cdat.pri.Type == _eType.PREFIX;
    end,
    --[[!
    @fqxn CoG.Affix.Methods.isSuffix
    @desc Determines whether this affix is a suffix.
    @ret boolean bIsSuffix True if it's a suffix, false otherwise.
    !]]
    isSuffix__FNL = function(this, cdat)
        return cdat.pri.Type == _eType.SUFFIX;
    end,
    --[[!
    @fqxn CoG.Affix.Methods.onApply
    @desc Fires the activator function provided during construction. This is called by the object to which the affix is applied. This is basically a controlled wrapper for the activator function to prevent erroneous or multiple calls and to restrict the environment in which the function is called.
    @param object oObject The object (a descendant of the BaseObject) that upon which the affix is applied.
    @param varargs varargs Any arguments that should be passed to the activator function from the object's <a href="#CoG.BaseObject.Methods.ApplyAffix">ApplyAffix</a> method.
    @ret boolean bApplied True if the affix was applied, false otherwise.
    !]]
    --must accept object which contains it (and any varargs), may return any events and functions
    onApply__FNL = function(this, cdat, oCoGObject, ...)
        local pri = cdat.pri;
        local wOldEnv = _ENV;
        _ENV = envrepo[pri.Environment];
        local vCallResult = pri.activator(oCoGObject, pri.journal, ...);
        _ENV = wOldEnv;
        return vCallResult;
    end,
    --[[!
    @fqxn CoG.Affix.Methods.onRemove
    @desc Fires the deactivator function provided during construction. This is called by the object from which the affix is removed. This is basically a controlled wrapper for the deactivator function to prevent erroneous or multiple calls and to restrict the environment in which the function is called.
    @param object oObject The object (a descendant of the BaseObject) that upon which the affix is applied.
    @param varargs varargs Any arguments that should be passed to the deactivator function.
    !]]
    onRemove__FNL = function(this, cdat, oCoGObject, ...)
        local pri = cdat.pri;
        local wOldEnv = _ENV;
        _ENV = envrepo[pri.Environment];
        pri.deactivator(oCoGObject, pri.journal, ...);
        _ENV = wOldEnv;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
