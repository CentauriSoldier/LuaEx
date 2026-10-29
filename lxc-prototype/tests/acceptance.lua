--[[!
@fqxn LXC.Tests.Acceptance
@desc Cross-module acceptance cases: protected receivers, failed construction,
    initialization authority, Lua syntax, lexical names and declaration domains.
    Fixtures are in-memory and never modify framework or application files.
!]]
return function(LXC)
    local nChecks = 0;

    local function fCheck(sName, bPassed)
        assert(bPassed, sName);
        nChecks = nChecks + 1;
    end

    local tEnvironment = setmetatable({}, {__index = _G});
    LXC.loadSources({['acceptance.lxc'] = [[namespace Acceptance {
        class Base {
            protected state=1;
            public readOther(other) { return other.state; }
        }
        class Child : Base {
            public readProtected(other) { return other.state; }
            public writeProtected(other) { other.state=3; }
        }
        class Grandchild : Child {}
        class Sibling : Base {}
        class NoArguments : Base { public NoArguments() { base(); } }
        class PrivateBase { private X { get("base"); }=1; }
        class PrivateChild : PrivateBase { public X { get("child"); }=2; }
        class NameBase {
            private data=1;
            public self() { return this; }
            public readReturned() { return this.self().data; }
        }
        class NameChild : NameBase { public data=2; }
        class ArgumentBase {
            public value=0;
            public ArgumentBase(t) { this.value=t.this; }
        }
        class Arguments : ArgumentBase {
            public Arguments(field) {
                base({this=field});
                local t={base=function() this.value=this.value+1; end};
                t.base();
            }
        }
        class Final {
            public final id=null;
            public Final(fWork) { fWork(this); this.id=7; }
        }
        class Failed {
            public final id=null;
            public Failed(fWork) { fWork(this); error("expected construction failure"); }
            public run() { return 2; }
        }
        class Holder {
            private class Hidden { public Hidden() {} public value=8; }
            private object=Hidden();
            public read() { return this.object.value; }
        }
        class Syntax {
            private secret=9;
            public contextual(field,value) { return field+value; }
            private callback=function(n)
                local total=0;
                for i=1,n do total=total+i; end;
                if total>2 then return total; else return 0; end;
            end;
            public callInitializer() { return this.callback(3); }
            public run() {
                local t={field=1, get=2, ["x"]=3};
                function t.add(a,b) return a+b; end;
                function t:mul(a) return self.x*a; end;
                local n=0x1p+2 + .5 + 1e-1;
                local function recurse(i)
                    if i==0 then return this.secret; end;
                    return recurse(i-1);
                end;
                for i=1,3 do n=n+i; end;
                for _,v in ipairs({1,2}) do n=n+v; end;
                do local n<const> =4; t.x=n; end;
                repeat local stop=true; n=n+1; until stop;
                while n<15 do n=n+1; end;
                if n>20 then n=0; elseif n>10 then n=n+1; else n=2; end;
                ::done::
                if false then goto done; end;
                return recurse(2),t.add(2,3),t:mul(2),"field } this.secret",[=[long {]=];
            }
            public Value {
                get { local t={field=3}; return field+t.field; }
                set { local t={value=value}; field=t.value; }
            }=1;
        }
    }]]}, tEnvironment);

    local A = tEnvironment.Acceptance;
    local oBase, oChild, oGrandchild, oSibling = A.Base(), A.Child(), A.Grandchild(), A.Sibling();
    fCheck('declaring class protected access across base receivers', oBase.readOther(oSibling) == 1);
    fCheck('derived protected access through own receiver', oChild.readProtected(oChild) == 1);
    fCheck('derived protected access through descendant receiver', oChild.readProtected(oGrandchild) == 1);
    fCheck('derived cannot read protected base receiver', not pcall(oChild.readProtected, oBase));
    fCheck('derived cannot read protected sibling receiver', not pcall(oChild.readProtected, oSibling));
    fCheck('derived cannot write protected sibling receiver', not pcall(oChild.writeProtected, oSibling));
    oChild.writeProtected(oGrandchild);
    fCheck('authorized protected assignment', oGrandchild.readOther(oGrandchild) == 3);
    local oPrivate=A.PrivateChild();
    fCheck('private property name reuse has independent storage',oPrivate.childX()==2);
    fCheck('private inherited alias does not switch declarations',not pcall(function() return oPrivate.baseX(); end));
    fCheck('public fast path preserves base private lookup on returned receiver',A.NameChild().readReturned()==1);
    fCheck('constructor analysis distinguishes table keys and ordinary parameter names',A.Arguments(5).value==6);
    fCheck('explicit parameterless parent constructor',A.NoArguments().readOther(oBase)==1);

    local bDenied;
    local oFinal = A.Final(function(other) bDenied = not pcall(function() other.id=6; end); end);
    fCheck('callback cannot initialize final binding', bDenied and oFinal.id == 7);
    local oLeaked;
    fCheck('constructor failure propagates', not pcall(A.Failed, function(other) oLeaked=other; end));
    fCheck('failed instance fields inaccessible', not pcall(function() return oLeaked.id; end));
    fCheck('failed instance methods inaccessible', not pcall(function() return oLeaked.run(); end));
    fCheck('failed instance cannot be saved', not pcall(LXC.serialize, oLeaked));
    fCheck('private construction from initializer retains context', A.Holder().read() == 8);

    local oSyntax = A.Syntax();
    fCheck('contextual accessor names remain ordinary method parameters',oSyntax.contextual(2,3)==5);
    fCheck('function initializer retains Lua block semicolons', oSyntax.callInitializer()==6);
    local a,b,c,d,e = oSyntax.run();
    fCheck('Lua scope and syntax corpus', a==9 and b==5 and c==8 and d=='field } this.secret' and e=='long {');
    fCheck('accessor table keys are not backing references', oSyntax.Value==4);
    oSyntax.Value=5;
    fCheck('accessor field and ordinary table selectors differ', oSyntax.Value==8);

    local tImports = setmetatable({}, {__index = _G});
    local sImports = [[namespace ImportsOne { class Shared {} }
        namespace ImportsTwo { class Shared {} }
        namespace ImportsUser { using ImportsOne; using ImportsTwo;
            class LocalNames {
                public run(Shared) { return Shared.value; }
                public localNames() {
                    local Shared={value=2};
                    do local Shared={value=3}; assert(Shared.value==3); end;
                    local function f(Shared) return Shared.value; end;
                    return f(Shared);
                }
                public fieldKeys() { return {Shared=1}.Shared; }
            }
        }]];
    -- Parenthesize a table constructor before selecting a field in Lua.
    sImports = string.gsub(sImports, 'return {Shared=1}.Shared', 'return ({Shared=1}).Shared');
    LXC.loadSources({['locals.lxc']=sImports}, tImports);
    local oLocals=tImports.ImportsUser.LocalNames();
    fCheck('parameter shadows ambiguous class', oLocals.run({value=4})==4);
    fCheck('locals and nested parameters shadow ambiguous class', oLocals.localNames()==2);
    fCheck('table keys do not resolve class names', oLocals.fieldKeys()==1);
    fCheck('ambiguous body reference fails before publication', not pcall(LXC.loadSources, {
        ['ambiguous-body.lxc']=[[namespace ImportsUser { using ImportsOne; using ImportsTwo;
            class Ambiguous { public run() { return Shared(); } }
        }]]}, tImports) and tImports.ImportsUser.Ambiguous==nil);

    local tCases = {
        {'nested type hiding', 'class A { public class T {} } class B : A { public class T {} }'},
        {'field hiding nested type', 'class A { public class T {} } class B : A { public T=1; }'},
        {'accessor hiding method', 'class A { public getX() {} } class B : A { public X { get; }=1; }'},
        {'same getter/setter alias', 'class A { public X { get("read"); set("read"); }=1; }'},
        {'reserved generated accessor name', 'class A { public oto { get("g"); }=1; }'},
        {'null declaration cannot hide placeholder', 'class null {}'},
        {'public derived private base', 'class Outer { private class Base {} public class Child : Base {} }'},
    };
    for n, tCase in ipairs(tCases) do
        fCheck(tCase[1], not pcall(LXC.loadSources, {['reject.lxc']='namespace Reject'..n..' {'..tCase[2]..'}'}, {}));
    end

    local tDomain={};
    LXC.loadSources({['domains.lxc']=[[namespace Domains {
        class Outer {
            private class Base { protected Base() {} }
            private class Group { private class Child : Base {} }
        }
    }]]}, tDomain);
    fCheck('nested private domain may derive private base', tDomain.Domains.Outer~=nil);
    local tDepthSources={'namespace Depth {'};
    for n=0,299 do
        tDepthSources[#tDepthSources+1]=string.format('class Node%03d : Node%03d {}',n,n+1);
    end
    tDepthSources[#tDepthSources+1]='class Node300 { public value=1; } }';
    local tDepthEnvironment={};
    local tDepthOrder=LXC.loadSources({['depth.lxc']=table.concat(tDepthSources,'\n')},tDepthEnvironment);
    fCheck('deep ancestry uses no per-class protected-call stack',#tDepthOrder==301 and tDepthEnvironment.Depth.Node000().value==1);
    return nChecks;
end;
