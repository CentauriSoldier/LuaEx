--[[!
@fqxn LXC.Facades
@desc Opaque references with Lua-compatible operand lookup. Private handler maps
    remain inaccessible through raw operations or the protected decoy metatable.
    Foreign metamethods execute behind an external caller boundary.
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
@fqxn LXC.Facades.invokeExternal
@desc Intentionally NOT registered as a runtime frame. An application-supplied
    metamethod cannot borrow the class scope which triggered its invocation.
!]]
local function invokeExternal(vMethod, ...)
    local __lxc_guard <close> = nil;
    return vMethod(...);
end

--[[!
@fqxn LXC.Facades.findBinary
@desc Finds the operation actually declared by this operand. A missing class
    operation permits right-operand fallback despite the shared decoy metatable.
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
@fqxn LXC.Facades.binary
@desc Preserves original operand order, left-before-right lookup and Lua's
    reversed __lt fallback for <=. Foreign operations receive ordinary operands.
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
@fqxn LXC.Facades.dispatch
@desc Routes nonbinary operations to their private handlers. This frame must
    remain visible so external tail calls cannot acquire a class caller's rights.
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
@fqxn LXC.Facades.finalize
@desc A private finalizable sidecar supplies exactly one __gc for each instance.
    Reinstates dispatch during finalization so legitimate private reads and Lua
    resurrection work even if weak-key cleanup has already removed the entry.
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
@fqxn LXC.Facades.owns
@desc Private bootstrap query. A later runtime must retain existing decoys by
    identity instead of enumerating them while capturing host dependencies.
!]]
function Facades.owns(vValue)
    return _tHandlers[vValue] ~= nil;
end

--[[!
@fqxn LXC.Facades.register
@desc Registers only trusted dispatch frames; invokeExternal remains a boundary.
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
@fqxn LXC.Facades.create
@param table tOperations Private operations; never returned to application code.
@ret table Empty decoy, independent of other instances' hidden handlers.
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
