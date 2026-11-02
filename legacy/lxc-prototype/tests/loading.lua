--[[!
@fqxn LXC.Tests.Loading
@desc Batch publication, using/requires order, previous batches and static failures.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName,bPassed) assert(bPassed,sName); nChecks=nChecks+1; end
    local tEvents = {};
    local tEnvironment = setmetatable({record=function(sName,vValue)
        tEvents[#tEvents+1]=sName; return vValue;
    end}, {__index=_G});
    local tOrder=LXC.loadSources({['loading.lxc']=[[
        namespace Dependencies {
            class Settings { public static ready=record("settings",true); }
        }
        namespace Loading {
            using Dependencies;
            class A requires(Dependencies.Settings) {
                public static flag=Settings.ready;
                private static own=1;
                static A() { A.own=2; record("static",true); }
                public first=record("base field",1);
                public A() { record("base body",true); }
                public static readOwn() { return A.own; }
            }
            class B : A {
                public second=record("child field",2);
                public B() { record("child body",true); }
            }
        }
    ]]},tEnvironment);
    fCheck('requires before dependent static fields',tOrder[1]=='Dependencies.Settings' and tEnvironment.Loading.A.flag==true);
    fCheck('static constructor accesses private fields',tEnvironment.Loading.A.readOwn()==2);
    local oObject=tEnvironment.Loading.B();
    fCheck('base-first source initialization',table.concat(tEvents,',')=='settings,static,base field,base body,child field,child body');
    fCheck('constructed fields',oObject.first==1 and oObject.second==2);
    LXC.loadSources({['later.lxc']='namespace Loading { class C : B {} }'},tEnvironment);
    fCheck('previously loaded parent',tEnvironment.Loading.C().second==2);
    local tFailed={};
    local bOK=pcall(LXC.loadSources,{['failed.lxc']=[[
        namespace Broken { class A {} class B { static B() { error("fail"); } } }
    ]]},setmetatable(tFailed,{__index=_G}));
    fCheck('failed initialization publishes no batch',not bOK and tFailed.Broken==nil);
    fCheck('failed batch leaves no registry entry',not LXC.class.exists('Broken.A'));
    bOK=pcall(LXC.loadSources,{['cycle.lxc']='namespace Cycle { class A requires(Cycle.B) {} class B requires(Cycle.A) {} }'},{});
    fCheck('dependency cycle rejected',not bOK);
    bOK=pcall(LXC.loadSources,{['static-this.lxc']='namespace Bad { class A { public static run() { return this; } } }'},{});
    fCheck('static this rejected at compilation',not bOK);
    bOK=pcall(LXC.loadSources,{['imports.lxc']=[[
        namespace One { class A {} } namespace Two { class A {} }
        namespace Three { using One; using Two; class Child : A {} }
    ]]},{});
    fCheck('ambiguous using class rejected',not bOK);

    local oLeakedClass, oLeakedInstance;
    local tLeakEnvironment = setmetatable({capture=function(oClass,oInstance)
        oLeakedClass,oLeakedInstance=oClass,oInstance;
    end},{__index=_G});
    bOK=pcall(LXC.loadSources,{['leaked.lxc']=[[namespace Leaked {
        class A { public value=1; }
        class B requires(Leaked.A) { static B() { capture(A,A()); error("stop"); } }
    }]]},tLeakEnvironment);
    fCheck('failed batch invalidates leaked class',not bOK and not pcall(oLeakedClass));
    fCheck('failed batch invalidates leaked instance',not pcall(function() return oLeakedInstance.value; end));
    fCheck('failed class cannot be serialized',not pcall(LXC.serialize,oLeakedClass));
    fCheck('failed class hidden from helpers',not LXC.class.exists(oLeakedClass));

    local tChanged={};
    tChanged.mutate=function() tChanged.Changed={A='occupied'}; end;
    bOK=pcall(LXC.loadSources,{['changed.lxc']=[[namespace Changed {
        class A { static A() { mutate(); } }
    }]]},tChanged);
    fCheck('destination rechecked after initialization',not bOK and tChanged.Changed.A=='occupied');
    fCheck('changed destination does not commit registry',not LXC.class.exists('Changed.A'));

    local tReentrant={};
    tReentrant.enter=function()
        LXC.loadSources({['inner.lxc']='namespace Reentrant { class Inner {} }'},tReentrant);
    end;
    bOK=pcall(LXC.loadSources,{['outer.lxc']=[[namespace Reentrant {
        class Outer { static Outer() { enter(); } }
    }]]},tReentrant);
    fCheck('reentrant load rejected without publication',not bOK and tReentrant.Reentrant==nil);
    LXC.loadSources({['recovery.lxc']='namespace Recovery { class Item {} }'},tReentrant);
    fCheck('loader recovers after failed staging',tReentrant.Recovery.Item~=nil);
    local bVisited=false;
    local tDynamic=setmetatable({}, {__pairs=function() bVisited=true; return next,{},nil; end});
    fCheck('source map cannot execute enumeration callbacks',not pcall(LXC.loadSources,tDynamic,{}) and not bVisited);
    local bDiagnostic,sDiagnostic=pcall(LXC.loadSources,{['diagnostic.lxc']=[[namespace Diagnostic {
        class A { public override missing() {} }
    }]]},{});
    fCheck('declaration diagnostic names file class and member',not bDiagnostic and
        string.find(sDiagnostic,'diagnostic.lxc:',1,true) and string.find(sDiagnostic,'Diagnostic.A.missing',1,true));
    return nChecks;
end;
