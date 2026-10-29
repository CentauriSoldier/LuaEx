--[[!
@fqxn LXC.Environment
@desc Builds private lexical class environments and read-only namespace views.
    Lookup order is compiler bindings, class resolution, namespace roots, then
    the host-supplied environment. No environment or privileged view is returned
    by the public API. Runtime supplies the checked class-access operation.
!]]
return function(Model, Context, Facades)
    local Environment = {};

    --[[!
    @fqxn LXC.Environment.create
    @param table tClass Declaring class whose compiled functions use this scope.
    @param table tBatch Definitions being staged alongside already loaded classes.
    @param table tHost Final fallback bindings supplied by the loader caller.
    @param table tBindings Internal compiler/helper bindings, never host globals.
    @param function fCheckClass Runtime class use-site validator.
    @ret table Private scope registered with the lexical context service.
    !]]
    function Environment.create(tClass, tBatch, tHost, tBindings, fCheckClass)
        local tNamespaceCache = {};

        -- Namespace views are cached only within this declaring class's scope.
        -- Each lookup still checks the current using scope before yielding a class.
        local function fNamespace(sPath)
            if (tNamespaceCache[sPath]) then return tNamespaceCache[sPath]; end

            local oNamespace = Facades.create({
                __index = Context.internal(function(sKey)
                    local __lxc_guard <close> = nil;
                    assert(type(sKey) == 'string', 'Namespace names must be strings.');
                    local sFull = sPath..'.'..sKey;
                    local tFound = tBatch[sFull] or Model.Classes[sFull];
                    if (tFound) then
                        fCheckClass(tFound, Context.caller());
                        return tFound.Object;
                    end

                    for sName in pairs(tBatch) do
                        if (string.sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end
                    for sName in pairs(Model.Classes) do
                        if (string.sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end
                    error('Unknown namespace member: '..sFull);
                end),
                __newindex = function() error('Namespace is read-only.'); end,
            });

            tNamespaceCache[sPath] = oNamespace;
            return oNamespace;
        end
        Context.internal(fNamespace);

        local tScope = setmetatable({}, {
            __index = Context.internal(function(_, sKey)
                local __lxc_guard <close> = nil;
                if (tBindings[sKey] ~= nil) then return tBindings[sKey]; end

                local tFound = Model.resolve(sKey, tClass, tBatch);
                if (tFound) then
                    fCheckClass(tFound, tClass);
                    return tFound.Object;
                end
                for sName in pairs(tBatch) do
                    if (string.match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end
                for sName in pairs(Model.Classes) do
                    if (string.match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end
                return tHost[sKey];
            end),
            __newindex = function() error('Class environments do not allow implicit global writes.'); end,
        });

        Context.register(tScope, tClass);
        return tScope;
    end

    return Environment;
end;
