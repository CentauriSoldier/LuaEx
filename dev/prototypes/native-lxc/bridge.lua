-- Existing parser, model validation and compiler; isolated experimental C storage.
local source = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local here = assert(source:match("^(.*)/[^/]+$"));
local root = source:match("^(.*)dev/prototypes/native%-lxc/bridge%.lua$");
assert(root, "Cannot locate the LuaEx prototype root.");
if (root == "") then root = "./"; end
package.path = root.."?.lua;"..package.path;
local modulePath = os.getenv("LXC_NATIVE_MODULE") or here.."/build/Release/lxc_native.dll";
local native = assert(package.loadlib(modulePath, "luaopen_lxc_native"))();
local Tokens = require("LuaEx.lib.lxc.Tokens");
local Names = require("LuaEx.lib.lxc.Names");
local Operators = require("LuaEx.lib.lxc.Operators");
local Diagnostics = require("LuaEx.lib.lxc.Diagnostics");
local Parser = require("LuaEx.lib.lxc.Parser")(Tokens, Names, Operators);
local Bridge = {};

local function supportedClass(definition, enums)
    assert(#enums == 0, "Prototype does not support enums or extensions.");
    assert(not definition.ParentName, "Prototype does not support inheritance.");
    assert(not definition.StaticConstructor, "Prototype does not support static construction.");
    assert(not definition.Outer and not next(definition.Nested or {}), "Prototype does not support nested classes.");
    assert(not definition.Flags.abstract and not definition.requires and not definition.permits and not definition.excludes,
        "Prototype does not support abstract classes or dependency/child policies.");
    assert(not definition.DefaultAnnotation, "Prototype does not support @default selection.");
    local function fMember(member, constructor)
        assert(not member.Flags.static and not member.Flags.abstract and not member.Flags.override,
            "Prototype does not support static, abstract or override members.");
        assert(not member.Flags.const and not member.Flags.final, "Prototype does not support const/final bindings.");
        assert(not member.TypeAnnotation, "Prototype does not support @type annotations.");
        if (constructor or member.Kind == "method") then
            assert(member.Visibility == "public", "Prototype supports public methods/constructors only.");
        else
            assert(member.Kind == "field", "Prototype does not support properties or operators.");
            assert(member.Visibility == "public" or member.Visibility == "private", "Prototype supports public/private fields only.");
            local text = assert(member.Initializer, "Prototype fields require scalar literal defaults.");
            local tokens = Tokens.scan(text, definition.File);
            assert(tonumber(text) or text == "true" or text == "false" or
                (#tokens == 2 and tokens[1].Kind == "string"), "Prototype defaults must be scalar literals.");
        end
    end
    for _, member in ipairs(definition.Members) do fMember(member, false); end
    if (definition.Constructor) then fMember(definition.Constructor, true); end
    assert(not next(definition.Operators or {}), "Prototype does not support custom operators.");
end

-- Select only a whole, single-parameter assignment. Token matching preserves
-- comments/spacing and rejects additional statements, returns and expressions.
local function setterSlot(member, definition, Model)
    if (member.Variadic or #member.Parameters ~= 1) then return; end
    local tokens = Tokens.scan(member.Body, definition.File);
    local complete = #tokens == 6 and tokens[6].Text == "<eof>" or
        #tokens == 7 and tokens[6].Text == ";" and tokens[7].Text == "<eof>";
    if (not complete or tokens[1].Text ~= "this" or tokens[2].Text ~= "." or
        tokens[4].Text ~= "=" or tokens[5].Text ~= member.Parameters[1]) then return; end
    local field = Model.member(definition, definition, tokens[3].Text);
    if (field and field.Kind == "field" and Model.memberAllowed(field, definition, definition)) then
        return field.NativeSlot;
    end
end

-- This prototype deliberately loads one class per batch. Unsupported declarations
-- fail before initializers or constructors execute; no fallback changes the result.
function Bridge.loadSource(text, filename, host, options)
    host = host or _G;
    options = options or {};
    local classes, enums = Parser.parse(text, filename or "prototype.lxc");
    assert(#classes == 1, "Prototype loads exactly one class per batch.");
    local definition = classes[1];
    supportedClass(definition, enums);
    local Model = require("LuaEx.lib.lxc.Model")(require("LuaEx.lib.lxc.Validation"), Diagnostics, Names, Operators);
    local Compiler = require("LuaEx.lib.lxc.Compiler")(Tokens, Model, require("LuaEx.lib.lxc.LuaScope")(Tokens));
    local batch = {[definition.FullName] = definition};
    definition.Batch = batch;
    Model.validate(batch);

    local descriptor = {count = 0, fields = {}, methods = {}, initializers = {}};
    for _, member in ipairs(definition.Members) do
        if (member.Kind == "field") then
            descriptor.count = descriptor.count + 1;
            member.NativeSlot = descriptor.count;
            descriptor.fields[member.Name] = {slot = member.NativeSlot, public = member.Visibility == "public"};
        end
    end
    local class, authority = native.define(descriptor);
    definition.Object = class;
    local mapping = {};
    local read, view = native.scope(authority, mapping);
    local scope = setmetatable({__lxc_read = read, __lxc_view = view}, {
        __index = function(_, name)
            local resolved = Model.resolve(name, definition, batch);
            if (resolved) then return resolved.Object; end
            return host[name];
        end,
        __newindex = function() error("Prototype class environment is read-only.", 2); end,
    });
    local ok, err = pcall(function()
        for _, member in ipairs(definition.Members) do
            if (member.Kind == "field") then
                Compiler.initializer(member, scope);
                descriptor.initializers[member.NativeSlot] = member.Initialize;
            else
                Compiler.method(member, scope);
                local field = member.Body:match("^%s*return%s+this%.([%a_][%w_]*)%s*;?%s*$");
                local selected = field and Model.member(definition, definition, field);
                descriptor.methods[member.Name] = {fn = member.Function,
                    getter = selected and selected.Kind == "field" and selected.NativeSlot or nil,
                    setter = options.directSetters ~= false and setterSlot(member, definition, Model) or nil};
            end
        end
        if (definition.Constructor) then
            Compiler.constructor(definition.Constructor, scope);
            descriptor.constructor = definition.Constructor.Function;
        end
        for index, member in ipairs(definition.DirectReadMembers or {}) do mapping[index] = member.NativeSlot; end
        native.seal(authority);
    end);
    if (not ok) then native.invalidate(authority); error(err, 0); end
    return class;
end

function Bridge.loadFile(filename, host, options)
    local file = assert(io.open(filename, "rb"));
    local text = file:read("*a");file:close();
    return Bridge.loadSource(text, filename, host, options);
end

return Bridge;
