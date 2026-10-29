--[[!
@fqxn LXC.Tests.Language
@desc Exercises approved declaration behavior through public operations: ancestor
    calls, shared statics, polymorphic slots, properties and metadata helpers.
!]]
return function(LXC)
    local nChecks=0;

    local function fCheck(sName,bPassed)
        assert(bPassed,sName);
        nChecks=nChecks+1;
    end

    local tEnvironment=setmetatable({}, {__index=_G});
    LXC.loadSources({['language.lxc']=[[namespace Language {
        class Base permits(Language.Child) {
            private static hidden=4;
            public static count=1;
            public static final seed=null;
            public static const settings={enabled=true};
            static Base() { Base.seed=12; }
            public value=1;
            public final items={};
            public run() { return "base"; }
            public dispatch() { return this.run(); }
            public static readHidden() { return Base.hidden; }
        }
        class Child : Base {
            public override run() { return base.run().."/child"; }
        }
        class Leaf : Child {
            public override run() { return base.run().."/leaf"; }
        }
        class Holder {
            public target=Base();
            public replace(other) { this.target=other; }
        }
        class Property {
            public Value { get; private set; }=2;
            public ReadOnly { get; }={};
            public final Id { get; set; }=5;
            public Count { get; set; }=1;
            public setInternally(n) { this.Value=n; }
            public static Ready { get("is"); set("change"); }=true;
        }
        class Deny excludes(Language.Blocked) {}
        class Types {
            public class Token {}
            protected class Hidden { public Hidden() {} public value=4; }
        }
        class UseTypes : Types { public make() { return Hidden(); } }
        class Qualified : Types.Token {}
    }]]},tEnvironment);

    local A=tEnvironment.Language;
    local oLeaf=A.Leaf();
    fCheck('multi-level ancestor calls',oLeaf.run()=='base/child/leaf');
    fCheck('base method dispatches concrete override',oLeaf.dispatch()=='base/child/leaf');
    fCheck('indirect child unaffected by direct permits list',LXC.class.ischild(A.Leaf,A.Base));
    fCheck('inherited static initially shared',A.Child.count==A.Base.count);
    A.Leaf.count=7;
    fCheck('descendant static writes declaring storage',A.Base.count==7 and A.Child.count==7);
    fCheck('inherited static method retains declaring rights',A.Leaf.readHidden()==4);
    fCheck('static final initialized in static constructor',A.Base.seed==12);
    fCheck('static final second write rejected',not pcall(function() A.Child.seed=13; end));
    A.Base.settings.enabled=false;
    fCheck('const table contents remain mutable',A.Child.settings.enabled==false);
    fCheck('const table cannot be rebound',not pcall(function() A.Base.settings={}; end));
    oLeaf.items[1]=true;
    fCheck('final table contents remain mutable',oLeaf.items[1]==true);
    fCheck('final table cannot be rebound',not pcall(function() oLeaf.items={}; end));

    local oHolder=A.Holder();
    oHolder.replace(oLeaf);
    oHolder.replace(A.Base());
    fCheck('polymorphic assignment preserves original base constraint',LXC.class.isinstanceof(oHolder.target,A.Base));
    fCheck('polymorphic field rejects unrelated instance',not pcall(oHolder.replace,A.Property()));
    oHolder.replace(oLeaf);
    local sNarrowed,nChanges=string.gsub(LXC.serialize(oHolder), '"Type"%]="Language%.Base"', '"Type"]="Language.Leaf"');
    fCheck('saved constructor type constraint cannot be narrowed',nChanges>0 and not pcall(LXC.deserialize,sNarrowed));
    local oProperty=A.Property();
    fCheck('automatic getter aliases direct reads',oProperty.Value==2 and oProperty.getValue()==2);
    fCheck('private setter direct access denied',not pcall(function() oProperty.Value=4; end));
    fCheck('private setter named access denied',not pcall(function() oProperty.setValue(4); end));
    oProperty.setInternally(6);
    fCheck('declaring method can use private setter',oProperty.Value==6);
    fCheck('getter-only rejects direct writes',not pcall(function() oProperty.ReadOnly={}; end));
    oProperty.ReadOnly.changed=true;
    fCheck('getter-only does not lock returned table',oProperty.ReadOnly.changed==true);
    fCheck('final property preserves binding lock',not pcall(function() oProperty.Id=6; end));
    fCheck('automatic property enforces storage type',not pcall(function() oProperty.Count='wrong'; end));
    fCheck('static custom prefix getter',A.Property.isReady()==true);
    A.Property.changeReady(false);
    fCheck('static custom prefix setter',A.Property.Ready==false);

    fCheck('helper exact instance relation',LXC.class.isinstanceof(oLeaf,A.Leaf) and not LXC.class.isinstanceof(oLeaf,A.Base));
    fCheck('helper inclusive ancestry relation',LXC.class.isa(oLeaf,A.Base));
    fCheck('helper parent name',LXC.class.getparentname(A.Leaf)=='Language.Child');
    fCheck('helper root base name',LXC.class.getbasename(A.Leaf)=='Language.Base');
    fCheck('helper reference requires name',LXC.class.getbyname(A.Leaf)==nil);
    fCheck('helper registered reference',LXC.class.getbyname('Language.Leaf')==A.Leaf);
    local tNames=LXC.class.getchildnames(A.Base);
    tNames[1]='modified';
    fCheck('helper child names are independent metadata',LXC.class.getchildnames(A.Base)[1]=='Language.Child');

    fCheck('permits rejects unlisted direct child',not pcall(LXC.loadSources,{
        ['not-permitted.lxc']='namespace Language { class Other : Base {} }'},tEnvironment));
    fCheck('excludes rejects listed direct child',not pcall(LXC.loadSources,{
        ['excluded.lxc']='namespace Language { class Blocked : Deny {} }'},tEnvironment));
    LXC.loadSources({['allowed.lxc']='namespace Language { class Allowed : Deny {} }'},tEnvironment);
    fCheck('excludes allows other direct child',A.Allowed~=nil);
    fCheck('inherited nested types resolve in derived methods',A.UseTypes().make().value==4);
    fCheck('relative qualified base resolves through namespace',LXC.class.isa(A.Qualified(),A.Types.Token));
    return nChecks;
end;
