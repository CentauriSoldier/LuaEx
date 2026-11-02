--[[!
@fqxn LXC.Tests.Stress
@desc Scaled and adversarial interactions using public non-debug operations.
    Counts assertions, not loop iterations. No files or host globals are changed.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName, bPassed)
        assert(bPassed, sName);
        nChecks = nChecks + 1;
    end

    local tLeaked, tFinalized = {}, {};
    local tEnvironment = setmetatable({
        capture = function(oObject) tLeaked[#tLeaked + 1] = oObject; end,
        finalized = function(nID) tFinalized[nID] = (tFinalized[nID] or 0) + 1; end,
        copy = LXC.clone,
        save = LXC.serialize,
    }, {__index = _G});
    LXC.loadSources({['stress.lxc'] = [[namespace Stress {
        class Base {
            private secret=11;
            protected guarded=12;
            public value=1;
            public final id=null;
            public const settings={enabled=true};
            public Value { get; protected set; }=2;
            public Base(n) { this.id=n; }
            public readPrivate(other) { return other.secret; }
            public readProtected(other) { return other.guarded; }
            public readValue() { return this.Value; }
            public readID() { return this.id; }
            public assignValue(n) { this.Value=n; }
            public privateClosure() { return function(other) return other.secret; end; }
            private hidden() { return this.secret; }
            public leakMethod() { return this.hidden; }
            public callback(fWork) { return fWork(this); }
            public pause(other) { coroutine.yield(this.id); return other.secret; }
            public fail() { error("expected method failure"); }
            public operator ==(other) { return class.isa(other,Base) and this.id==other.id; }
        }
        class Child : Base {
            private secret=21;
            public Child(n) { base(n); }
            public own() { return this.secret; }
            public readDerived(other) { return other.guarded; }
            public writeDerived(other,n) { other.guarded=n; }
            public override Value { get { return field*2; } protected set { field=value+1; } }
            public baseValue() { return base.Value; }
        }
        class Sibling : Base { public Sibling(n) { base(n); } }
        class Outer {
            private secret=31;
            private class Inner {
                private secret=41;
                public Inner() {}
                public readOuter(other) { return other.secret; }
                public read() { return this.secret; }
            }
            private class Sibling {
                public Sibling() {}
                public steal(other) { return other.secret; }
            }
            public inner() { return Inner(); }
            public sibling() { return Sibling(); }
            public steal(other) { return other.secret; }
            public factory() { return Inner; }
        }
        class Graph {
            public left=null;
            public right=null;
            public map={};
            public callback=null;
            public operator ==(other) { error("Graph equality is not identity."); }
        }
        class Lifetime {
            private id=0;
            public Lifetime(n) { this.id=n; }
            public operator gc() { finalized(this.id); }
        }
        class Failed : Lifetime {
            public Failed(n) { base(n); capture(this); error("expected constructor failure"); }
            public read() { return 1; }
        }
        class InvalidRestore : Lifetime {
            public InvalidRestore(n) { base(n); }
            private validateSnapshot(state) { error("expected validation failure"); }
        }
        class CallbackClone {
            public operator clone() { return callbackClone(this); }
        }
    }]]}, tEnvironment);
    local A = tEnvironment.Stress;

    -- Repeated construction exercises independent mutable defaults, declaring
    -- private-name reuse, inherited operators and property slot ownership.
    local tObjects = {};
    for n = 1, 2000 do
        local oObject = A.Child(n);
        oObject.assignValue(n);
        assert(oObject.readPrivate(oObject)==11 and oObject.own()==21);
        assert(oObject.Value==(n+1)*2 and oObject.baseValue()==n+1);
        assert(oObject.id==n and oObject==A.Base(n));
        tObjects[n]=oObject;
    end
    fCheck('2000 constructions retain private scopes and shared property slots',#tObjects==2000);
    tObjects[1].settings.enabled=false;
    fCheck('mutable defaults are independent',tObjects[2].settings.enabled and not tObjects[1].settings.enabled);
    local a,b,sibling,base=tObjects[1],tObjects[2],A.Sibling(3),A.Base(4);
    for _ = 1, 100 do
        assert(a.readPrivate(b)==11 and a.readProtected(sibling)==12);
        assert(not pcall(a.readDerived,sibling) and not pcall(a.readDerived,base));
        a.writeDerived(b,15);
        assert(a.readDerived(b)==15);
        assert(not pcall(a.writeDerived,sibling,20));
        assert(not pcall(function() a.Value=10; end));
        assert(not pcall(function() a.assignValue('wrong'); end));
        assert(not pcall(function() a.id=2; end));
        assert(not pcall(function() a.settings={}; end));
    end
    fCheck('repeated protected receiver property type and binding denial',a.readID()==1 and sibling.readProtected(sibling)==12);

    local outer=A.Outer();
    local inner=outer.inner();
    for _ = 1, 100 do
        assert(inner.readOuter(outer)==31 and inner.read()==41);
        assert(not pcall(outer.steal,inner));
        assert(not pcall(outer.sibling().steal,inner));
        assert(not pcall(outer.factory()));
        assert(not pcall(LXC.clone,outer.factory()));
        assert(not pcall(LXC.serialize,{outer.factory()}));
        assert(LXC.class.getbyname('Stress.Outer.Inner')==nil);
    end
    fCheck('repeated nested direction and hidden factory use-site denial',inner.read()==41);

    local fPrivate=a.leakMethod();
    local fClosure=a.privateClosure();
    for _ = 1, 100 do
        assert(fClosure(b)==11);
        assert(not pcall(fPrivate));
        assert(not pcall(a.callback,function(other) return other.secret; end));
        assert(a.callback(function() return pcall(fPrivate); end)==false);
        assert(not pcall(a.fail));
        assert(not pcall(function() return a.secret; end));
    end
    fCheck('repeated callbacks errors and escaped methods retain boundaries',fClosure(b)==11);
    local tThreads={};
    for n = 1, 40 do
        tThreads[n]=coroutine.create(function() return tObjects[n].pause(b); end);
        local bOK,nID=coroutine.resume(tThreads[n]);
        assert(bOK and nID==n);
    end
    for n = 40, 1, -1 do
        assert(not pcall(function() return b.secret; end));
        local bOK,nValue=coroutine.resume(tThreads[n]);
        assert(bOK and nValue==11 and coroutine.status(tThreads[n])=='dead');
    end
    fCheck('40 interleaved suspended callers retain isolated scope',not pcall(fPrivate));

    -- Raw entries contain only attacker-supplied values. All checks of hidden
    -- storage use an authored method or a captured checked wrapper.
    local fRead=a.readPrivate;
    rawset(a,'secret',99);
    rawset(a,'id','shadow');
    rawset(a,'Value','shadow');
    rawset(a,'readPrivate',function() return 'shadow'; end);
    rawset(a,'__eq',function() error('Raw equality was used.'); end);
    fCheck('raw methods and fields only shadow lookup',a.secret==99 and a.readPrivate()=='shadow' and fRead(a)==11 and a.readID()==1);
    fCheck('raw equality name cannot replace operator dispatch',a==A.Base(1));
    local fIterator,tState,vKey=pairs({[a]='value'});
    fCheck('table keys use identity despite overloaded equality',fIterator(tState,vKey)==a and ({[a]=1})[A.Base(1)]==nil);
    local tRawCopy=LXC.clone(a);
    fCheck('shadowed object clone uses backing values',tRawCopy.readID()==1 and tRawCopy.readPrivate(tRawCopy)==11 and tRawCopy.Value==4);
    for _,sName in ipairs({'secret','id','Value','readPrivate','__eq'}) do rawset(a,sName,nil); end
    fCheck('sealed metatable cannot be replaced',not pcall(setmetatable,a,{}) and getmetatable(a)=='LXC opaque reference');
    fCheck('table move cannot read hidden fields',not pcall(table.move,a,1,1,1,{}));
    fCheck('raw enumeration reveals no backing entries',next(a)==nil and rawget(a,'secret')==nil);

    -- Incremental batches grow one dependency chain. Failed competing batches
    -- must leave earlier identities and the publication destination intact.
    for n = 1, 40 do
        local sParent=n==1 and '' or ' : Node'..(n-1);
        local sSource='namespace StressLoad { class Node'..n..sParent..' { public own'..n..'='..n..'; } }';
        local tNames=LXC.loadSources({['batch'..n..'.lxc']=sSource},tEnvironment);
        assert(#tNames==1 and tNames[1]=='StressLoad.Node'..n);
    end
    local oLoaded=tEnvironment.StressLoad.Node40();
    fCheck('40 incremental batches preserve ancestor state',oLoaded.own1==1 and oLoaded.own40==40);
    for _ = 1, 40 do
        assert(not pcall(LXC.loadSources,{['duplicate.lxc']='namespace StressLoad { class Node40 {} }'},tEnvironment));
        assert(tEnvironment.StressLoad.Node40().own1==1);
    end
    fCheck('repeated failed loading preserves committed identities',LXC.class.exists('StressLoad.Node40'));

    -- A wide object graph includes object keys, mutual cycles and aliases. The
    -- equality operator throws if infrastructure substitutes equality for identity.
    local tGraph={};
    for n = 1, 300 do tGraph[n]=A.Graph(); end
    for n,oObject in ipairs(tGraph) do
        oObject.left=tGraph[n%#tGraph+1];
        oObject.right=oObject.left;
        oObject.map[oObject]=oObject.left;
    end
    tGraph.self=tGraph;
    fCheck('codec returns exactly one restored root',select('#',LXC.deserialize(LXC.serialize(tGraph)))==1);
    for nCopy,tCopied in ipairs({LXC.clone(tGraph),LXC.deserialize(LXC.serialize(tGraph))}) do
        assert(rawequal(tCopied.self,tCopied),'Graph copy '..nCopy..' lost root alias: '..tostring(tCopied.self)..' / '..tostring(tCopied));
        for n,oObject in ipairs(tCopied) do
            assert(not rawequal(oObject,tGraph[n]));
            assert(rawequal(oObject.left,tCopied[n%#tCopied+1]));
            assert(rawequal(oObject.left,oObject.right) and rawequal(oObject.map[oObject],oObject.left));
        end
    end
    fCheck('300-node object graph clone and codec preserve cycles keys aliases',#tGraph==300);
    local tDeep,tTail={},nil;
    tTail=tDeep;
    for _ = 1, 1000 do tTail.next={}; tTail=tTail.next; end
    tTail.root=tDeep;
    local tDeepCopy=LXC.clone(tDeep);
    local tDeepRoot=tDeepCopy;
    for _ = 1, 1000 do tDeepCopy=tDeepCopy.next; end
    fCheck('1000-level ordinary table clone preserves back edge',rawequal(tDeepCopy.root,tDeepRoot) and not rawequal(tDeepRoot,tDeep));
    local fCallback=function() return 9; end;
    local oCallback=A.Graph(); oCallback.callback=fCallback;
    fCheck('function identity survives clone',rawequal(LXC.clone(oCallback).callback,fCallback));
    fCheck('function persistence rejects explicitly',not pcall(LXC.serialize,oCallback));

    -- A custom hook may not pass the source itself off as an independent copy.
    tEnvironment.callbackClone=function(oSource) return oSource; end;
    fCheck('custom clone rejects same source identity',not pcall(LXC.clone,A.CallbackClone()));

    local sInvalid=LXC.serialize(A.InvalidRestore(9000));
    for n = 1, 30 do
        assert(not pcall(A.Failed,10000+n));
        assert(not pcall(LXC.deserialize,sInvalid));
        local oLeaked=tLeaked[#tLeaked];
        assert(not pcall(function() return oLeaked.read(); end));
        assert(not pcall(LXC.clone,oLeaked) and not pcall(LXC.serialize,oLeaked));
    end
    fCheck('30 failed constructors and restores reject usable partial state',#tLeaked==30);
    tLeaked={};
    local function fCreateFinalizables()
        for n = 1, 100 do
            local oOriginal=A.Lifetime(n);
            local oCopy=LXC.clone(oOriginal);
            local oRestored=LXC.deserialize(LXC.serialize(oOriginal));
            assert(not rawequal(oOriginal,oCopy) and not rawequal(oOriginal,oRestored));
        end
    end
    fCreateFinalizables();
    collectgarbage('collect'); collectgarbage('collect'); collectgarbage('collect');
    for n = 1, 100 do assert(tFinalized[n]==3); end
    for n = 10001, 10030 do assert(tFinalized[n]==nil); end
    fCheck('300 ready objects finalize once and failed constructors skip hooks',tFinalized[1]==3);
    fCheck('failed restored shells skip hooks',tFinalized[9000]==1);
    collectgarbage('collect'); collectgarbage('collect');
    fCheck('repeated collection does not duplicate finalization',tFinalized[1]==3 and tFinalized[9000]==1);
    return nChecks;
end;
