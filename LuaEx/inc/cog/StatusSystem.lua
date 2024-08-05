local class = class;
local table = table;

local _tEffectsByOrdinal = {};

return class("StatusSystem",
{--METAMETHODS
},
{--STATIC PUBLIC
    StatusSystem = function(stapub)
        local tEffect = luaex.cog.config["StatusSystem"].EFFECT;

        --create the effect enum
        stapub.EFFECT = enum("StatusSystem.EFFECT", tEffect, nil, true);

        --store the ordinal references
        for nOrdinal, eEffect in stapub.EFFECT() do
            _tEffectsByOrdinal[nOrdinal] = eEffect;
        end

    end,
},
{--PRIVATE
    activeEffects           = {},
    activeEffectsByEnum     = {},
    effectCallbacks         = {},
    effects                 = {},
},
{},--PROTECTED
{--PUBLIC
    StatusSystem = function(this, cdat)
        local pri = cdat.pri;

        for nOrdinal, eEffect in StatusSystem.EFFECT() do
            pri.effects[eEffect] = {
                id          = nOrdinal,
                isImmune    = false,
                remaining   = Protean(0, 0, 0, 0, 0, 0, 0, 0, 9999),
                resistance  = Protean(0, 0, 0, 0, 0, 0, 0, 0, 100),
            };

            pri.activeEffectsByEnum[eEffect] = false;
        end

    end,
    adjustDuration = function(this, cdat, eEffect, nDuration)
        type.assert.custom(eEffect, "Status.EFFECT");
        type.assert.number(nDuration, true, false, false, true, false, 0);
        local tEffect = cdat.pri.effects[eEffect];

        tEffect.duration = tEffect + nDuration;
        return this;
    end,
    cycle = function(this, cdat)
        local pri = cdat.pri;

        --for

        local tEffect = cdat.pri.effects[eEffect];
--TODO
        tEffect.duration = tEffect + nDuration;
    end,
    getDuration = function(this, cdat, eEffect)
        type.assert.custom(eEffect, "Status.EFFECT");
        return cdat.pri.effects[eEffect].duration;
    end,
    isActive = function(this, cdat, eEffect)
        type.assert.custom(eEffect, "Status.EFFECT");
        return cdat.pri.activeEffects[eEffect] ~= nil;
    end,
    setDuration = function(this, cdat, eEffect, nDuration)
        type.assert.custom(eEffect, "Status.EFFECT");
        type.assert.number(nDuration, true, false, false, true, false, 0);
        local pri                   = cdat.pri;
        local tEffect               = pri.effects[eEffect];
        local tActiveEffects        = pri.activeEffects;
        local tActiveEffectsByEnum  = pri.activeEffectsByEnum;


        tEffect.duration        = nDuration;
        local bCurrentlyActive  = tEffect.isActive;
        local bIsActive         = (not tEffect.isImmune) and (tEffect.duration > 0);

        tEffect.isActive = bIsActive;

        if (bCurrentlyActive and not bIsActive) then --deactivate
            tActiveEffectsByEnum[eEffect] = false;

            for x = 1, #tActiveEffects do

                if (tActiveEffects[x] == eEffect) then
                    table.remove(tActiveEffects[x]);
                    table.sort(tActiveEffects);
                    break;
                end

            end

        elseif (not bCurrentlyActive and bIsActive) then --activate
            tActiveEffectsByEnum[eEffect] = true;
        end

        return this;
    end,
    setImmune = function(this, cdat, eEffect, bFlag)
        type.assert.custom(eEffect, "Status.EFFECT");
        bFlag = type(bFlag) == "boolean" and bFlag or false;
        local tEffect = cdat.pri.effects[eEffect];
        tEffect.isImmune = bFlag;

        return this;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
