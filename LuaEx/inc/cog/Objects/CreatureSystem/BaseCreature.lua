--LOCALIZATION
local class = class;

--[[!
    @fqxn CoG.CreatureSystem.BaseCreature
    @desc Generic BaseObject subclass owning independent XP, HP, inventory, equipment,
    status and targeting components. Components are created in the constructor and
    exposed through final getters without replacement setters. Their own APIs remain
    mutable. XPSystem owns level calculation; subclasses define gameplay behavior.
    No species, faction, age, mana, stamina, damage, death or resource-cycling policy
    is imposed. Required XP/HP values and a configured status category come from the caller.
!]]
return class("BaseCreature",
{--METAMETHODS
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.__clone
        @desc Requires concrete subclasses to define copying of creature state,
        component ownership, inherited metadata and runtime callbacks.
        @throws Always unless a subclass supplies its own __clone.
    !]]
    __clone = function()
        error("BaseCreature subclasses must define __clone for their creature state.");
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
},
{--PROTECTED
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.getXP
        @pulsarlua function BaseCreature.getXP
        @desc Final getter for this creature's mutable experience/level component. No replacement setter.
        @ret XPSystem oXP The owned tracker; initially level zero with zero XP.
    !]]
    XP__autoAF            = null,
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.getHP
        @pulsarlua function BaseCreature.getHP
        @desc Final getter for this creature's mutable HP Pool. No replacement setter or death rule.
        @ret Pool oHP The owned Pool.
    !]]
    HP__autoAF            = null,
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.getInventory
        @pulsarlua function BaseCreature.getInventory
        @desc Final getter for an initially empty, unlimited inventory owned by this creature. No replacement setter.
        @ret ItemSystem oInventory The owned inventory.
    !]]
    Inventory__autoAF     = null,
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.getEquipment
        @pulsarlua function BaseCreature.getEquipment
        @desc Final getter for an initially empty slot system owned by this creature. Subclasses/callers add slots. No replacement setter.
        @ret ItemSlotSystem oEquipment The owned equipment system.
    !]]
    Equipment__autoAF     = null,
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.getStatusTracker
        @pulsarlua function BaseCreature.getStatusTracker
        @desc Final getter for the creature's configured-scope status tracker. No replacement setter.
        @ret StatusTracker oStatuses Independent initially inactive status storage.
    !]]
    StatusTracker__autoAF = null,
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.getTargetor
        @pulsarlua function BaseCreature.getTargetor
        @desc Final getter for the creature's initially empty targeting component. No replacement setter.
        @ret Targetor oTargetor Independent mutable targeting categories.
    !]]
    Targetor__autoAF      = null,
},
{--PUBLIC
    --[[!
        @fqxn CoG.CreatureSystem.BaseCreature.Methods.BaseCreature
        @pulsarlua function BaseCreature
        @desc Initializes inherited metadata and constructs fresh components using existing system APIs.
        The options table supplies configuration, never replacement component instances.
        <ul>
        <li>XP: table containing Type, LevelOneXP, MaxLevel and Progression, all required by XPSystem. Optional StepSize uses XPSystem's default of 2.</li>
        <li>HP: table containing explicit numeric Max and Current, validated/clamped by Pool.</li>
        <li>StatusScope: actual configured StatusTracker category enum. No default category is invented; subclasses supply their own scope.</li>
        </ul>
        Inventory and equipment use their existing empty defaults and associate this creature as owner.
        @param string sName Nonblank name passed to BaseObject.
        @param string sDescription Nonblank description passed to BaseObject.
        @param Rarity.LEVEL|nil eRarity Rarity passed to BaseObject.
        @param string|nil wEventrix Registered event environment name passed to BaseObject.
        @param table tOptions Required XP, HP and StatusScope configuration described above.
        @throws Missing/invalid options, a nonconfigured status scope, or an inherited/component constructor error.
    !]]
    BaseCreature = function(this, cdat, super, sName, sDescription, eRarity, wEventrix, tOptions)
        type.assert.table(tOptions);
        type.assert.table(tOptions.XP);
        type.assert.table(tOptions.HP);
        type.assert.number(tOptions.HP.Max);
        type.assert.number(tOptions.HP.Current);

        super(sName, sDescription, eRarity, wEventrix);

        local pro = cdat.pro;
        local tXP = tOptions.XP;
        local tHP = tOptions.HP;

        pro.XP            = XPSystem(tXP.Type, tXP.LevelOneXP, tXP.MaxLevel, tXP.Progression, tXP.StepSize);
        pro.HP            = Pool(tHP.Max, tHP.Current);
        pro.Inventory     = ItemSystem(nil, nil, this);
        pro.Equipment     = ItemSlotSystem(nil, this);
        pro.StatusTracker = StatusTracker(tOptions.StatusScope);
        pro.Targetor      = Targetor();
    end,

},
BaseObject,
false,
nil
);

--[[!
    @fqxn CoG.CreatureSystem.BaseCreature.InheritedBaseObject
    @inheritdoc CoG.BaseObject
!]]
