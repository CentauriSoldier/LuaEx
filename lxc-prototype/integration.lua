--[[!
@fqxn Experiments.LXC.DiscoveryIntegration
@desc Initializes only LuaEx core in this fresh process, then exercises real .lxc
    discovery and loading through existing filesystem hooks. No framework edits.
!]]
local pSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local pRoot = pSource:match("^(.*)/[^/]+$") or ".";
package.path = pRoot.."/../?.lua;"..pRoot.."/../?/init.lua;"..package.path;
require("LuaEx.load")(0);

local LXC = assert(loadfile(pRoot.."/lxc.lua"))();
local tFiles = LXC.discover(pRoot.."/examples/?.lua;"..pRoot.."/examples/?/init.lua");
assert(#tFiles == 2, "Expected exactly two discovered .lxc examples.");
local tEnvironment = setmetatable({}, {__index = _G});
local tOrder = LXC.loadFiles(tFiles, tEnvironment);
assert(tOrder[1] == "Demo.Characters.Creature", "Discovered parent must load first.");
assert(tEnvironment.Demo.Characters.Player("James").describe() == "James: 100", "Discovered classes must execute.");
print("LXC discovery integration: 3 checks passed using real LuaEx io.listfiles.");

-- Bind the existing core services into an explicit host environment. This does
-- not change LuaEx.load or migrate any framework class.
local tHost = setmetatable({cloner=cloner, serializer=serializer, type=type}, {__index=_G});
LXC.bindHost(tHost);
LXC.bindHost(tHost);
local nChecks=0;
local function check(sName,bPassed)
    assert(bPassed,sName);
    nChecks=nChecks+1;
end
LXC.loadSources({['host.lxc']=[[namespace HostCheck {
    class Node {
        private value=5;
        public next=null;
        public read() { return this.value; }
        public closure() { return function() return this.value; end; }
        public operator clone() {
            local other=Node();
            cloner.registerCopy(this,other);
            other.next=clone(this.next);
            return other;
        }
    }
    class Attack {
        public operator clone() { return callback(this,Attack()); }
    }
    class Unregistered {
        public next=null;
        public operator clone() { local other=Unregistered(); other.next=clone(this.next); return other; }
    }
}]]},tHost);
local Node=tHost.HostCheck.Node;
local oNode=Node(); oNode.next=oNode;
local oCopy=tHost.clone(oNode);
check('host custom clone preserves cycle and private state',not rawequal(oNode,oCopy) and rawequal(oCopy.next,oCopy) and oCopy.read()==5);
local tCopy=tHost.cloner.cloneIndependent({oNode,oNode});
check('host clone preserves repeated custom-hook aliases',rawequal(tCopy[1],tCopy[2]) and rawequal(tCopy[1].next,tCopy[1]));
local sSaved=tHost.serialize({oNode,oNode});
local tRestored=tHost.deserialize(sSaved);
check('tagged host codec preserves graph identity',sSaved:sub(1,8)=='--LXC:3\n' and rawequal(tRestored[1],tRestored[2]) and rawequal(tRestored[1].next,tRestored[1]) and tRestored[1].read()==5);
check('host type bridge recognizes identities',tHost.type(oNode)=='Node' and tHost.type(Node)=='class');
check('host codec rejects compiled closures',not pcall(tHost.serialize,oNode.closure()));
tHost.callback=function(oSource,oReplacement)
    tHost.cloner.registerCopy(oSource,oReplacement);
    return oReplacement;
end;
check('external callback cannot register privileged copy',not pcall(tHost.clone,tHost.HostCheck.Attack()));
local oUnregistered=tHost.HostCheck.Unregistered(); oUnregistered.next=oUnregistered;
check('cyclic custom clone without registration rejects explicitly',not pcall(tHost.clone,oUnregistered));
check('host clone recovers after failed traversal',tHost.clone(oNode).read()==5);
check('legacy primitive codec remains available',tHost.deserialize(tHost.serialize(42))==42);
print('LXC host bridge integration: '..nChecks..' checks passed using existing LuaEx core.');
