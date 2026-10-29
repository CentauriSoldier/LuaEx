--[[!
@fqxn LXC.Tests.Equality
@desc Native equality, hidden state under raw decoy writes, graph identity and
    finalizer resurrection. Assertions distinguish value equality from identity.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName, bPassed)
        assert(bPassed, sName);
        nChecks = nChecks + 1;
    end

    local nCalls, nFinalized, oResurrected = 0, 0, nil;
    local tEnvironment = setmetatable({
        counted = function() nCalls = nCalls + 1; end,
        resurrect = function(oObject, nValue)
            assert(nValue == 7, 'Finalizer lost private state.');
            nFinalized = nFinalized + 1;
            oResurrected = oObject;
        end,
    }, {__index = _G});
    LXC.loadSources({['equality.lxc'] = [[namespace Equality {
        class Value {
            private value=0;
            public Value(n) { this.value=n; }
            public read() { return this.value; }
            public operator ==(other) {
                counted();
                return class.isa(other,Value) and this.value==other.value;
            }
        }
        class Inherited : Value { public Inherited(n) { base(n); } }
        class Override : Value {
            public Override(n) { base(n); }
            public override operator ==(other) { return not base.__eq(other); }
        }
        class Two {
            public operator ==(left,right) { return left.marker=="left" and right.marker=="right"; }
            public marker="right";
        }
        class Plain {}
        class Canonical { public __eq(other) { return true; } }
        class External {
            private secret=5;
            private read() { return this.secret; }
            public leak() { return this.read; }
            public compare(other) { return this==other; }
        }
        class Storage {
            private secret=10;
            public value=2;
            public Auto { get; set; }=3;
            public Custom { get { return field; } set { field=value; } }=4;
            public final fixed=5;
            public static count=6;
            public read() { return this.secret,this.value,this.Auto,this.Custom,this.fixed,Storage.count; }
        }
        class Graph {
            public link=null;
            public data={};
            public operator ==(other) { error("Internal identity comparison invoked user equality."); }
        }
        class Lifetime {
            private value=7;
            public read() { return this.value; }
            public operator gc() { resurrect(this,this.value); }
        }
        class Failed : Lifetime { public Failed() { error("failed construction"); } }
    }]]}, tEnvironment);
    local A = tEnvironment.Equality;
    local a, b, c = A.Value(2), A.Value(2), A.Value(3);
    fCheck('empty table identities',type(a)=='table' and next(a)==nil and type(A.Value)=='table');
    fCheck('same-instance equality skips operator',a==a and nCalls==0);
    fCheck('one-operand private cross-instance equality',a==b and not rawequal(a,b));
    fCheck('unequal values and negation',a~=c and not (a~=b));
    fCheck('inherited equality',A.Inherited(2)==a and a==A.Inherited(2));
    fCheck('overridden equality and base',A.Override(2)~=a and A.Override(3)==a);
    local oPlain=A.Plain();
    fCheck('default identity',oPlain==oPlain and oPlain~=A.Plain());
    fCheck('no equality operation defaults false for foreign table',oPlain~={} and {}~=oPlain);
    fCheck('canonical equality spelling',A.Canonical()==oPlain);
    local oTwo=A.Two();
    fCheck('two operands preserve original order and right selection',({marker='left'})==oTwo and oTwo~={marker='left'});
    local nBefore=nCalls;
    fCheck('Lua equality excludes different native types',a~=2 and 2~=a and a~='2' and a~=nil and a~=false and nCalls==nBefore);
    fCheck('equality with null is not null identity',a~=LXC.null and rawequal(LXC.deserialize(LXC.serialize(LXC.null)),LXC.null));
    fCheck('left class precedence',a~=setmetatable({}, {__eq=function() error('Wrong operand selected.'); end}));
    local tForeign=setmetatable({}, {__eq=function(left,right) return rawequal(left,oPlain) and type(right)=='table'; end});
    fCheck('foreign right fallback',oPlain==tForeign);
    fCheck('foreign left precedence',tForeign~=oPlain);
    local oExternal=A.External();
    local fPrivate=oExternal.leak();
    local tAttack=setmetatable({}, {__eq=function() return fPrivate(); end});
    fCheck('foreign equality callback cannot borrow class rights',not pcall(oExternal.compare,tAttack));

    local oStorage=A.Storage();
    rawset(oStorage,'secret',99);
    rawset(oStorage,'value','shadow');
    rawset(oStorage,'Auto','shadow');
    rawset(oStorage,'Custom','shadow');
    rawset(oStorage,'fixed','shadow');
    rawset(A.Storage,'count','shadow');
    oStorage.value='second shadow';
    local nSecret,nValue,nAuto,nCustom,nFixed,nCount=oStorage.read();
    fCheck('raw entries shadow public lookup',oStorage.value=='second shadow' and oStorage.Auto=='shadow' and A.Storage.count=='shadow');
    fCheck('lexical reads retain all hidden slots',nSecret==10 and nValue==2 and nAuto==3 and nCustom==4 and nFixed==5 and nCount==6);
    local oCopy=LXC.clone(oStorage);
    local oRestored=LXC.deserialize(LXC.serialize(oStorage));
    fCheck('clone and persistence ignore raw decoy entries',oCopy.value==2 and oCopy.Auto==3 and oRestored.Custom==4 and rawget(oCopy,'secret')==nil);
    for _,sName in ipairs({'secret','value','Auto','Custom','fixed'}) do rawset(oStorage,sName,nil); end
    rawset(A.Storage,'count',nil);
    fCheck('removing raw entries restores hidden lookup',oStorage.value==2 and oStorage.Auto==3 and oStorage.Custom==4 and A.Storage.count==6);
    fCheck('hidden typing and final binding still enforced',not pcall(function() oStorage.value='wrong'; end) and not pcall(function() oStorage.fixed=6; end));

    local oGraph=A.Graph();
    oGraph.link=oGraph;
    oGraph.data[oGraph]=oGraph;
    local tRoot={oGraph,oGraph,A.Graph};
    tRoot.self=tRoot;
    local tCopy=LXC.clone(tRoot);
    local tRestored=LXC.deserialize(LXC.serialize(tRoot));
    for _,tGraph in ipairs({tCopy,tRestored}) do
        local oObject=tGraph[1];
        fCheck('graph identity avoids user equality',rawequal(tGraph[1],tGraph[2]) and rawequal(oObject.link,oObject) and
            rawequal(oObject.data[oObject],oObject) and rawequal(tGraph.self,tGraph) and rawequal(tGraph[3],A.Graph));
    end
    fCheck('class field typing distinguishes decoys from ordinary tables',not pcall(function() oGraph.link={}; end));
    fCheck('helpers avoid user equality',LXC.class.isinstanceof(oGraph,A.Graph) and LXC.class.isa(oGraph,A.Graph));

    local tRejected = {
        'class A { private operator ==(other) {} }',
        'class A { public static operator ==(other) {} }',
        'class A { public operator ==(a,b,c) {} }',
        'class A { public operator ==(other,...) {} }',
        'class A { public final operator ==(other) {} } class B:A { public override operator ==(other) {} }',
        'class A { public operator ==(other) {} } class B:A { public override operator ==(a,b) {} }',
        'class A { public operator ==(other) {} } class B:A { public operator ==(other) {} }',
    };
    for n,sSource in ipairs(tRejected) do
        fCheck('equality declaration contract '..n,not pcall(LXC.loadSources,{['invalid-equality.lxc']='namespace InvalidEquality'..n..' {'..sSource..'}'},{}));
    end

    -- Keep the resurrected reference only until its dispatch/private read is checked.
    do local oLifetime=A.Lifetime(); end
    collectgarbage('collect'); collectgarbage('collect');
    fCheck('finalizer resurrection retains private state',nFinalized==1 and oResurrected.read()==7);
    oResurrected=nil;
    collectgarbage('collect'); collectgarbage('collect');
    fCheck('resurrected instance finalizes exactly once',nFinalized==1);
    fCheck('failed constructor rejected',not pcall(A.Failed));
    collectgarbage('collect'); collectgarbage('collect');
    fCheck('incomplete instance skips finalizer',nFinalized==1);
    return nChecks;
end;
