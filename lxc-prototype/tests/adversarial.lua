--[[!
@fqxn LXC.Tests.Adversarial
@desc Iterator access boundaries, invalid public inputs, malformed declarations
    and corrupt/oversized wire data. Debug intrusion is outside these tests.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName,bPassed)
        assert(bPassed,sName);
        nChecks=nChecks+1;
    end
    local tEnvironment=setmetatable({}, {__index=_G});
    LXC.loadSources({['adversarial.lxc']=[[namespace Adversarial {
        class Iterator {
            private values={3,5,7};
            private secret=19;
            private hidden() { return this.secret; }
            public leak() { return this.hidden; }
            public operator pairs() {
                return function(_,key) return next(this.values,key); end,nil,nil;
            }
            public sum(other) {
                local total=0;
                for _,value in pairs(other) do total=total+value; end;
                return total;
            }
            public run(fIterator) {
                for _ in fIterator,nil,nil do end;
            }
            public fail(other) { for _ in pairs(other) do error("iterator body failed"); end; }
            public loaded() {
                local fWork=load("return other.secret","external loaded body","t",{other=this});
                return fWork();
            }
            public globalWrite() { injected=1; }
        }
        class Base {
            protected work() { return 1; }
            public call(other) { return other.work(); }
        }
        class Child : Base {
            protected override work() { return base.work()+1; }
            public restricted(other) { return other.work(); }
        }
        class Sibling : Base {}
        abstract class Abstract {
            public abstract __eq(other);
        }
        class Concrete : Abstract {
            public override __eq(other) { return true; }
        }
        class Types {
            public count=1;
            public flag=false;
            public text="value";
            public values={};
            public optional=null;
            public factory=Base;
            public constructorReturn() { return 1,2,3; }
        }
    }]]},tEnvironment);
    local A=tEnvironment.Adversarial;
    local a=A.Iterator();
    fCheck('class pairs iterator keeps legitimate declaring scope',a.sum(a)==15);
    local fIterator,tState,vKey=pairs(a);
    local nKey,nValue=fIterator(tState,vKey);
    fCheck('escaped authored iterator retains declared rights',nKey==1 and nValue==3);
    local fPrivate=a.leak();
    local tAttack=setmetatable({}, {__pairs=function() return fPrivate(); end});
    fCheck('foreign pairs metamethod cannot borrow loop caller rights',not pcall(a.sum,tAttack));
    tAttack=setmetatable({}, {__pairs=function() return function() return fPrivate(); end,nil,nil; end});
    fCheck('foreign iterator callback cannot borrow loop caller rights',not pcall(a.sum,tAttack));
    fCheck('direct generic iterator callback cannot borrow rights',not pcall(a.run,function() return fPrivate(); end));
    fCheck('iterator body error propagates',not pcall(a.fail,a));
    fCheck('iterator error leaves access closed',not pcall(fPrivate) and not pcall(function() return a.secret; end));
    fCheck('dynamically loaded function cannot borrow declaring rights',not pcall(a.loaded));
    fCheck('compiled environment denies implicit global writes',not pcall(a.globalWrite) and tEnvironment.injected==nil);
    fCheck('raw next does not enumerate hidden values',next(a)==nil);
    fCheck('pairs dispatch ignores raw named replacement',pcall(function()
        rawset(a,'__pairs',function() error('raw replacement'); end);
        assert(a.sum(a)==15);
        rawset(a,'__pairs',nil);
    end));
    local oBase,oChild,oSibling=A.Base(),A.Child(),A.Sibling();
    fCheck('base scope retains protected overridden method contract',oBase.call(oChild)==2);
    fCheck('derived scope dispatches protected override',oChild.restricted(oChild)==2);
    fCheck('derived protected method rejects sibling receiver',not pcall(oChild.restricted,oSibling));
    fCheck('external protected override lookup rejects',not pcall(function() return oChild.work; end));
    fCheck('abstract equality requires concrete implementation',not pcall(A.Abstract) and A.Concrete()=={});

    local oTypes=A.Types();
    local tWrong={
        {'count','wrong'}, {'flag',1}, {'text',false}, {'values',2}, {'factory',{}},
        {'count',LXC.null}, {'flag',LXC.null}, {'text',LXC.null}, {'values',LXC.null},
    };
    for n,tCase in ipairs(tWrong) do
        fCheck('typed field invalid assignment '..n,not pcall(function() oTypes[tCase[1]]=tCase[2]; end));
    end
    fCheck('nil assignment rejected',not pcall(function() oTypes.count=nil; end));
    oTypes.optional=oChild;
    fCheck('null establishes concrete class constraint',not pcall(function() oTypes.optional=oBase; end));
    fCheck('normal methods preserve Lua multiple returns',select('#',oTypes.constructorReturn())==3);
    fCheck('ordinary table cannot impersonate class',not LXC.class.is({}) and not LXC.class.isinstance({}));
    fCheck('unregistered metadata stays unavailable',LXC.class.getname({})==nil and not LXC.class.exists({}) and LXC.class.getchildnames({})==nil);
    fCheck('class relationship helpers reject unresolved inputs',not LXC.class.isa(oChild,{}) and not LXC.class.isinstanceof(oChild,{}) and not LXC.class.ischild({},A.Base));
    fCheck('class name lookup returns nil for nonstring input',LXC.class.getbyname({})==nil);

    local tInvalidCalls={
        function() LXC.loadSources(nil,{}); end,
        function() LXC.loadSources({},nil); end,
        function() LXC.loadSources({[1]='namespace X {}'},{}); end,
        function() LXC.loadSources({['bad.lxc']=false},{}); end,
        function() LXC.loadFiles(nil,{}); end,
        function() LXC.loadFiles({1},{}); end,
        function() LXC.loadFiles(setmetatable({},{__index={}}),{}); end,
        function() LXC.deserialize({}); end,
        function() LXC.deserialize(nil); end,
        function() LXC.clone({},'wrong'); end,
        function() LXC.saveStatic(oTypes); end,
        function() LXC.loadStatic({},'{}'); end,
        function() LXC.bindHost({}); end,
    };
    for n,fCall in ipairs(tInvalidCalls) do fCheck('invalid public API input '..n,not pcall(fCall)); end

    local tInvalidSources={
        'private class A {}',
        'public private class A {}',
        'public public class A {}',
        'abstract final class A {}',
        'class A { public x=1; public x=2; }',
        'class A { public run(x,x) {} }',
        'class A { public run(this) {} }',
        'class A { public Value { get; get; }=1; }',
        'class A { public Value { get("bad-prefix"); }=1; }',
        'class A { public abstract Value { get; } }',
        'class A requires(Missing.Dependency) {}',
        'class A requires(Bad.A) {}',
        'class A permits(Bad.A,Bad.A) {}',
        'class A permits(Bad.A) {}',
        'class A { public run() { return base(); } }',
        'class A { public run() { return _ENV; } }',
        'class A { public run() { local __lxc_context=1; return __lxc_context; } }',
        'class A { public const x; }',
        'class A { public final const x=1; }',
        'class A { public final Value { get; }=1; } class B:A { public override Value { get; } }',
        'class A { public static Value { get; }=1; } class B:A { public static Value { get; }=2; }',
        'class A { public static A() {} }',
        'class A { public A() { return 1; } static A() { A(); } }',
        'class A { public value=nil; static A() { A(); } }',
        'class A { public run() { return "unterminated; } }',
        'class A { public run() {',
        'class A {} using Other;',
        'interface A {}',
    };
    for n,sSource in ipairs(tInvalidSources) do
        local tTarget=setmetatable({}, {__index=_G});
        local bOK=pcall(LXC.loadSources,{['bad-input.lxc']='namespace Bad {'..sSource..'}'},tTarget);
        fCheck('malformed declaration '..n,not bOK and tTarget.Bad==nil);
    end

    local sPrefix='{["Version"]=1,["Root"]={["Ref"]=1,},["Nodes"]={';
    local tBadWire={
        '', '{}', 'true', 'return {}', '{["Version"]=1,["Version"]=1,}',
        '{["Version"]=2,["Root"]={},["Nodes"]={},}',
        '{["Version"]=1,["Root"]={["Null"]=false,},["Nodes"]={},}',
        '{["Version"]=1,["Root"]={["Null"]=true,["Value"]=1,},["Nodes"]={},}',
        '{["Version"]=1,["Root"]={["Ref"]=0,},["Nodes"]={},}',
        '{["Version"]=1,["Root"]={["Ref"]=0.5,},["Nodes"]={},}',
        sPrefix..'[2]={["Kind"]="table",["Entries"]={},},},}',
        sPrefix..'[1]={["Kind"]="unknown",["Class"]="Adversarial.Types",["Fields"]={},},},}',
        sPrefix..'[1]={["Kind"]="class",["Class"]="Missing.Class",},},}',
        sPrefix..'[1]={["Kind"]="table",["Entries"]={[1]={[1]={["Value"]=1,},},},},},}',
        sPrefix..'[1]={["Kind"]="instance",["Class"]="Adversarial.Types",["Fields"]={},},},}',
        sPrefix..'[1]={["Kind"]="table",["Entries"]={},["Extra"]=true,},},}',
        '{["Version"]=1,["Root"]={["Value"]=(function() error("executed") end)(),},["Nodes"]={},}',
    };
    for n,sWire in ipairs(tBadWire) do fCheck('corrupt snapshot '..n,not pcall(LXC.deserialize,sWire)); end
    local sSaved=LXC.serialize(oTypes);
    fCheck('corrupt saved binding flags rejected',not pcall(LXC.deserialize,(sSaved:gsub('"Locked"%]=false','"Locked"]=true',1))));
    fCheck('static restore rejects instance root',not pcall(LXC.loadStatic,A.Types,sSaved));
    fCheck('text size limit enforced before parsing',not pcall(LXC.deserialize,string.rep(' ',16*1024*1024+1)));
    local sNested=string.rep('{[1]=',256)..'true'..string.rep(',}',256);
    local bNested,sNestingError=pcall(LXC.deserialize,sNested);
    fCheck('literal nesting limit enforced',not bNested and tostring(sNestingError):find('nesting limit',1,true));
    local tNodes={};
    for n=1,100001 do tNodes[n]='['..n..']={["Kind"]="table",["Entries"]={},},'; end
    local bNodes,sNodeError=pcall(LXC.deserialize,sPrefix..table.concat(tNodes)..'},}');
    fCheck('graph node limit enforced',not bNodes and tostring(sNodeError):find('node limit',1,true));
    fCheck('codec recovers after malformed and limit inputs',LXC.deserialize(LXC.serialize(oTypes)).count==1);
    return nChecks;
end;
