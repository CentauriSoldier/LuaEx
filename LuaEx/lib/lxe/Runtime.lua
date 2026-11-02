--[[!
@fqxn LuaEx.LXE.Runtime
@desc Builds canonical enum/member objects with private state. Public objects are
    empty table views; payload objects retain their own identity and mutability.
!]]
local Runtime = {};

--[[!
@fqxn LuaEx.LXE.Runtime.create
@desc Creates runtime operations sharing only the loader's private registry.
@param table tRegistry Canonical definitions and object-state map.
@param any oNull LuaEx null singleton.
@ret table Runtime service.
!]]
function Runtime.create(tRegistry, oNull)
    local Service, tStates = {}, tRegistry.States;
    local function fState(oObject)
        local tState = tStates[oObject];
        assert(tState and not tState.Root.Failed, "Invalid or discarded LXE value.");
        return tState;
    end
    local function fPayload(vOperand)
        local tState = tStates[vOperand];
        if (tState) then return fState(vOperand).Value; end
        return vOperand;
    end
    local function fNumeric(vOperand, bInteger)
        local vValue = fPayload(vOperand);
        assert(type(vValue) == "number" and (not bInteger or math.tointeger(vValue)),
            bInteger and "LXE bitwise operations require integers." or "LXE arithmetic requires numbers.");
        return vValue;
    end
    local tArithmetic = {
        __add = function(a, b) return a + b; end,
        __sub = function(a, b) return a - b; end,
        __mul = function(a, b) return a * b; end,
        __div = function(a, b) return a / b; end,
        __idiv = function(a, b) return a // b; end,
        __mod = function(a, b) return a % b; end,
        __pow = function(a, b) return a ^ b; end,
    };
    local tBitwise = {
        __band = function(a, b) return a & b; end,
        __bor = function(a, b) return a | b; end,
        __bxor = function(a, b) return a ~ b; end,
        __shl = function(a, b) return a << b; end,
        __shr = function(a, b) return a >> b; end,
    };
    local function fOrder(a, b, bEqual)
        local tLeft, tRight = fState(a), fState(b);
        assert(tLeft.Parent and tLeft.Parent == tRight.Parent, "LXE ordering requires siblings.");
        if (bEqual) then return tLeft.Value <= tRight.Value; end
        return tLeft.Value < tRight.Value;
    end
    local function fAllocate(tDefinition, tParent, tRoot)
        local oObject, tState = {}, {Definition = tDefinition, Parent = tParent,
            Root = tRoot, Children = {}, ByName = {}, Name = tDefinition.Name,
            Ordinal = tDefinition.Ordinal, FullName = tDefinition.FullName};
        tStates[oObject], tDefinition.Object, tState.Object = tState, oObject, oObject;
        local tMeta = {
            __index = function(_, vKey)
                fState(oObject);
                if (vKey == "Name") then return tState.Name; end
                if (vKey == "Parent") then return tParent and tParent.Object or oNull; end
                if (vKey == "Ordinal" and tParent) then return tState.Ordinal; end
                if (vKey == "Value" and tParent) then
                    assert(tState.Ready, "Enum member is not initialized: "..tState.FullName);
                    return tState.Value;
                end
                local oChild = tState.ByName[vKey] or tState.Children[vKey];
                if (oChild) then return oChild; end
                local tExtension = tParent and tParent.Definition.Extensions[vKey];
                if (tExtension) then return assert(tExtension.Function, "Extension is not ready."); end
                if (type(vKey) == "number") then return nil; end
                error("Unknown enum member: "..tState.FullName.."."..tostring(vKey), 2);
            end,
            __newindex = function() error("LXE enums are read-only.", 2); end,
            __metatable = false,
            __type = tParent and tParent.FullName or "enum",
            __subtype = tParent and "enumitem" or nil,
            __clone = function() fState(oObject); return oObject; end,
            __serialize = function()
                fState(oObject); tRegistry.Check(tRoot);
                return {Path = tState.FullName};
            end,
            __serialtype = "lxevalue",
            __tostring = function() fState(oObject); return tState.FullName; end,
        };
        if (tDefinition.Members) then
            tMeta.__len = function() fState(oObject); return #tState.Children; end;
            local function fIterator(_, nOrdinal)
                fState(oObject);
                local oChild = tState.Children[nOrdinal + 1];
                if (oChild) then return nOrdinal + 1, oChild; end
            end
            local function fIterate() return fIterator, oObject, 0; end
            tMeta.__pairs, tMeta.__call = fIterate, fIterate;
        end
        if (tParent) then
            for sName, fOperation in pairs(tArithmetic) do
                tMeta[sName] = function(a, b) return fOperation(fNumeric(a), fNumeric(b)); end;
            end
            for sName, fOperation in pairs(tBitwise) do
                tMeta[sName] = function(a, b) return fOperation(fNumeric(a, true), fNumeric(b, true)); end;
            end
            tMeta.__unm = function(a) return -fNumeric(a); end;
            tMeta.__bnot = function(a) return ~fNumeric(a, true); end;
            tMeta.__lt = function(a, b) return fOrder(a, b, false); end;
            tMeta.__le = function(a, b) return fOrder(a, b, true); end;
            tMeta.__concat = function(a, b)
                local vLeft, vRight = fPayload(a), fPayload(b);
                assert((type(vLeft) == "string" or type(vLeft) == "number") and
                    (type(vRight) == "string" or type(vRight) == "number"),
                    "LXE concatenation requires string/number payloads.");
                return vLeft..vRight;
            end;
        end
        -- LuaEx's type hook reads the public metatable view. Expose identity
        -- metadata through an immutable view, never the mutable implementation.
        tMeta.__metatable = setmetatable({}, {
            __index = {__type = tMeta.__type, __subtype = tMeta.__subtype},
            __newindex = function() error("LXE metadata is read-only.", 2); end,
            __metatable = false,
        });
        setmetatable(oObject, tMeta);
        if (tDefinition.Members) then
            for n, tMember in ipairs(tDefinition.Members) do
                local oChild = fAllocate(tMember, tState, tRoot);
                tState.Children[n], tState.ByName[tMember.Name] = oChild, oChild;
            end
        end
        return oObject;
    end

    --[[!
    @fqxn LuaEx.LXE.Runtime.allocate
    @desc Allocates an enum tree without evaluating payloads.
    @param table tRoot Validated root declaration.
    @ret table Canonical root object.
    !]]
    function Service.allocate(tRoot)
        return fAllocate(tRoot, nil, tRoot);
    end

    --[[!
    @fqxn LuaEx.LXE.Runtime.initialize
    @desc Evaluates members once in declaration order and rejects nil/duplicates.
    @param table tRoot Allocated root.
    @param function fEvaluate Evaluates one member expression.
    !]]
    function Service.initialize(tRoot, fEvaluate)
        local function fMembers(tDefinition)
            local tSeen = {};
            for _, tMember in ipairs(tDefinition.Members) do
                local vValue = tMember.Ordinal;
                if (tMember.Expression) then vValue = fEvaluate(tMember); end
                if (vValue == nil) then error(tMember.File..":"..tMember.Line..": Explicit enum value is nil.", 0); end
                -- Lua table keys use raw identity for reference values and normal
                -- equality for scalars. NaN is never equal and cannot be a key.
                local bNaN = type(vValue) == "number" and vValue ~= vValue;
                if (not bNaN) then
                    if (tSeen[vValue]) then error(tMember.File..":"..tMember.Line..": Duplicate enum value: "..tMember.Name, 0); end
                    tSeen[vValue] = true;
                end
                local tState = tStates[tMember.Object];
                tState.Value, tState.Ready = vValue, true;
                if (tMember.Members) then fMembers(tMember); end
            end
        end
        fMembers(tRoot);
    end

    --[[!
    @fqxn LuaEx.LXE.Runtime.helpers
    @desc Returns the small public lookup/membership API; no registry names leak.
    @ret table Public helper functions.
    !]]
    function Service.helpers()
        return {
            getByName = function(oEnum, sName)
                local tState = fState(oEnum);
                assert(tState.Definition.Members and type(sName) == "string", "Expected enum and member name.");
                return tState.ByName[sName];
            end,
            getByValue = function(oEnum, vValue)
                local tState = fState(oEnum);
                assert(tState.Definition.Members, "Expected an enum collection.");
                for _, oChild in ipairs(tState.Children) do
                    if (rawequal(fState(oChild).Value, vValue)) then return oChild; end
                end
            end,
            isMember = function(oMember, oEnum)
                local tState = tStates[oMember];
                return tState ~= nil and not tState.Root.Failed and tState.Parent ~= nil and
                    tState.Parent.Object == oEnum;
            end,
            isEnum = function(vValue)
                local tState = tStates[vValue];
                return tState ~= nil and not tState.Root.Failed and tState.Definition.Members ~= nil;
            end,
        };
    end
    return Service;
end

return Runtime;

