--[[!
@fqxn LuaEx.LXC.Facades
@desc <h3>Facades — responsibility and connections</h3><p>Creates the empty public tables used as classes,
    instances, namespace views and read-only APIs. State lives in private handler maps; a shared protected
    metatable forwards operations to the owning service. This supports encapsulation through ordinary Lua
    operations, not a security sandbox against privileged debug/raw access.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

local _tHandlers = setmetatable({}, {__mode = 'k'});
local _getMeta = debug.getmetatable;
-- Share trusted dispatch frames across loads without changing foreign threads.
-- The registry is available only through the already privileged debug facility.
local _tRegistry = debug.getregistry();
local _sRegistryKey = 'LXC.Facades.TableDecoys';
if (_tRegistry[_sRegistryKey]) then return _tRegistry[_sRegistryKey]; end

local _tMeta;
local _tBinary = {};
for _, sName in ipairs({'__add', '__sub', '__mul', '__div', '__idiv', '__mod', '__pow',
    '__concat', '__eq', '__lt', '__le', '__band', '__bor', '__bxor', '__shl', '__shr'}) do
    _tBinary[sName] = true;
end


--[[!
@fqxn LuaEx.LXC.Facades.invokeExternal
@desc Invokes a foreign operand metamethod through a deliberately non-internal frame, preserving the application
    callback's access boundary.
@param function vMethod Foreign operand metamethod selected for invocation.
@param any ... Additional arguments forwarded in order.
@ret any ... Foreign metamethod results.
@vis internal
!]]
local function invokeExternal(vMethod, ...)
    local __lxc_guard <close> = nil;
    return vMethod(...);
end


--[[!
@fqxn LuaEx.LXC.Facades.findBinary
@desc Selects an operand implementation without invoking it. LXC handlers advertise support; foreign operands
    use their actual metatable.
@param any vValue Value to inspect, assign, copy or serialize.
@param string sOperation Canonical Lua metamethod operation name.
@ret function|nil vMethod Selected method, followed by boolean bClass for LXC dispatch.
@vis internal
!]]
local function findBinary(vValue, sOperation)
    local tHandler = _tHandlers[vValue];
    if (tHandler) then
        if (tHandler.__supports and tHandler.__supports(sOperation)) then
            return tHandler.__operator, true;
        end
        return;
    end
    local tMeta = _getMeta(vValue);
    if (type(tMeta) == 'table') then return rawget(tMeta, sOperation), false; end
end


--[[!
@fqxn LuaEx.LXC.Facades.binary
@desc Tries left then right operand support. LXC receives both operands; foreign methods run through
    invokeExternal. Missing &lt;= falls back to reversed <, and missing equality to raw identity.
@param string sOperation Canonical Lua metamethod operation name.
@param any vLeft Original left operand.
@param any vRight Original right operand.
@ret any ... Operator results or an unsupported-operation error.
@vis internal
!]]
local function binary(sOperation, vLeft, vRight)
    local __lxc_guard <close> = nil;
    local vMethod, bClass = findBinary(vLeft, sOperation);
    if (vMethod == nil) then vMethod, bClass = findBinary(vRight, sOperation); end
    if (vMethod ~= nil) then
        if (bClass) then return vMethod(sOperation, vLeft, vRight); end
        return invokeExternal(vMethod, vLeft, vRight);
    end
    if (sOperation == '__le') then return not binary('__lt', vRight, vLeft); end
    if (sOperation == '__eq') then return rawequal(vLeft, vRight); end
    error('No operand implements '..sOperation..'.', 2);
end


--[[!
@fqxn LuaEx.LXC.Facades.dispatch
@desc Routes facade operations to private handlers. Binary operators share operand selection; other operations
    use an explicit or generic operator callback. Unknown references and unsupported operations fail.
@param string sOperation Canonical Lua metamethod operation name.
@param table oReference Opaque public facade reference.
@param any ... Additional arguments forwarded in order.
@ret any ... Selected handler results.
@vis internal
!]]
local function dispatch(sOperation, oReference, ...)
    local __lxc_guard <close> = nil;
    if (_tBinary[sOperation]) then return binary(sOperation, oReference, ...); end
    local tHandler = _tHandlers[oReference];
    if (tHandler) then
        local fOperation = tHandler[sOperation];
        if (not fOperation and tHandler.__operator) then return tHandler.__operator(sOperation, ...); end
        assert(fOperation, 'Unsupported LXC reference operation: '..sOperation);
        return fOperation(...);
    end
    error('Unknown LXC reference.', 2);
end


--[[!
@fqxn LuaEx.LXC.Facades.finalize
@desc Reestablishes the reference/handler association while finalizing its handler, then invokes __finalize.
    Runtime's callback decides whether the instance is ready and permitted to run gc.
@param table tHandler Private facade operation record.
@ret nil No return value.
@vis internal
!]]
local function finalize(tHandler)
    local __lxc_guard <close> = nil;
    local oReference = tHandler.Reference;
    _tHandlers[oReference] = tHandler;
    tHandler.__finalize();
end
local _tFinalizerMeta = {__gc = finalize};

_tMeta = {__metatable = 'LXC opaque reference', __serialtype = 'table'};
for _, sOperation in ipairs({'__index', '__newindex', '__call', '__len', '__pairs', '__tostring', '__close', '__serialize',
    '__add', '__sub', '__mul', '__div', '__idiv', '__mod', '__pow', '__concat', '__unm', '__eq', '__lt', '__le',
    '__band', '__bor', '__bxor', '__bnot', '__shl', '__shr'}) do
    _tMeta[sOperation] = function(oReference, ...)
        local __lxc_guard <close> = nil;
        return dispatch(sOperation, oReference, ...);
    end;
end

local Facades = {};


--[[!
@fqxn LuaEx.LXC.Facades.owns
@desc Checks the private handler map without exposing or enumerating state.
@param any vValue Value to inspect, assign, copy or serialize.
@ret boolean bOwned Whether this value is a known facade.
@vis internal
!]]
function Facades.owns(vValue)
    return _tHandlers[vValue] ~= nil;
end


--[[!
@fqxn LuaEx.LXC.Facades.register
@desc Registers shared dispatch/metamethod frames with a Context service. invokeExternal intentionally remains a
    visible application boundary.
@param table Context Caller-ownership service receiving trusted dispatch registrations.
@ret nil No return value; registers trusted identities.
@vis internal
!]]
function Facades.register(Context)
    Context.internal(dispatch);
    Context.internal(binary);
    Context.internal(findBinary);
    Context.internal(finalize);
    for _, fOperation in pairs(_tMeta) do
        if (type(fOperation) == 'function') then Context.internal(fOperation); end
    end
end


--[[!
@fqxn LuaEx.LXC.Facades.create
@desc Returns an empty protected table dispatching through the supplied handler record. Optional __finalize
    arranges handler finalization. Reads/writes/operators use callbacks; raw table enumeration cannot reveal
    private state.
@param table tOperations Callbacks keyed by metamethod, with optional __supports/__operator/__finalize
    extensions.
@ret table oReference New opaque public reference.
@vis internal
!]]
function Facades.create(tOperations)
    local oReference = setmetatable({}, _tMeta);
    _tHandlers[oReference] = tOperations;
    if (tOperations.__finalize) then
        tOperations.Reference = oReference;
        setmetatable(tOperations, _tFinalizerMeta);
    end
    return oReference;
end

_tRegistry[_sRegistryKey] = Facades;
return Facades;
