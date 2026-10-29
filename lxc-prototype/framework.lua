--[[!
@fqxn LXC.FrameworkTests
@desc Exercises included LXC classes through normal LuaEx initialization and the
    existing serializer. Filesystem checks use memory fixtures, never native writes.
!]]
local _pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
local _pRoot = (_pSource:match('^(.*)/[^/]+$') or '.')..'/..';
package.path = _pRoot..'/?.lua;'.._pRoot..'/?/init.lua;'..package.path;
require('LuaEx.load')();
local _nChecks = 0;
local function check(sName,bPassed)
    assert(bPassed,sName);
    _nChecks = _nChecks + 1;
end

for _,sName in ipairs({'Queue','Stack','Set','Tree','SortedDictionary','ClassRegistry','XML',
        'Grid','EventSystem','Potentiometer','Protean','Ini','BaseLog','VFS'}) do
    check('LXC framework identity '..sName,class.is(_G[sName]) and class.getname(_G[sName])=='LuaEx.Classes.'..sName);
end
check('documented VFS require identity',rawequal(require('LuaEx.classes.util.VFS'),VFS));
check('VFS final contract retained',not pcall(lxc.loadSources,{['derive-vfs.lxc']='namespace FrameworkBad { class Child : LuaEx.Classes.VFS {} }'},_G));
check('normal initialization installed LXC',lxc~=nil and rawequal(require('LuaEx.load')(),luaex));
check('normal loader recursively discovers application dependencies',Demo.Characters.Player('Loader').describe()=='Loader: 100');

