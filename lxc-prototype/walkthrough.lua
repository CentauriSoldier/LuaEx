--[[!
@fqxn LXC.Walkthrough
@desc Guided, executable introduction to LXC. Read the declarations alongside
    the labeled output. Expected denials are caught; unexpected results fail.
    All source and saved data stay in memory. No project files are changed.
!]]
local _pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local _pRoot = _pSource:match('^(.*)/[^/]+$') or '.';
local LXC = assert(loadfile(_pRoot..'/lxc.lua'))();
local _tConstruction = {};
local _nChecks = 0;
local _tEnvironment = setmetatable({
    construction = function(sStage) _tConstruction[#_tConstruction + 1] = sStage; end,
}, {__index = _G});

--[[!
@fqxn LXC.Walkthrough.section
@desc Introduces one concept before demonstrating it.
!]]
local function section(sTitle, sExplanation)
    print('\n'..sTitle);
    print(sExplanation);
end

--[[!
@fqxn LXC.Walkthrough.show
@desc Prints a checked result with its expected value.
!]]
local function show(sLabel, vActual, vExpected)
    assert(rawequal(vActual, vExpected), sLabel..': unexpected result '..tostring(vActual));
    _nChecks = _nChecks + 1;
    print('  OK: '..sLabel..' = '..tostring(vActual)..' (expected '..tostring(vExpected)..')');
end

--[[!
@fqxn LXC.Walkthrough.denied
@desc An expected error is a successful demonstration, not a failed run.
!]]
local function denied(sLabel, fOperation)
    local bOK = pcall(fOperation);
    assert(not bOK, sLabel..': operation unexpectedly succeeded.');
    _nChecks = _nChecks + 1;
    print('  DENIED as expected: '..sLabel);
end

-- LXC declarations use braces; their method bodies are ordinary Lua. Instance
-- methods are bound dot calls: hero.describe(), not hero:describe().
LXC.loadSources({['walkthrough.lxc'] = [[
namespace TutorialConfig {
    class Settings { public static startingEnergy = 20; }
}
namespace Tutorial {
    using TutorialConfig;

    class Entity requires(TutorialConfig.Settings) {
        private name = "Unnamed";
        protected energy = 10;
        public points = 0;
        public friend = null;
        public data = {};
        public final id = null;
        public const settings = {active = true};
        public static created = 0;
        private static ready = false;

        -- Static state is initialized once, before instances are constructed.
        static Entity() { Entity.ready = true; }

        -- Automatic getter, custom protected setter, and generated readHealth().
        public Health {
            get("read");
            protected set { field = math.max(0, value); }
        } = 100;

        public Entity(nID, sName) {
            this.id = nID;
            this.name = sName;
            Entity.created = Entity.created + 1;
            construction("Entity");
        }

        public describe() { return this.name; }
        public final getName() { return this.name; }
        public sameName(other) { return this.name == other.name; }
        public readPeerEnergy(other) { return other.energy; }
        public healTo(n) { this.Health = n; }
        public callback(fWork) { return fWork(this); }
        public privateClosure() { return function() return this.name; end; }
        public static isReady() { return Entity.ready; }
        public operator ==(other) {
            return class.isa(other, Entity) and this.id == other.id;
        }

        private class Tag {
            public Tag() {}
            public ownerName(other) { return other.name; }
        }
        public makeTag() { return Tag(); }
    }

    class Hero : Entity {
        -- Constructors do not override. The parent call must come first.
        public Hero(nID, sName) {
            base(nID, sName);
            this.energy = Settings.startingEnergy;
            construction("Hero");
        }

        public override describe() { return base.describe().." / energy "..this.energy; }
        public readHeroEnergy(other) { return other.energy; }
        public train(n) { this.energy = this.energy + n; }

        -- Override behavior, retain one original backing slot and accessor names.
        public override Health {
            get("read") { return field; }
            protected set { field = math.min(150, math.max(0, value)); }
        }
        public baseHealth() { return base.Health; }
        public operator +(other) { return this.energy + other.energy; }
    }
    class Guard : Entity { public Guard(nID, sName) { base(nID, sName); } }

    class Inventory {
        private items = {"Map", "Torch"};
        public operator pairs() {
            return function(_, key) return next(this.items, key); end, nil, nil;
        }
    }

    abstract class Action { public abstract run(); }
    final class Wave : Action { public override run() { return "wave"; } }
}
]]}, _tEnvironment);

local A = _tEnvironment.Tutorial;
print('LXC GUIDED WALKTHROUGH - '.._VERSION);
print('OK lines verify results. DENIED lines demonstrate intentional access errors.');

section('1. Construction, inheritance and method overrides',
    'Hero chains to Entity with base(...), then runs its own constructor.');
local oHero = A.Hero(1, 'Ada');
show('constructor order', table.concat(_tConstruction, ' -> '), 'Entity -> Hero');
show('overridden describe uses base.describe', oHero.describe(), 'Ada / energy 20');
show('inherited final method', oHero.getName(), 'Ada');
show('exact concrete class', LXC.class.getname(oHero), 'Tutorial.Hero');
show('hero is also an Entity', LXC.class.isa(oHero, A.Entity), true);

section('2. Private and protected access',
    'Rights belong to the declaring class, including access to another instance.');
local oPeer = A.Hero(2, 'Ada');
local oEntity = A.Entity(3, 'Base');
local oGuard = A.Guard(4, 'Guard');
show('same-class private cross-instance read', oHero.sameName(oPeer), true);
show('derived protected read on another Hero', oHero.readHeroEnergy(oPeer), 20);
show('base-declared method can read a Guard', oHero.readPeerEnergy(oGuard), 10);
denied('external private field read', function() return oHero.name; end);
denied('external protected field read', function() return oHero.energy; end);
denied('Hero protected access through a base receiver', function() return oHero.readHeroEnergy(oEntity); end);
denied('Hero protected access through a sibling receiver', function() return oHero.readHeroEnergy(oGuard); end);
show('nested private Tag can read enclosing Entity state', oHero.makeTag().ownerName(oHero), 'Ada');
denied('external lookup of the private nested class', function() return A.Entity.Tag; end);
denied('external callback borrowing class rights', function()
    return oHero.callback(function(other) return other.name; end);
end);
show('authored closure retains its declaring rights', oHero.privateClosure()(), 'Ada');

section('3. Properties, typed fields, const and final',
    'Direct property access and named accessors use the same backing slot.');
oHero.healTo(200);
show('overridden setter clamps health', oHero.Health, 150);
show('generated readHealth accessor', oHero.readHealth(), 150);
show('base view sees the same slot', oHero.baseHealth(), 150);
denied('external write through protected setter', function() oHero.Health = 5; end);
denied('change the established points type', function() oHero.points = 'wrong'; end);
denied('reassign initialized final id', function() oHero.id = 99; end);
denied('rebind const settings', function() oHero.settings = {}; end);
oHero.settings.active = false;
show('const table contents remain mutable', oHero.settings.active, false);
show('other instances own independent default tables', oPeer.settings.active, true);

section('4. Static state, imports and operators',
    'Class qualifiers access shared statics; == compares IDs here, not identity.');
show('static constructor ran', A.Entity.isReady(), true);
show('four parent constructor calls', A.Entity.created, 4);
show('inherited static storage is shared', A.Hero.created, 4);
show('using/requires supplied starting energy', oHero.readHeroEnergy(oPeer), 20);
show('custom addition of two Heroes', oHero + oPeer, 40);
local oSameID = A.Hero(1, 'Different name');
show('separate objects with equal IDs', oHero == oSameID, true);
show('equal values still have distinct identities', rawequal(oHero, oSameID), false);
show('different IDs compare unequal', oHero ~= oPeer, true);
show('Lua does not call table equality against a number', oHero == 1, false);

section('5. Custom iteration and abstract/final classes',
    'The authored iterator reads private items; it returns only the chosen values.');
local tItems = {};
for nIndex, sItem in pairs(A.Inventory()) do
    print('  ITEM '..nIndex..': '..sItem);
    tItems[nIndex] = sItem;
end
show('iterator result', table.concat(tItems, ', '), 'Map, Torch');
denied('instantiate an abstract class', function() return A.Action(); end);
show('concrete implementation of abstract method', A.Wave().run(), 'wave');
denied('derive from a final class', function()
    LXC.loadSources({['invalid-wave.lxc'] = 'namespace Tutorial { class MoreWave : Wave {} }'}, _tEnvironment);
end);

section('6. Clone and save/load graphs',
    'The host deliberately owns the codec. Saved state includes hidden fields.');
oHero.friend, oPeer.friend = oPeer, oHero;
oHero.data.shared = {'shared value'};
oPeer.data.shared = oHero.data.shared;
local tGraph = {oHero, oHero, oPeer};
local nBefore = A.Entity.created;
local tCopy = LXC.clone(tGraph);
local sSave = LXC.serialize(tGraph);
local tRestored = LXC.deserialize(sSave);
show('clone preserves repeated-object aliases', rawequal(tCopy[1], tCopy[2]), true);
show('clone reconnects the mutual cycle', rawequal(tCopy[1].friend.friend, tCopy[1]), true);
show('clone preserves shared nested tables', rawequal(tCopy[1].data.shared, tCopy[3].data.shared), true);
show('clone creates distinct identities', rawequal(tCopy[1], oHero), false);
tCopy[1].data.shared[1] = 'copy only';
show('clone mutable state is independent', oHero.data.shared[1], 'shared value');
show('restored private state drives behavior', tRestored[1].describe(), 'Ada / energy 20');
show('restore reconnects graph aliases', rawequal(tRestored[1], tRestored[2]), true);
show('restore reconnects the cycle', rawequal(tRestored[1].friend.friend, tRestored[1]), true);
show('clone/restore do not rerun constructors', A.Entity.created, nBefore);
denied('malformed saved input', function() return LXC.deserialize('this is not a snapshot'); end);

section('7. Table decoys and raw writes',
    'Raw entries can shadow public lookup; they do not replace hidden backing slots.');
local fGetName = oHero.getName;
rawset(oHero, 'name', 'raw shadow');
show('raw entry is visible on the decoy', oHero.name, 'raw shadow');
show('checked method still reads hidden name', fGetName(), 'Ada');
rawset(oHero, 'name', nil);
denied('removing the shadow restores private denial', function() return oHero.name; end);

print('\nWALKTHROUGH PASSED: '.._nChecks..' checked outcomes.');
print('No files were saved. The serialized graph above existed only in memory.');
