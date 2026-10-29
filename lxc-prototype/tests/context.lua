--[[!
@fqxn LXC.Tests.Context
@desc Non-debug access boundaries: callbacks, closures, aliases, coroutines,
    raw operations, private references and mutation of public Lua dependencies.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName,bPassed) assert(bPassed,sName); nChecks=nChecks+1; end
    local tEnvironment=setmetatable({}, {__index=_G});
    LXC.loadSources({['context.lxc']=[[namespace Scope {
        class A {
            private secret=10;
            private readPrivate() { return this.secret; }
            public A() {}
            public get() { return this.secret; }
            public leakMethod() { return this.readPrivate; }
            public callback(fWork) { return fWork(this); }
            public protectedClosure() { return function() return this.secret; end; }
            public delayed(other) { coroutine.yield("paused"); return other.secret; }
            public nestedCall(other) { local function read() return other.secret; end; return read(); }
            public fail() { error("intentional failure"); }
            public handle() { return function(other) return other.secret; end; }
        }
    }]]},tEnvironment);
    local A=tEnvironment.Scope.A;
    local a,b=A(),A();
    fCheck('public this read',a.get()==10);
    fCheck('escaped private method denied',not pcall(a.leakMethod()));
    fCheck('declared closure remains authorized',a.protectedClosure()()==10);
    fCheck('nested local function retains context',a.nestedCall(b)==10);
    fCheck('external callback cannot borrow rights',not pcall(a.callback,function(other) return other.secret; end));
    local fPrivate = a.leakMethod();
    fCheck('tail-called external callback cannot borrow rights',not pcall(a.callback,function()
        return fPrivate();
    end));
    fCheck('tail-called pcall cannot lend class rights',a.callback(function()
        return pcall(fPrivate);
    end)==false);
    fCheck('tail-called xpcall cannot lend class rights',a.callback(function()
        return xpcall(fPrivate,function(sError) return sError; end);
    end)==false);
    fCheck('nested external callback still denied',not pcall(a.callback,function(other)
        return (function() return other.secret; end)();
    end));
    local oCoroutine=coroutine.create(function() return a.delayed(b); end);
    local bOK,sValue=coroutine.resume(oCoroutine);
    fCheck('class coroutine can yield',bOK and sValue=='paused');
    fCheck('yield does not leak scope',not pcall(function() return b.secret; end));
    bOK,sValue=coroutine.resume(oCoroutine);
    fCheck('resume preserves lexical scope',bOK and sValue==10);
    fCheck('caught exception',not pcall(a.fail));
    fCheck('exception does not leak scope',not pcall(function() return a.secret; end));
    fCheck('table insert cannot write facade',not pcall(table.insert,a,3));
    fCheck('rawget cannot inspect hidden storage',rawget(a,'secret')==nil and next(a)==nil);
    local fGet=a.get;
    rawset(a,'secret',99);
    fCheck('raw private-name entry does not change hidden state',a.secret==99 and fGet()==10);
    rawset(a,'secret',nil);
    fCheck('removing raw private-name entry restores access denial',not pcall(function() return a.secret; end));
    rawset(a,'get',function() return 5; end);
    fCheck('raw method entry shadows public lookup only',a.get()==5 and fGet()==10);
    rawset(a,'get',nil);
    fCheck('native metatable inspection sealed',getmetatable(a)=='LXC opaque reference');
    fCheck('table identity cannot be resumed',not pcall(coroutine.resume,a));
    rawset(A,'public',true);
    fCheck('raw class entry does not enter new instances',A.public==true and not pcall(function() return A().public; end));
    rawset(A,'public',nil);
    local Helpers=LXC.class;
    rawset(LXC,'class',{});
    fCheck('raw API entry shadows lookup',not rawequal(LXC.class,Helpers));
    rawset(LXC,'class',nil);
    local fGetByName=Helpers.getbyname;
    rawset(Helpers,'getbyname',function() return A; end);
    fCheck('raw helper entry leaves captured implementation intact',Helpers.getbyname()==A and fGetByName()==nil);
    rawset(Helpers,'getbyname',nil);
    local fAssert,fRawGet,fPairs=assert,rawget,pairs;
    _G.assert=function(...) return ...; end;
    _G.rawget=function() return 10; end;
    _G.pairs=function() return function() end; end;
    local bDenied=not pcall(function() return a.secret; end);
    _G.assert,_G.rawget,_G.pairs=fAssert,fRawGet,fPairs;
    fCheck('runtime does not trust replaced global guards',bDenied);
    local tStringMeta = getmetatable('');
    local vStringIndex = tStringMeta.__index;
    tStringMeta.__index = function() error('Application string metatable invoked.'); end;
    local bLoaded, vLoadError = pcall(function()
        LXC.loadSources({['captured.lxc'] = [[namespace Captured {
            class Item { public value=4; public read() { return this.value; } }
        }]]}, tEnvironment);
        assert(tEnvironment.Captured.Item().read() == 4);
        assert(LXC.deserialize(LXC.serialize({answer=42})).answer == 42);
    end);
    tStringMeta.__index = vStringIndex;
    fCheck('runtime ignores replaced string metatable: '..tostring(vLoadError),bLoaded);
    local tDebug=_G.debug;
    _G.debug=nil;
    local bRestricted,vRestricted=pcall(function()
        local tRestricted={};
        LXC.loadSources({['restricted.lxc']=[[namespace Restricted {
            class Item {
                private value=4;
                public read() { return this.value; }
                public facilities() { return debug,_G; }
            }
        }]]},tRestricted);
        local oRestricted=tRestricted.Restricted.Item();
        local vDebug,vGlobals=oRestricted.facilities();
        return oRestricted.read()==4 and vDebug==nil and vGlobals==nil and
            not pcall(function() return oRestricted.value; end);
    end);
    _G.debug=tDebug;
    fCheck('runtime works after public debug removal',bRestricted);
    fCheck('restricted class environment exposes neither debug nor globals',vRestricted==true);
    return nChecks;
end;
