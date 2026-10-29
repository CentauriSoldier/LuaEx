--[[!
@fqxn LXC.Tests.Operators
@desc Native Lua operator/metamethod contracts through opaque instances. Covers
    both operand positions, inheritance, lifecycle hooks and access boundaries.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName, bPassed)
        assert(bPassed, sName);
        nChecks = nChecks + 1;
    end
    local tEvents = {};
    local tEnvironment = setmetatable({record = function(sEvent, vValue)
        tEvents[#tEvents + 1] = {sEvent, vValue};
    end}, {__index = _G});

    LXC.loadSources({['operators.lxc'] = [[namespace Op {
        class Number {
            private value=0;
            public Number(n) { this.value=n; }
            private static number(v) {
                if class.isinstance(v) then return v.value; end;
                return v;
            }
            public operator +(left,right) { return Number.number(left)+Number.number(right); }
            public operator -(left,right) { return Number.number(left)-Number.number(right); }
            public operator *(left,right) { return Number.number(left)*Number.number(right); }
            public operator /(left,right) { return Number.number(left)/Number.number(right); }
            public operator //(left,right) { return Number.number(left)//Number.number(right); }
            public operator %(left,right) { return Number.number(left)%Number.number(right); }
            public operator ^(left,right) { return Number.number(left)^Number.number(right); }
            public operator &(left,right) { return Number.number(left)&Number.number(right); }
            public operator |(left,right) { return Number.number(left)|Number.number(right); }
            public operator ~(left,right) { return Number.number(left)~Number.number(right); }
            public operator <<(left,right) { return Number.number(left)<<Number.number(right); }
            public operator >>(left,right) { return Number.number(left)>>Number.number(right); }
            public operator ..(left,right) { return tostring(Number.number(left))..":"..tostring(Number.number(right)); }
            public operator -() { return -this.value; }
            public operator ~() { return ~this.value; }
            public operator #() { return this.value; }
            public operator <(left,right) { return Number.number(left)<Number.number(right); }
            public operator tostring() { return "N"..this.value; }
            public operator ()(...) { return this.value,...; }
        }
        class Child : Number {
            public Child(n) { base(n); }
            public override operator +(left,right) { return base.__add(left,right)+100; }
        }
        class Missing {}
        class Other { public operator +(left,right) { return "right"; } }
        class One { private n=7; public operator +(other) { return this.n+other; } }
        class Dictionary {
            private values={};
            private secret=8;
            public final id=9;
            public Guard { get; private set; }=1;
            private class Hidden {}
            public operator [](key) { return this.values[key]; }
            public operator []=(key,value) { this.values[key]=value; }
            public operator pairs() { return next,this.values,nil; }
        }
        class Lifetime {
            private n=4;
            public operator close(e) { record("close",e); }
            public operator gc() { record("gc",this.n); }
        }
        class External {
            private secret=5;
            private read() { return this.secret; }
            public leak() { return this.read; }
            public run(other) { return this+other; }
        }
        class Snapshot {
            private n=4;
            public read() { return this.n; }
            public operator clone() { record("clone",this.n); return Snapshot(); }
            public operator serialize(state) { record("serialize",this.n); state.pri.n=8; }
            public operator deserialize(state) { record("deserialize",state.pri.n); state.pri.n=9; }
        }
        class InvalidSnapshot {
            private n=4;
            public operator serialize(state) { state.pri.n="wrong"; }
        }
    }]]}, tEnvironment);
    local A = tEnvironment.Op;
    local a,b = A.Number(6),A.Number(3);
    fCheck('addition',a+b==9);
    fCheck('right scalar addition',a+2==8);
    fCheck('left scalar addition',2+a==8);
    fCheck('subtraction order',a-b==3 and 20-a==14 and a-2==4);
    fCheck('multiplication',a*b==18 and 2*a==12);
    fCheck('division order',a/b==2 and 24/a==4);
    fCheck('floor division',a//4==1 and 20//a==3);
    fCheck('modulo',a%4==2 and 20%a==2);
    fCheck('power order',b^2==9 and 2^b==8);
    fCheck('bitwise and',a&3==2 and 3&a==2);
    fCheck('bitwise or',a|1==7 and 1|a==7);
    fCheck('bitwise xor',a~3==5 and 3~a==5);
    fCheck('shift order',b<<2==12 and 16>>b==2);
    fCheck('concatenation order',a..b=='6:3' and 'x'..a=='x:6');
    fCheck('unary minus',-a==-6);
    fCheck('unary complement',~a==~6);
    fCheck('length',#a==6);
    fCheck('less-than and reversed greater-than',b<a and a>b);
    fCheck('less-or-equal fallback',b<=a and a>=b and a<=a and not (a<=b));
    fCheck('tostring',tostring(a)=='N6');
    local n,x,y=a(11,12);
    fCheck('call preserves varargs and multiple returns',n==6 and x==11 and y==12);
    fCheck('inherited and overridden operator',A.Child(2)+3==105 and #A.Child(4)==4);
    fCheck('right class fallback when left has no operator',A.Missing()+A.Other()=='right');
    fCheck('one-operand receiver form',A.One()+2==9 and 2+A.One()==9);

    local tForeign=setmetatable({}, {__add=function(left,right) return 'foreign'; end});
    fCheck('foreign right fallback',A.Missing()+tForeign=='foreign');
    fCheck('foreign left precedence',tForeign+a=='foreign');
    local oExternal=A.External();
    local fPrivate=oExternal.leak();
    local tAttack=setmetatable({}, {__add=function() return fPrivate(); end});
    fCheck('foreign callback cannot borrow operator caller scope',not pcall(oExternal.run,tAttack));

    local d=A.Dictionary(); d.alpha=2; d[3]=false;
    fCheck('unknown index read/write',d.alpha==2 and d[3]==false);
    fCheck('missing index may return nil',d.missing==nil);
    local nEntries=0;
    for _ in pairs(d) do nEntries=nEntries+1; end
    fCheck('pairs',nEntries==2);
    fCheck('index cannot bypass private fields',not pcall(function() return d.secret; end));
    fCheck('newindex cannot bypass private fields',not pcall(function() d.secret=2; end));
    fCheck('newindex cannot bypass final fields',not pcall(function() d.id=2; end));
    fCheck('newindex cannot bypass private property setter',not pcall(function() d.Guard=2; end));
    fCheck('newindex cannot replace accessor alias',not pcall(function() d.getGuard=2; end));
    fCheck('index cannot expose nested class through wrong qualifier',not pcall(function() return d.Hidden; end));
    rawset(d,'secret',1);
    fCheck('raw decoy entry is separate from declared storage',rawget(d,'secret')==1 and getmetatable(d)=='LXC opaque reference');
    rawset(d,'secret',nil);
    fCheck('raw entry removal restores private denial',not pcall(function() return d.secret; end));

    do local resource <close> = A.Lifetime(); end
    fCheck('normal scope close',tEvents[1][1]=='close' and tEvents[1][2]==nil);
    local bOK=pcall(function() local resource <close> = A.Lifetime(); error('close-error'); end);
    fCheck('error scope close',not bOK and tEvents[2][1]=='close' and tostring(tEvents[2][2]):find('close%-error'));
    collectgarbage('collect'); collectgarbage('collect');
    local nFinalized=0;
    for _, tEvent in ipairs(tEvents) do if tEvent[1]=='gc' then nFinalized=nFinalized+1; fCheck('gc retains private access',tEvent[2]==4); end end
    fCheck('garbage collection finalizes each instance',nFinalized==2);

    local oSnapshot=A.Snapshot();
    local oCopy=LXC.clone(oSnapshot);
    fCheck('clone operator returns independent instance',not rawequal(oCopy,oSnapshot) and oCopy.read()==4);
    fCheck('clone invokes only clone hook',tEvents[#tEvents][1]=='clone');
    local sSnapshot=LXC.serialize(oSnapshot);
    fCheck('serialize operator preserves source',oSnapshot.read()==4 and tEvents[#tEvents][1]=='serialize');
    local oRestored=LXC.deserialize(sSnapshot);
    fCheck('deserialize operator applies typed projection',oRestored.read()==9 and tEvents[#tEvents][1]=='deserialize' and tEvents[#tEvents][2]==8);
    fCheck('serialization operator enforces field types',not pcall(LXC.serialize,A.InvalidSnapshot()));

    local tRejected = {
        'class A { private operator +(other) {} }',
        'class A { public static operator +(other) {} }',
        'class A { public operator +() {} }',
        'class A { public operator tostring(x) {} }',
        'class A { public operator +(other,...) {} }',
        'class A { public operator ==() {} }',
        'class A { public __metatable=1; }',
        'class A { public final operator +(other) {} } class B:A { public override operator +(other) {} }',
    };
    for nCase,sSource in ipairs(tRejected) do
        fCheck('invalid operator contract '..nCase,not pcall(LXC.loadSources,{['invalid-op.lxc']='namespace InvalidOp'..nCase..' {'..sSource..'}'},{}));
    end
    return nChecks;
end;