local d=SortedDictionary();
local count=0;
local function descending(a,b) count=count+1;return a>b;end
d.setSortFunction(descending).add('a',1).add('b',2);
local restored=deserialize(serialize(d));
restored.add('c',3);
local keys={};for key in pairs(restored) do keys[#keys+1]=key;end
check('saved custom comparator works after new insertion',table.concat(keys,',')=='c,b,a');
local nBefore=count;
restored.add('d',4);
check('restored comparator owns independent captured counter',count==nBefore);
local plain=deserialize(serialize(SortedDictionary().add('a',1)));
plain.add('b',2);
check('default comparator reconstructed without private closure export',plain.size()==2);

local tree=Tree('root');local child=tree.Add('child');child.Add(false);
local copied=clone(tree);local savedTree=deserialize(serialize(tree));
check('Tree clone reconnects parent cycle',rawequal(copied.Child(1).GetParent(),copied));
check('Tree save preserves parent and false value',rawequal(savedTree.Child(1).GetParent(),savedTree) and savedTree.Child(1).Child(1).GetValue()==false);
check('Tree preorder iterator callback',tree.Print()=='root\n  child\n    false');
tree.RemoveAt(1);check('Tree removal clears parent',child.GetParent()==nil);

local registry=ClassRegistry({Queue});
check('registry class inheritance match',registry.allows(Queue()));
check('registry dummy callback remains callable',registry.getPrerequisite()()==true);
registry.setDefaultPrerequisite(false);
check('registry dummy switch',not registry.allows(Queue()));
registry.setPrerequisite(function(other) return #other>0,'empty';end);
check('registry application callback',registry.allows(Queue({1})) and not registry.allows(Queue()));
local savedRegistry=deserialize(serialize(registry));
check('registry callback and class references survive saving',savedRegistry.allows(Queue({1})));
local defaultRegistry=deserialize(serialize(ClassRegistry({Stack})));
check('registry default reconstructed safely',defaultRegistry.allows(Stack()));
local exact=Queue();registry.clear().add(exact);
check('registry exact instance identity',registry.allows(exact)==false and not registry.contains(Queue()));

local events=EventSystem();local owner={};local callback=function() end;
events.register(owner,'changed',callback);
check('EventSystem registration and active flag',events.isActive(owner,'changed',callback));
events.setActive(owner,'changed',nil,false);check('EventSystem bulk disable',not events.isActive(owner,'changed',callback));
events.toggleActive(owner,'changed',callback);check('EventSystem toggle',events.isActive(owner,'changed',callback));
events.unregister(owner,'changed',callback);check('EventSystem unregister rejects stale callback',not pcall(events.isActive,owner,'changed',callback));
local savedEvents=EventSystem({answer=1});savedEvents.register(owner,'saved',callback);
local eventGraph=deserialize(serialize({savedEvents,owner,callback}));
check('EventSystem save retains callback keys and owner identity',eventGraph[1].isActive(eventGraph[2],'saved',eventGraph[3]));

local grid=Grid().fromString('Name,Value\nAda,"a,b"\nBob,2');
check('Grid quoted delimiter and dimensions',grid.getCell(1,'Value')=='a,b' and grid.getRowCount()==2);
local gridCopy=clone(grid);local gridSaved=deserialize(serialize(grid));
gridCopy.getRow(1).Value='copy';
check('Grid cloned row view owns new backing',gridCopy.getCell(1,'Value')=='copy' and grid.getCell(1,'Value')=='a,b');
gridSaved.getRow(2).Name='restored';
check('Grid restored row view rebuilt',gridSaved.getCell(2,1)=='restored' and grid.getCell(2,1)=='Bob');
local nCells=0;for _ in gridSaved.eachCell() do nCells=nCells+1;end
check('Grid cell iterator',nCells==4);

local ini=Ini('[Base]\nValue = 7\n[Child]\nValue = <Base>');
check('Ini inheritance',ini.GetValue('Child','Value',true)=='7');
local iniSaved=deserialize(serialize(ini));iniSaved.SetValue('Base','Value',8);
check('Ini independent saved private state',ini.GetValueNumber('Base','Value')==7 and iniSaved.GetValueNumber('Base','Value')==8);
check('Ini final contract retained',not pcall(lxc.loadSources,{['derive-ini.lxc']='namespace FrameworkBad { class Child : LuaEx.Classes.Ini {} }'},_G));

local fOpen=io.open;local written,closed=0,0;
io.open=function()
    return {write=function() written=written+1;return true;end,close=function() closed=closed+1;return true;end};
end;
local ok,reason=pcall(function()
    local log=BaseLog('memory.log',function() return 'date';end,nil,true);
    check('BaseLog migrated automatic accessors',log.getAutoWrite()==false and rawequal(log.getLevel(),BaseLog.LEVEL.INFO));
    log.log('memory only');check('BaseLog disabled auto write',written==0);
    log.setAutoWrite(true);log.log('one write');check('BaseLog explicit auto write',written==1);
    log.setAutoWrite(false);
    local savedLog=deserialize(serialize(log));savedLog.log('restored callback');
    check('BaseLog saved date callback and enum state work',not savedLog.getAutoWrite() and rawequal(savedLog.getLevel(),BaseLog.LEVEL.INFO) and written==1);
end);
io.open=fOpen;if not ok then error(reason,0);end
check('BaseLog closes opened handles',closed==2);

lxc.loadSources({['host-callback.lxc']=[[namespace FrameworkCallbacks {
    class Box { public callback=null; public other=null; }
    class Hidden {
        private class Secret { public Secret() {} }
        private factory=Secret;
        public leak() { return Secret; }
        public compiled() { return function() return 1; end; }
        public saveFactory() { return serialize(Secret); }
        public restoreFactory(source) { return deserialize(source); }
        public make() { return this.factory(); }
    }
    class RestoreFailure {
        public value=5;
        public __deserialize(state) { LxcFrameworkCapture(this); error('expected restore failure'); }
    }
}]]},_G);
local box=FrameworkCallbacks.Box();local shared={n=1};local object=box;
local function increment() shared.n=shared.n+1;return shared.n,object;end
local function read() return shared.n,object;end
box.callback=increment;box.other={read=read,shared=shared};
local root={box,increment,read,shared};root.self=root;
local graph=deserialize(serialize(root));
local n,linked=graph[2]();
check('callback captures class back-reference',n==2 and rawequal(linked,graph[1]));
check('shared captures and callback alias',graph[3]()==2 and graph[4].n==2 and rawequal(graph[1].callback,graph[2]));
check('host graph root cycle and independence',rawequal(graph.self,graph) and shared.n==1);
local callbackOnly=deserialize(serialize(increment));
local _,capturedBox=callbackOnly();
check('root function can capture LXC state',class.isinstanceof(capturedBox,FrameworkCallbacks.Box));
local hidden=FrameworkCallbacks.Hidden();local privateFactory=hidden.leak();
check('captured hidden factory is scope checked',not pcall(serialize,function() return privateFactory;end));
local compiled=hidden.compiled();
check('indirect private compiler closure is rejected',not pcall(serialize,function() return compiled;end));
check('native C functions remain explicitly unsupported',not pcall(serialize,print));

local scalar=0;
local function add() scalar=scalar+1;return scalar;end
local function current() return scalar;end
local functions=deserialize(serialize({add,current}));
check('ordinary serializer retains shared scalar cells',functions[1]()==1 and functions[2]()==1 and scalar==0);
box=FrameworkCallbacks.Box();box.callback=add;box.other=current;
local sharedCells=deserialize(serialize(box));
check('LXC callbacks retain shared scalar cells',sharedCells.callback()==1 and sharedCells.other()==1 and scalar==0);
local environment={answer=42};
local environmentCallback=assert(load('return function() return answer; end','custom environment','t',environment))();
box=FrameworkCallbacks.Box();box.callback=environmentCallback;box.other=environment;
local savedEnvironment=deserialize(serialize(box));
savedEnvironment.other.answer=43;
check('custom callback environment shares restored table',savedEnvironment.callback()==43 and environment.answer==42);
local globalCallback=assert(load('return function() return _G; end','global environment','t',_G))();
box.callback=globalCallback;box.other={math.huge,-math.huge,0/0};
local savedGlobals=deserialize(serialize(box));
check('global callback environment retains current global binding',rawequal(savedGlobals.callback(),_G));
check('host serializer preserves nonfinite numbers',savedGlobals.other[1]==math.huge and savedGlobals.other[2]==-math.huge and savedGlobals.other[3]~=savedGlobals.other[3]);
check('standalone LXC codec remains data only',not pcall(lxc.serialize,box));
box.callback=print;
check('native callback rejection does not poison host export',not pcall(serialize,box));
box.callback=add;
check('host export recovers after unsupported callback',deserialize(serialize(box)).callback()==1);
local originalPoint=point(2,3);
local withPoint=deserialize(serialize(Queue({originalPoint})));
check('foreign primitive inside LXC graph',type(withPoint.peek())=='primitive' and
    getmetatable(withPoint.peek()).__subtype=='point' and withPoint.peek().x==2 and withPoint.peek().y==3);
withPoint.peek().x=4;
check('restored foreign primitive owns independent state',originalPoint.x==2 and withPoint.peek().x==4);
local queue=Queue({1});local typed=array({queue,queue});
local typedCopy=deserialize(serialize(typed));
check('typed array restores LXC item type',type(typedCopy)=='array' and type(typedCopy[1])=='Queue' and typedCopy[1].peek()==1);
check('typed array preserves repeated LXC identity',rawequal(typedCopy[1],typedCopy[2]) and not rawequal(typedCopy[1],queue));
queue.enqueue(typed);
local mixed=deserialize(serialize({typed,queue}));
check('mixed array LXC cycle and root aliases',rawequal(mixed[1][1],mixed[2]) and rawequal(mixed[2].dequeue(),1) and rawequal(mixed[2].peek(),mixed[1]));
local capturedArray=typed;
local mixedCallback=function() return capturedArray,queue;end;
local mixedFunctions=deserialize(serialize({typed,queue,mixedCallback}));
local restoredArray,restoredQueue=mixedFunctions[3]();
check('callback captures reconnect across typed container cycle',rawequal(restoredArray,mixedFunctions[1]) and rawequal(restoredQueue,mixedFunctions[2]));
check('compiled callbacks inside typed containers remain rejected',not pcall(serialize,array({compiled})));
check('hidden factories inside typed containers remain scope checked',not pcall(serialize,array({privateFactory})));
local hiddenCopy=deserialize(serialize(hidden));
check('private stored factory retains declaring authority',class.isinstance(hiddenCopy.make()));
local savedFactory=hidden.saveFactory();
check('class-owned save and restore retain caller authority',rawequal(hidden.restoreFactory(savedFactory),privateFactory));
check('external restore cannot import hidden factory',not pcall(deserialize,savedFactory));
check('restored private state remains inaccessible',not pcall(function() return hiddenCopy.factory;end));

local previousCapture=LxcFrameworkCapture;local leaked;
LxcFrameworkCapture=function(value) leaked=value;end;
local failingSave=serialize(array({FrameworkCallbacks.RestoreFailure()}));
local failed,reason=pcall(deserialize,failingSave);
LxcFrameworkCapture=previousCapture;
check('failed snapshot validation rejects mixed graph',not failed and tostring(reason):find('expected restore failure',1,true)~=nil);
check('failed restored shell is unusable after hook escape',leaked~=nil and not pcall(function() return leaked.value;end));
check('restore recovers after failed mixed graph',deserialize(serialize(array({Queue({7})})))[1].peek()==7);

local rawSerializer=require('LuaEx.lib.serializer');
local literal=lxc.serialize(FrameworkCallbacks.Box());
check('older tagged data-only class save stays readable',class.isinstanceof(deserialize('--LXC:1\n'..literal),FrameworkCallbacks.Box));
local oldGraph=assert(load('return '..literal,'legacy fixture','t',{}))();
local marker={};
local oldHost='--LXC:2\n'..rawSerializer.serialize({Graph=oldGraph,References={marker},Markers={marker}});
check('older tagged host envelope stays readable',class.isinstanceof(deserialize(oldHost),FrameworkCallbacks.Box));
local source={};source.self=source;
local ordinary=rawSerializer.serialize(source,'previously ignored argument');
check('ordinary serializer keeps version-one format and ignored extra args',ordinary:find('["version"] = 1',1,true)~=nil);
local ordinaryCopy=rawSerializer.deserialize(ordinary,'previously ignored argument');
check('ordinary serializer retains native table cycle',rawequal(ordinaryCopy.self,ordinaryCopy));
local authorizedState=serialize(hidden);
local graphText=authorizedState:sub(9);
local forged=assert(load('return '..graphText,'inspect staged fixture','t',{
    serializer={restoreGraph=function(graph) return graph;end},math=math}))();
for nID,node in ipairs(forged.nodes) do
    if node.kind=='staged' and node.header.Kind=='class' then forged.root={node=nID};break;end
end
local forgedSave='--LXC:3\nserializer.restoreGraph('..rawSerializer.serialize(forged)..')';
check('forged root cannot expose encapsulated hidden factory',not pcall(deserialize,forgedSave));
local originalNode=FrameworkCallbacks.Box();originalNode.callback=function() return 9;end;
local resaved=deserialize(serialize(deserialize(serialize(array({originalNode,originalNode})))));
check('resaving typed class graphs preserves callbacks and aliases',resaved[1].callback()==9 and rawequal(resaved[1],resaved[2]));
local eager={};setmetatable(eager,{__serialize=function() return {self=eager};end});
check('unsupported eager object hook cycle still rejects',not pcall(serialize,eager));
print('PASS framework integration: '.._nChecks..' checks through normal LuaEx.load().');
