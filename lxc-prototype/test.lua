--[[!
@fqxn LXC.Tests
@desc Standalone regression runner. Runs source/access/persistence/loading suites
    plus the shipped examples. No native filesystem writes or GUI are involved.
!]]
local pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local pRoot = pSource:match('^(.*)/[^/]+$') or '.';
local vThreadMeta = getmetatable(coroutine.running());
local LXC = assert(loadfile(pRoot..'/lxc.lua'))();
local nChecks = 0;

for _, sSuite in ipairs({'contracts', 'persistence', 'loading', 'context', 'acceptance', 'language', 'operators', 'equality', 'stress', 'adversarial'}) do
    local nPassed = assert(loadfile(pRoot..'/tests/'..sSuite..'.lua'))()(LXC);
    print('PASS '..sSuite..': '..nPassed..' checks.');
    nChecks = nChecks + nPassed;
end

local tEnvironment = setmetatable({}, {__index = _G});
local tOrder = LXC.loadFiles({pRoot..'/examples/01_Player.lxc', pRoot..'/examples/02_Creature.lxc'}, tEnvironment);
assert(tOrder[1] == 'Demo.Characters.Creature');
local oPlayer = tEnvironment.Demo.Characters.Player('James');
assert(oPlayer.describe() == 'James: 100' and oPlayer.getItemCount() == 2);
assert(oPlayer.getLiteral() == '} { } ');
nChecks = nChecks + 3;
print('PASS examples: 3 checks.');

-- Independent registries share only opaque dispatch infrastructure in this state.
local vPreviousAPI, vPreviousObject = _G.LxcCapturedAPI, _G.LxcCapturedObject;
_G.LxcCapturedAPI, _G.LxcCapturedObject = LXC, LXC.class.getbyname('Equality.Graph')();
local OtherLXC = assert(loadfile(pRoot..'/lxc.lua'))();
_G.LxcCapturedAPI, _G.LxcCapturedObject = vPreviousAPI, vPreviousObject;
assert(OtherLXC.class.getbyname('Acceptance.Holder') == nil);
assert(LXC.class.getbyname('Acceptance.Holder')().read() == 8);
local tOtherEnvironment = {};
OtherLXC.loadSources({['other.lxc'] = [[namespace Other {
    class Item {
        private value=3;
        public read() { return this.value; }
        public operator ==(other) { return this.value==other.read(); }
    }
    class Restricted { public operator ==(other) { return other.value==3; } }
}]]}, tOtherEnvironment);
assert(tOtherEnvironment.Other.Item().read() == 3);
assert(not pcall(OtherLXC.serialize, oPlayer));
local oOther = tOtherEnvironment.Other.Item();
local oValue = LXC.class.getbyname('Equality.Value')(3);
assert(oOther==oValue and oValue~=oOther, 'Mixed runtimes must preserve left-operand selection.');
assert(not pcall(function() return tOtherEnvironment.Other.Restricted()==oValue; end), 'Foreign runtime must not acquire private rights.');
assert(not pcall(LXC.serialize,oOther) and not pcall(LXC.clone,oOther), 'Foreign decoys must not enter generic table traversal.');
assert(rawequal(getmetatable(coroutine.running()),vThreadMeta), 'Facade allocation must not alter foreign thread metatables.');
nChecks = nChecks + 8;
print('PASS runtime isolation: 8 checks.');
local oPrevious;
for nRuntime=1,8 do
    local CurrentLXC=assert(loadfile(pRoot..'/lxc.lua'))();
    local tCurrent=setmetatable({}, {__index=_G});
    CurrentLXC.loadSources({['runtime-stress.lxc']=[[namespace RuntimeStress {
        class Item {
            private value=4;
            public read() { return this.value; }
            public steal(other) { return other.value; }
            public operator ==(other) { return this.value==other.read(); }
            public operator +(other) { return this.value+other.read(); }
        }
    }]]},tCurrent);
    local oCurrent=tCurrent.RuntimeStress.Item();
    local oRestored=CurrentLXC.deserialize(CurrentLXC.serialize(oCurrent));
    local oCopy=CurrentLXC.clone(oCurrent);
    assert(oCurrent==oRestored and oCopy==oCurrent and not rawequal(oCopy,oCurrent));
    if (oPrevious) then
        assert(oCurrent==oPrevious and oPrevious==oCurrent and oCurrent+oPrevious==8);
        assert(not pcall(oCurrent.steal,oPrevious) and not pcall(oPrevious.steal,oCurrent));
    end
    oPrevious=oCurrent;
end
nChecks=nChecks+1;
print('PASS runtime stress: 8 additional registries, 1 assertion group.');
print('LXC total: '..nChecks..' checks passed on '.._VERSION..'.');
