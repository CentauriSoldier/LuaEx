--[[!
@fqxn LuaEx.LXC.Helpers
@desc <h3>Helpers — responsibility and connections</h3><p>Implements the read-only class helper object exposed
    as LXC.class and, after host binding, global class. Model supplies names, visibility and ancestry; Context
    supplies the actual caller. The helpers recognize LXC classes and instances, not objects made by legacy
    lib/class.lua.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Helpers.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Model Private injected dependency; its role is described in the module map.
@param table Context Private injected dependency; its role is described in the module map.
@param table Runtime Private injected dependency; its role is described in the module map.
@param table Facades Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Model, Context, Runtime, Facades)
    local __lxc_guard <close> = nil;
    local tClasses, tObjects = Runtime.services();
    local tMethods = {};

    
    --[[!
    @fqxn LuaEx.LXC.Helpers.resolve
    @desc Identifies a definition from an LXC class, instance or exact published qualified name. This raw lookup
        does not check access; fVisible adds usability checks.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret table|nil tClass Raw definition or nil.
    @vis internal
    !]]
    local function fResolve(vValue)
        local __lxc_guard <close> = nil;
        return tClasses[vValue] or (tObjects[vValue] and tObjects[vValue].Class) or
            (type(vValue) == 'string' and Model.Classes[vValue]) or nil;
    end

    
    --[[!
    @fqxn LuaEx.LXC.Helpers.visible
    @desc Requires a non-discarded class, publication or the caller's current batch, and complete nested
        visibility. Unknown/inaccessible values produce nil.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret table|nil tClass Usable visible definition.
    @vis internal
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
    @fqxn LuaEx.LXC.class.getname
    @desc Returns an instance's concrete qualified class name, or a visible class/name input's name. Knowing an
        instance's name does not expose its class object.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret string|nil sName Qualified name or nil.
    @pulsarlua function class.getname
    !]]
    tMethods.getname = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tClass = tObjects[vValue] and tObjects[vValue].Class or fVisible(vValue);
        return tClass and tClass.FullName or nil;
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.is
    @desc Recognizes class-object identity in the registry without granting visibility or checking publication.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret boolean bClass Whether the value is a registered class object.
    @pulsarlua function class.is
    !]]
    tMethods.is = function(vValue)
        local __lxc_guard <close> = nil;
        return tClasses[vValue] ~= nil;
    end;
    
    --[[!
    @fqxn LuaEx.LXC.class.isinstance
    @desc Recognizes instance identity without checking readiness or exposing storage.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret boolean bInstance Whether the value is a registered instance.
    @pulsarlua function class.isinstance
    !]]
    tMethods.isinstance = function(vValue)
        local __lxc_guard <close> = nil;
        return tObjects[vValue] ~= nil;
    end;
    
    --[[!
    @fqxn LuaEx.LXC.class.exists
    @desc Tests whether a class/instance/name input resolves to a usable class visible from the actual caller.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret boolean bExists Whether a visible class exists.
    @pulsarlua function class.exists
    !]]
    tMethods.exists = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        return fVisible(vValue) ~= nil;
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.getbyname
    @desc Returns a class object for an exact visible qualified name; non-string, unknown or inaccessible inputs
        yield nil. Unlike legacy class lookup, this takes no environment argument.
    @param string sName Name/path to resolve or inspect under the lookup rules described above.
    @ret table|nil oClass Visible class or nil.
    @pulsarlua function class.getbyname
    !]]
    tMethods.getbyname = Context.internal(function(sName)
        local __lxc_guard <close> = nil;
        if (type(sName) ~= 'string') then return nil; end
        local tClass = fVisible(sName); return tClass and tClass.Object or nil;
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.isinstanceof
    @desc Tests exact concrete identity after resolving an accessible class input. Descendant instances do not
        satisfy this exact-class test.
    @param any oObject Candidate LXC instance.
    @param any vClass Class object, instance or exact qualified name, subject to caller visibility.
    @ret boolean bMatch Whether concrete class identity matches.
    @pulsarlua function class.isinstanceof
    !]]
    tMethods.isinstanceof = Context.internal(function(oObject, vClass)
        local __lxc_guard <close> = nil;
        local tClass = fVisible(vClass);
        return tClass ~= nil and tObjects[oObject] ~= nil and tObjects[oObject].Class == tClass;
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.isa
    @desc Tests polymorphic membership in an accessible class or any descendant of it.
    @param any oObject Candidate LXC instance.
    @param any vClass Class object, instance or exact qualified name, subject to caller visibility.
    @ret boolean bMatch Whether the instance belongs to this class ancestry.
    @pulsarlua function class.isa
    !]]
    tMethods.isa = Context.internal(function(oObject, vClass)
        local __lxc_guard <close> = nil;
        local tClass = fVisible(vClass);
        return tClass ~= nil and tObjects[oObject] ~= nil and Model.descends(tObjects[oObject].Class, tClass);
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.ischild
    @desc Tests strict descent between visible class/instance/name inputs. A class is not its own child;
        indirect descendants count.
    @param any vChild Child class object, instance or qualified name.
    @param any vParent Ancestor class object, instance or qualified name.
    @ret boolean bChild Whether the first class strictly descends from the second.
    @pulsarlua function class.ischild
    !]]
    tMethods.ischild = Context.internal(function(vChild, vParent)
        local __lxc_guard <close> = nil;
        local tChild, tParent = fVisible(vChild), fVisible(vParent);
        return tChild ~= nil and tParent ~= nil and tChild ~= tParent and Model.descends(tChild, tParent);
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.getparentname
    @desc Returns the immediate parent's qualified name when the selected class and parent are visible.
        Roots/unavailable inputs yield nil.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret string|nil sName Parent name or nil.
    @pulsarlua function class.getparentname
    !]]
    tMethods.getparentname = Context.internal(function(vValue)
        local __lxc_guard <close> = nil;
        local tClass = fVisible(vValue);
        return tClass and tClass.Parent and fVisible(tClass.Parent.Object) and tClass.Parent.FullName or nil;
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.getbasename
    @desc Returns the visible root ancestor's qualified name. A root returns its own name; unavailable
        input/root visibility yields nil.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret string|nil sName Root name or nil.
    @pulsarlua function class.getbasename
    !]]
    tMethods.getbasename = Context.internal(function(vValue)

           local __lxc_guard <close> = nil;
        local tClass = fVisible(vValue);
        if (not tClass) then return nil; end
        while (tClass.Parent) do tClass = tClass.Parent; end
        return fVisible(tClass.Object) and tClass.FullName or nil;
    end);
    
    --[[!
    @fqxn LuaEx.LXC.class.getchildnames
    @desc Returns a fresh alphabetically sorted list of visible direct-child names, excluding deeper
        descendants. Unavailable input yields nil; no children yields an empty list.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret table|nil tNames Direct-child names or nil.
    @pulsarlua function class.getchildnames
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
        --[[!
        @fqxn LuaEx.LXC.Helpers.__newindex
        @desc Rejects mutation of the public read-only class helper object.
        @ret nil Never returns successfully; raises a read-only/view error.
        @vis internal
        !]]
        __newindex = function()
            local __lxc_guard <close> = nil;
            error('Class helpers are read-only.');
        end});
end;
