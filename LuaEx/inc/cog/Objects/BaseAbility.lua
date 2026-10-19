--LOCALIZATION
local class   = class;
local Pool    = Pool;
local Protean = Protean;

local function dummy() end

--[[!
    @fqxn CoG.BaseAbility
    @pulsarlua class BaseAbility
    @desc Generic ability callbacks, enabled state, Protean use cost and
    regenerating points. Callers configure the exposed components directly.
    The implementing system defines callback arguments and cycle units.
!]]
return class("BaseAbility",
{--METAMETHODS
},
{--STATIC PUBLIC
},
{--PRIVATE
},
{--PROTECTED
    Enabled__auto__is                   = null,
    Cost__auto__                        = null,
    Points__autoAF                      = null,
    CheckActivationRequirements__auto__ = dummy,
    OnUse__auto__                       = dummy,
    OnSuccess__auto__                   = dummy,
    OnFail__auto__                      = dummy,
},
{--PUBLIC
    --[[!
        @fqxn CoG.BaseAbility.Methods.BaseAbility
        @pulsarlua function BaseAbility
        @desc Creates independent Protean and Pool components using their
        existing defaults. Callers configure them through getCost() and
        getPoints(). Omitted callbacks retain the shared dummy function.
        @param string sName Ability name.
        @param string sDescription Ability description.
        @param Rarity.LEVEL|nil eRarity Inherited rarity.
        @param string|nil wEventrix Inherited event environment.
        @param boolean bEnabled Initial enabled state.
        @param function|nil fCheckActivationRequirements Activation requirements callback.
        @param function|nil fOnUse Use callback.
        @param function|nil fOnSuccess Successful-use callback.
        @param function|nil fOnFail Failed-use callback.
    !]]
    BaseAbility = function(this, cdat, super,
                           sName, sDescription, eRarity, wEventrix, bEnabled,
                           fCheckActivationRequirements, fOnUse, fOnSuccess, fOnFail)
        type.assert.boolean(bEnabled);

        super(sName, sDescription, eRarity, wEventrix);

        local pro = cdat.pro;

        pro.Enabled = bEnabled;
        pro.Cost    = Protean();
        pro.Points  = Pool();

        if (fCheckActivationRequirements ~= nil) then
            pro.CheckActivationRequirements = fCheckActivationRequirements;
        end

        if (fOnUse ~= nil) then
            pro.OnUse = fOnUse;
        end

        if (fOnSuccess ~= nil) then
            pro.OnSuccess = fOnSuccess;
        end

        if (fOnFail ~= nil) then
            pro.OnFail = fOnFail;
        end
    end,

    --[[!
        @fqxn CoG.BaseAbility.Methods.use
        @pulsarlua function BaseAbility.use
        @desc Checks enabled state, activation requirements and available points.
        Callbacks receive this ability followed by the supplied arguments.
        Requirements and OnUse reject by returning false and an optional reason.
        Successful use deducts the calculated Protean cost before calling OnSuccess.
        Failed use calls OnFail with this ability, a reason and supplied arguments.
        Callback errors propagate; callbacks are not rollback transactions.
        The caller advances regeneration through getPoints().cycle().
        @param varargs ... Implementer-defined use context.
        @ret boolean bSuccess Whether use succeeded.
        @ret string|nil sReason Failure reason.
    !]]
    use = function(this, cdat, ...)
        local pro   = cdat.pro;
        local nCost = pro.Cost.getValue(Protean.VALUE_FINAL);

        assert(math.isfinite(nCost) and nCost >= 0,
            "Ability cost must be finite and nonnegative.");

        if (not pro.Enabled) then
            pro.OnFail(this, "Disabled", ...);
            return false, "Disabled";
        end

        local bAllowed, sReason = pro.CheckActivationRequirements(this, ...);

        if (bAllowed == false) then
            sReason = sReason or "Activation requirements not met";
            pro.OnFail(this, sReason, ...);
            return false, sReason;
        end

        if (pro.Points.get() < nCost) then
            pro.OnFail(this, "Insufficient points", ...);
            return false, "Insufficient points";
        end

        local bSuccess, sFailure = pro.OnUse(this, ...);

        if (bSuccess == false) then
            sFailure = sFailure or "Use failed";
            pro.OnFail(this, sFailure, ...);
            return false, sFailure;
        end

        pro.Points.adjust(-nCost);
        pro.OnSuccess(this, ...);

        return true;
    end,
},
BaseObject,
false,
nil
);

--[[!
    @fqxn CoG.BaseAbility.InheritedBaseObject
    @inheritdoc CoG.BaseObject
!]]
