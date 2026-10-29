--[[!
@fqxn LXC.Tests.Persistence
@desc Graph identity, data validation, explicit static state and failure isolation.
!]]
return function(LXC)
    local nChecks = 0;
    local function fCheck(sName, bPassed) assert(bPassed, sName); nChecks = nChecks + 1; end
    -- Persistence is a host capability, supplied deliberately for this fixture.
    local tEnvironment = setmetatable({LXC = LXC}, {__index = _G});
    LXC.loadSources({['persistence.lxc'] = [[namespace Saved {
        class Item {
            public static count=0;
            public static const limit=10;
            private static hidden=5;
            public flag=false;
            public name="start";
            public optional=null;
            public final id=null;
            public values={};
            public Item(nId) { this.id=nId; Item.count=Item.count+1; }
            public changeName(sName) { this.name=sName; }
            public setSelf() { this.optional=this; }
            public static hiddenSave() { return LXC.saveStatic(Item); }
            public static hiddenLoad(sData) { LXC.loadStatic(Item,sData); }
            public static getHidden() { return Item.hidden; }
            public static setHidden(nValue) { Item.hidden=nValue; }
        }
        class FactoryHolder {
            private class Hidden { public Hidden() {} public value=8; }
            private factory=Hidden;
            public exposed=null;
            public make() { return this.factory(); }
            public leak() { return this.factory; }
        }
        class OtherHolder { private data=null; public leak() { return this.data; } }
    }]]}, tEnvironment);
    local Item = tEnvironment.Saved.Item;
    local oItem = Item(42); oItem.name = 'binary\0\255'; oItem.setSelf();
    oItem.values.object, oItem.values.same = oItem, oItem;
    local sSave = LXC.serialize(oItem);
    local oRestored = LXC.deserialize(sSave);
    fCheck('class cycle restored', oRestored.optional == oRestored);
    fCheck('nested cycle restored', oRestored.values.object == oRestored and oRestored.values.same == oRestored);
    fCheck('false and binary strings restored', oRestored.flag == false and oRestored.name == oItem.name);
    fCheck('constructor not rerun', Item.count == 1);
    fCheck('final lock restored', not pcall(function() oRestored.id=43; end));
    fCheck('type contract restored', not pcall(function() oRestored.name=1; end));
    fCheck('separate restore graphs', LXC.deserialize(sSave) ~= oRestored);
    fCheck('shared class references', LXC.deserialize(LXC.serialize({Item,Item}))[1] == Item);
    local tKey = {}; local tRoot = {[tKey]=tKey}; tRoot.self=tRoot;
    local tClone = LXC.clone(tRoot);
    local oKey; for k in pairs(tClone) do if (type(k)=='table') then oKey=k; end end
    fCheck('table keys preserve graph aliases', oKey ~= tKey and tClone[oKey] == oKey and tClone.self == tClone);
    local tCopy = LXC.clone(oItem); tCopy.values.new = true;
    fCheck('clone owns independent mutable state', not oItem.values.new and tCopy.optional == tCopy);
    local sStatics = LXC.saveStatic(Item); Item.count=9;
    LXC.loadStatic(Item,sStatics);
    fCheck('explicit mutable static restoration', Item.count==1 and Item.limit==10);
    Item.setHidden(20); LXC.loadStatic(Item,sStatics);
    fCheck('external static saves exclude private state', Item.getHidden()==20);
    local sPrivate = Item.hiddenSave(); Item.setHidden(30); Item.hiddenLoad(sPrivate);
    fCheck('declaring static context preserves private state', Item.getHidden()==20);
    fCheck('native function rejected', not pcall(LXC.serialize,print));
    fCheck('Lua closure rejected explicitly', not pcall(LXC.serialize,function() end));
    fCheck('foreign coroutine rejected', not pcall(LXC.serialize,coroutine.create(function() end)));
    fCheck('nonfinite rejected explicitly', not pcall(LXC.serialize,math.huge));
    fCheck('snapshot execution rejected', not pcall(LXC.deserialize,'(function() return 1 end)()'));
    fCheck('trailing snapshot code rejected', not pcall(LXC.deserialize,sSave..'; return 1'));
    fCheck('incompatible saved type rejected', not pcall(LXC.deserialize,(sSave:gsub('"Type"%]="string"','"Type"]="number"'))));
    fCheck('unknown graph field rejected', not pcall(LXC.deserialize,'{["Version"]=1,["Nodes"]={},["Root"]={},["Extra"]=1,}'));
    fCheck('nil root round trip', LXC.deserialize(LXC.serialize(nil))==nil);
    fCheck('null identity round trip', LXC.deserialize(LXC.serialize(LXC.null))==LXC.null);
    fCheck('negative decimal round trip', LXC.deserialize(LXC.serialize(-0.125)) == -0.125);

    local nNext=0;
    tEnvironment.nextId=function() nNext=nNext+1; return nNext; end;
    LXC.loadSources({['dynamic.lxc']=[[namespace Saved {
        class Dynamic { public const id=nextId(); public flag="a"=="a"; }
    }]]},tEnvironment);
    local oFirst,oSecond=tEnvironment.Saved.Dynamic(),tEnvironment.Saved.Dynamic();
    fCheck('dynamic const values remain per instance',LXC.clone(oFirst).id==1 and LXC.clone(oSecond).id==2);
    fCheck('expression initializer type is not guessed from first token',LXC.clone(oFirst).flag==true);
    fCheck('integer precision round trip',LXC.deserialize(LXC.serialize(math.maxinteger))==math.maxinteger);
    fCheck('table metatables rejected explicitly',not pcall(LXC.serialize,setmetatable({},{__index={}})));
    fCheck('invalid reference rejected',not pcall(LXC.deserialize,'{["Version"]=1,["Nodes"]={},["Root"]={["Ref"]=1,},}'));
    local oFactory=LXC.clone(tEnvironment.Saved.FactoryHolder());
    fCheck('private class reference survives encapsulated instance state',oFactory.make().value==8);
    fCheck('private factory cannot be saved as an exposed root',not pcall(LXC.serialize,oFactory.leak()));
    fCheck('private factory cannot be saved through an exposed table',not pcall(LXC.serialize,{oFactory.leak()}));
    fCheck('private factory cannot be restored as an exposed root',not pcall(LXC.deserialize,
        '{["Version"]=1,["Root"]={["Ref"]=1,},["Nodes"]={[1]={["Kind"]="class",["Class"]="Saved.FactoryHolder.Hidden",},},}'));
    local sRef='{["Value"]={["Ref"]=2,},["Type"]="class",["ClassType"]=false,["Locked"]=false,}';
    local sHidden='[2]={["Kind"]="class",["Class"]="Saved.FactoryHolder.Hidden",},';
    local sForged='{["Version"]=1,["Root"]={["Ref"]=1,},["Nodes"]={[1]={["Kind"]="instance",["Class"]="Saved.OtherHolder",'..
        '["Fields"]={["Saved.OtherHolder:data"]='..sRef..',},},'..sHidden..'},}';
    fCheck('snapshot cannot transplant hidden factory into unrelated private state',not pcall(LXC.deserialize,sForged));
    sForged='{["Version"]=1,["Root"]={["Ref"]=1,},["Nodes"]={[1]={["Kind"]="instance",["Class"]="Saved.FactoryHolder",'..
        '["Fields"]={["Saved.FactoryHolder:factory"]='..sRef..',["Saved.FactoryHolder:exposed"]='..sRef..',},},'..sHidden..'},}';
    fCheck('snapshot cannot move hidden factory to a public slot',not pcall(LXC.deserialize,sForged));
    local tDeep,tTail={},nil;
    tTail=tDeep;
    for _=1,2000 do tTail.next={}; tTail=tTail.next; end
    tTail.root=tDeep;
    local tDeepCopy=LXC.deserialize(LXC.serialize(tDeep));
    tTail=tDeepCopy;
    for _=1,2000 do tTail=tTail.next; end
    fCheck('deep graph round trip avoids recursive graph traversal',tTail.root==tDeepCopy);
    return nChecks;
end;
