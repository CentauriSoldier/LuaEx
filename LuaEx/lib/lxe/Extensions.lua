--[[!
@fqxn LuaEx.LXE.Extensions
@desc Builds read-only Lua environments and compiles enum extension functions.
    Enum references resolve through the prepared registry without early publication.
!]]
-- Keep runtime string operations independent of application replacements.
local _rep, _sub = string.rep, string.sub;


local Extensions = {};

--[[!
@fqxn LuaEx.LXE.Extensions.environment
@desc Resolves namespace/import names, declared dependencies, and host globals.
    Access to unready or undeclared enum dependencies fails at the source declaration.
@param table tOwner Enum root or extension declaration.
@param table tBatch Pending definitions.
@param table tRegistry Existing canonical registry.
@param table tHost Application environment.
@ret table Read-only Lua execution environment.
!]]
function Extensions.environment(tOwner, tBatch, tRegistry, tHost)
    local tRoot = tOwner.Root or tOwner.Definition.Root;
    local tAllowed = {[tRoot] = true};
    for _, sName in ipairs(tRoot.Requires or {}) do
        local tRequired = tBatch[sName] or tRegistry.Definitions[sName];
        tAllowed[tRequired.Root] = true;
    end
    local function fDefinition(sPath)
        return tBatch[sPath] or tRegistry.Definitions[sPath];
    end
    local function fObject(tDefinition)
        assert(not tDefinition.Root.Failed, "Discarded enum: "..tDefinition.FullName);
        assert(tAllowed[tDefinition.Root], "Declare requires("..tDefinition.Root.FullName..") before using this enum.");
        assert(tDefinition.Object, "Enum dependency is not initialized: "..tDefinition.FullName);
        if (tDefinition.Root.Within and (tDefinition.Root.Flags.Visibility or "public") ~= "public") then
            local sOwner = tOwner.Outer and tOwner.Outer.FullName;
            if (tOwner.Kind ~= "extension") then sOwner = tRoot.Within; end
            assert(sOwner == tDefinition.Root.Within, "Inaccessible class-owned enum: "..tDefinition.FullName);
        end
        return tDefinition.Object;
    end
    local tViews = {};
    local function fHasPrefix(sPath)
        local sPrefix = sPath..".";
        for sName in pairs(tBatch) do if (_sub(sName, 1, #sPrefix) == sPrefix) then return true; end end
        for sName in pairs(tRegistry.Definitions) do if (_sub(sName, 1, #sPrefix) == sPrefix) then return true; end end
        return false;
    end
    local function fNamespace(sPath, vHost)
        if (tViews[sPath]) then return tViews[sPath]; end
        local oView = setmetatable({}, {
            __index = function(_, sKey)
                local sFull = sPath.."."..sKey;
                local tFound = fDefinition(sFull);
                if (tFound) then return fObject(tFound); end
                local vExisting = vHost and vHost[sKey];
                if (fHasPrefix(sFull)) then return fNamespace(sFull, vExisting); end
                if (vExisting ~= nil) then return vExisting; end
                error("Unknown name: "..sFull, 2);
            end,
            __newindex = function() error("LXE namespace views are read-only.", 2); end,
            __metatable = false,
        });
        tViews[sPath] = oView;
        return oView;
    end
    return setmetatable({}, {
        __index = function(_, sName)
            local tFound = fDefinition(sName) or fDefinition(tOwner.Namespace.."."..sName);
            for _, sImport in ipairs(tOwner.Imports or {}) do
                local tOther = fDefinition(sImport.."."..sName);
                assert(not tOther or not tFound or tFound == tOther, "Ambiguous enum name: "..sName);
                tFound = tFound or tOther;
            end
            if (tFound) then return fObject(tFound); end
            local vExisting = tHost[sName];
            if (fHasPrefix(sName)) then return fNamespace(sName, vExisting); end
            if (vExisting ~= nil) then return vExisting; end
            error("Unknown name in "..tOwner.File..":"..tOwner.Line..": "..sName, 2);
        end,
        __newindex = function() error("LXE environments reject implicit global writes.", 2); end,
        __metatable = false,
    });
end

--[[!
@fqxn LuaEx.LXE.Extensions.compile
@desc Compiles all extension bodies before payload execution; wrappers enforce exact
    receiver membership on calls. Compiling does not invoke application bodies.
@param table tExtensions Validated extension records.
@param table tBatch Pending definitions.
@param table tRegistry Private registry.
@param table tHost Application environment.
!]]
function Extensions.compile(tExtensions, tBatch, tRegistry, tHost)
    for _, tExtension in ipairs(tExtensions) do
        local tEnvironment = Extensions.environment(tExtension, tBatch, tRegistry, tHost);
        local sSource = _rep("\n", tExtension.Line - 1).."return function("..
            table.concat(tExtension.Parameters, ",")..")\n"..tExtension.Body.."\nend";
        local fMethod = assert(load(sSource, "@"..tExtension.File, "t", tEnvironment))();
        tExtension.Function = function(oReceiver, ...)
            local tState = tRegistry.States[oReceiver];
            assert(tState and not tState.Root.Failed and tState.Parent and
                tState.Parent.Definition == tExtension.Definition, "Invalid enum extension receiver.");
            return fMethod(oReceiver, ...);
        end;
    end
end

return Extensions;

