--[[!
@fqxn LXC.Helpers
@desc Builds a scope-aware read-only helper API. Metadata returns names/booleans;
    class references require current use-site visibility, not possession alone.
!]]
return function(Model, Context, Runtime, Facades)
    local __lxc_guard <close> = nil;
    local tClasses, tObjects = Runtime.services();
    local tMethods = {};

    --[[!
    @fqxn LXC.Helpers.resolve
    @desc Finds an internal class identity from a registered reference, instance or qualified name.
    !]]
    local function fResolve(vValue)
        local __lxc_guard <close> = nil;
        return tClasses[vValue] or (tObjects[vValue] and tObjects[vValue].Class) or
            (type(vValue) == 'string' and Model.Classes[vValue]) or nil;
    end

    --[[!
    @fqxn LXC.Helpers.visible
    @desc Filters class metadata/reference queries by lifecycle and current lexical use-site visibility.
    !]]
    local function fVisible(vValue)
        local __lxc_guard <close> = nil;
        local tClass = fResolve(vValue);
        local tCaller = Context.caller();
        if (tClass and not tClass.Discarded and (tClass.Published or (tCaller and tCaller.Batch == tClass.Batch)) and
            Model.visible(tClass, tCaller)) then return tClass; end
    end
    Context.internal(fVisible);

    --[[!
    @fqxn LXC.Helpers.getname
    @desc Names are metadata, never a route to hidden class references. Holding an
        instance permits its exact type name, but does not authorize class lookup.
    !]]
    tMethods.getname = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tClass = tObjects[vValue] and tObjects[vValue].Class or fVisible(vValue);
        return tClass and tClass.FullName or nil;
    end);
    --[[!
    @fqxn LXC.Helpers.is
    @desc Reports whether a value is a class identity; supplies no reference or construction authority.
    !]]
    tMethods.is = function(vValue)
        local __lxc_guard <close> = nil;
        return tClasses[vValue] ~= nil;
    end;
    --[[!
    @fqxn LXC.Helpers.isinstance
    @desc Reports whether a value is an instance identity without inspecting its private state.
    !]]
    tMethods.isinstance = function(vValue)
        local __lxc_guard <close> = nil;
        return tObjects[vValue] ~= nil;
    end;
    --[[!
    @fqxn LXC.Helpers.exists
    @desc Reports whether the caller can access the resolved live class.
    !]]
    tMethods.exists = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        return fVisible(vValue) ~= nil;
    end);
    --[[!
    @fqxn LXC.Helpers.getbyname
    @desc Returns a registered class reference only for a string name visible in the using scope.
    !]]
    tMethods.getbyname = Context.internal(function(sName)
        local __lxc_guard <close> = nil;
        if (type(sName) ~= 'string') then return nil; end
        local tClass = fVisible(sName); return tClass and tClass.Object or nil;
    end);
    --[[!
    @fqxn LXC.Helpers.isinstanceof
    @desc Checks exact instance identity against a visible class; descendants do not satisfy this query.
    !]]
    tMethods.isinstanceof = Context.internal(function(oObject, vClass)
        local __lxc_guard <close> = nil;
        local tClass = fVisible(vClass);
        return tClass ~= nil and tObjects[oObject] ~= nil and tObjects[oObject].Class == tClass;
    end);
    --[[!
    @fqxn LXC.Helpers.isa
    @desc Checks whether an instance belongs to a visible class or any descendant of that class.
    !]]
    tMethods.isa = Context.internal(function(oObject, vClass)
        local __lxc_guard <close> = nil;
        local tClass = fVisible(vClass);
        return tClass ~= nil and tObjects[oObject] ~= nil and Model.descends(tObjects[oObject].Class, tClass);
    end);
    --[[!
    @fqxn LXC.Helpers.ischild
    @desc Checks strict ancestry between visible classes; a class is not its own child.
    !]]
    tMethods.ischild = Context.internal(function(vChild, vParent)
        local __lxc_guard <close> = nil;
        local tChild, tParent = fVisible(vChild), fVisible(vParent);
        return tChild ~= nil and tParent ~= nil and tChild ~= tParent and Model.descends(tChild, tParent);
    end);
    --[[!
    @fqxn LXC.Helpers.getparentname
    @desc Returns the visible immediate parent name or nil, never its factory reference.
    !]]
    tMethods.getparentname = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tClass = fVisible(vValue);
        return tClass and tClass.Parent and fVisible(tClass.Parent.Object) and tClass.Parent.FullName or nil;
    end);
    --[[!
    @fqxn LXC.Helpers.getbasename
    @desc Returns the visible root ancestor name or nil without exposing a hidden class reference.
    !]]
    tMethods.getbasename = Context.internal(function(vValue)

           local __lxc_guard <close> = nil;
        local tClass = fVisible(vValue);
        if (not tClass) then return nil; end
        while (tClass.Parent) do tClass = tClass.Parent; end
        return fVisible(tClass.Object) and tClass.FullName or nil;
    end);
    --[[!
    @fqxn LXC.Helpers.getchildnames
    @desc Returns a fresh sorted list of visible direct-child names; mutations cannot change registry state.
    !]]
    tMethods.getchildnames = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tClass, tNames = fVisible(vValue), {};
        if (not tClass) then return nil; end
        for _, tChild in pairs(Model.Classes) do
            if (tChild.Parent == tClass and fVisible(tChild.Object)) then tNames[#tNames + 1] = tChild.FullName; end
        end
        table.sort(tNames); return tNames;
    end);

    for _, fMethod in pairs(tMethods) do Context.internal(fMethod); end
    return Facades.create({__index = function(sName)
        local __lxc_guard <close> = nil;
        return tMethods[sName];
    end,
        __newindex = function()
            local __lxc_guard <close> = nil;
            error('Class helpers are read-only.');
        end});
end;
