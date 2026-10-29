--[[!
@fqxn LXC.Tests.Contracts
@desc Positive and negative source contracts, evaluated in one isolated runtime.
    Sources live in memory; no fixture files or user files are modified.
!]]
return function(LXC)
    local nChecks, nFixture = 0, 0;

    local function fCheck(sName, bPassed)
        assert(bPassed, sName); nChecks = nChecks + 1;
    end

    local function fCompile(sSource)
        nFixture = nFixture + 1;
        local tEnvironment = setmetatable({}, {__index = _G});
        local sNamespace = 'Case'..nFixture;
        local bOK, vResult = pcall(LXC.loadSources, {['case'..nFixture..'.lxc'] =
            'namespace '..sNamespace..' { '..sSource..' }'}, tEnvironment);
        return bOK, vResult, tEnvironment[sNamespace], tEnvironment;
    end

    local function fRejects(sName, sSource, sMessage)
        local bOK, vResult, tPublished = fCompile(sSource);
        fCheck(sName, not bOK and tostring(vResult):find(sMessage, 1, true) ~= nil);
        fCheck(sName..' does not publish', tPublished == nil);
    end

    fRejects('final classes', 'final class A {} class B : A {}', 'final class');
    fRejects('inheritance cycle', 'class A : B {} class B : A {}', 'cycle');
    fRejects('missing parent', 'class A : Missing {}', 'Missing parent');
    fRejects('duplicate classes', 'class A {} class A {}', 'Duplicate class');
    fRejects('abstract concrete class', 'class A { public abstract run(); }', 'abstract class');
    fRejects('unimplemented abstraction', 'abstract class A { public abstract run(); } class B : A {}', 'abstract methods');
    fRejects('private abstract method', 'abstract class A { abstract run(); }', 'private');
    fRejects('missing override', 'class A { public run() {} } class B : A { public run() {} }', 'override');
    fRejects('orphan override', 'class A { public override run() {} }', 'override target');
    fRejects('final override', 'class A { public final run() {} } class B : A { public override run() {} }', 'final');
    fRejects('parameter count', 'class A { public run(a) {} } class B : A { public override run() {} }', 'parameter');
    fRejects('variadic status', 'class A { public run(a, ...) {} } class B : A { public override run(a) {} }', 'parameter');
    fRejects('visibility override', 'class A { public run() {} } class B : A { protected override run() {} }', 'visibility');
    fRejects('field hiding', 'class A { public x=1; } class B : A { public x=2; }', 'hiding');
    fRejects('static hiding', 'class A { public static x=1; } class B : A { public static x=2; }', 'hiding');
    fRejects('mixed lists', 'class A permits(X.B) excludes(X.C) {}', 'combine');
    fRejects('empty list', 'class A permits() {}', 'Empty');
    fRejects('unqualified list', 'class A permits(B) {}', 'fully qualified');
    fRejects('constructor overload', 'class A { public A() {} public A(a) {} }', 'Duplicate constructor');
    fRejects('late parent call', 'class A {} class B : A { public B() { local a=1; base(); } }', 'first');
    fRejects('duplicate parent call', 'class A {} class B : A { public B() { base(); base(); } }', 'first');
    fRejects('root base call', 'class A { public A() { base(); } }', 'no parent');
    fRejects('private parent constructor', 'class A { private A() {} } class B : A {}', 'parent constructor');
    fRejects('static constructor arguments', 'class A { static A(a) {} }', 'parameterless');
    fRejects('const null', 'class A { public static const x=null; }', 'Const');
    fRejects('static uninitialized final', 'class A { public static final x=null; }', 'Uninitialized final');
    fRejects('invalid Lua', 'class A { public run() { local x=; } }', 'case');
    fRejects('compiler environment escape', 'class A { public run() { return _ENV; } }', 'Reserved');
    fRejects('property prefix override', 'class A { public X { get("read"); }=1; } class B : A { public override X { get("get"); } }', 'prefix');
    fRejects('property accessor removal', 'class A { public X { get; set; }=1; } class B : A { public override X { get; } }', 'accessor set');
    fRejects('property visibility widening', 'class A { private X { public get; }=1; }', 'widen');
    fRejects('generated method collision', 'class A { public X { get; }=1; public getX() {} }', 'collision');

    local bOK, sError, tClasses = fCompile([[
        abstract class Base { public abstract run(a, ...); }
        abstract class Middle : Base {}
        class Leaf : Middle { public override run(renamed, ...) { return renamed, ...; } }
    ]]);
    fCheck('abstract chain compiles', bOK or error(sError));
    fCheck('abstract creation denied', not pcall(tClasses.Base));
    fCheck('abstract implementation dispatch', tClasses.Leaf().run(7) == 7);

    bOK, sError, tClasses = fCompile([[
        class A {
            private x=1; public final y=null; public z=null; public flag=false;
            public A() { this.y=9; this.z=4; }
            public read() { return this.x; }
            public assignY(v) { this.y=v; }
            public assignZ(v) { this.z=v; }
        }
        class B : A { private x=2; public own() { return this.x; } }
    ]]);
    fCheck('field constraints compile', bOK or error(sError));
    local oObject = tClasses.B();
    fCheck('private state ownership', oObject.read() == 1 and oObject.own() == 2);
    fCheck('false retained', oObject.flag == false);
    fCheck('final initialized', oObject.y == 9);
    fCheck('final second assignment', not pcall(oObject.assignY, 10));
    fCheck('typed null reset denied', not pcall(oObject.assignZ, LXC.null));
    fCheck('nil write denied', not pcall(oObject.assignZ, nil));
    fCheck('field type enforced', not pcall(oObject.assignZ, 'wrong'));

    bOK, sError, tClasses = fCompile([[
        class Outer {
            private secret=4;
            private class Inner {
                private own=8;
                public Inner() {}
                public readOuter(other) { return other.secret; }
                public read() { return this.own; }
            }
            private class Sibling {
                public Sibling() {}
                public steal(other) { return other.own; }
            }
            public make() { return Inner(); }
            public makeSibling() { return Sibling(); }
            public leak() { return Inner; }
            public steal(other) { return other.own; }
        }
    ]]);
    fCheck('nested declarations compile', bOK or error(sError));
    local oOuter = tClasses.Outer();
    local oInner = oOuter.make();
    fCheck('private returned instance public behavior', oInner.read() == 8);
    fCheck('nested reads enclosing state', oInner.readOuter(oOuter) == 4);
    fCheck('outer cannot read nested private', not pcall(oOuter.steal, oInner));
    fCheck('siblings cannot read private', not pcall(oOuter.makeSibling().steal, oInner));
    fCheck('external nested class lookup denied', not pcall(function() return tClasses.Outer.Inner; end));
    fCheck('escaped class cannot be constructed', not pcall(oOuter.leak()));
    fCheck('helper does not recover private class', LXC.class.getbyname(LXC.class.getname(oInner)) == nil);
    fCheck('restored private object retains public behavior', LXC.deserialize(LXC.serialize(oInner)).read() == 8);

    bOK, sError, tClasses = fCompile([[
        class A {
            public Health { get("read"); set { field=value; } }=1;
        }
        class B : A {
            public override Health { get { return field*2; } set { field=value+1; } }
            public baseRead() { return base.Health; }
        }
    ]]);
    fCheck('property override compiles', bOK or error(sError));
    local oProperty = tClasses.B(); oProperty.Health = 4;
    fCheck('property shared storage', oProperty.Health == 10 and oProperty.baseRead() == 5);
    fCheck('inherited prefix dispatch', oProperty.readHealth() == 10);
    oProperty.setHealth(6);
    fCheck('named setter custom behavior', oProperty.Health == 14 and oProperty.baseRead() == 7);

    return nChecks;
end;
