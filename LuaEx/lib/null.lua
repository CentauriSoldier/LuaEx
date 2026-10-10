--[[!
@fqxn LuaEx.Libraries.null
@pulsarlua table null
@desc The immutable null singleton represents an explicitly empty value. Unlike nil,
it retains table entries and sequence slots. LuaEx publishes the same object as null
and NULL. Null supports placeholder propagation, empty iteration, cloning and persistence.
The sections below document its operators and methods individually.
<br><strong>Localization warning:</strong> the owner has observed unexpected behavior
when localizing null in some environments. Prefer the global null/NULL names. The
examples use those names; this warning does not imply that assignment normally copies
or creates another singleton.
@ex
require("LuaEx.init");

local tRecord = {owner = null, description = null};
assert(tRecord.owner == null);
assert(rawget(tRecord, "owner") ~= nil); -- The field still exists.

tRecord.owner = nil; -- nil removes the field entirely.
assert(rawget(tRecord, "owner") == nil);
assert(rawequal(NULL, null));
!]]

--[[!
@fqxn LuaEx.Libraries.null.TypeAndIdentity
@pulsarlua table null.TypeAndIdentity
@desc type(null) returns "null", subtype(null) returns "null", and type.isnull(null)
is true. NULL is an alias of the same singleton. Null differs from nil, false, zero
and ordinary tables. Lua's equality dispatch invokes null's __eq hook for applicable
objects; that hook compares their LuaEx type names. Use rawequal for singleton identity.
@ex
require("LuaEx.init");
assert(type(null) == "null" and subtype(null) == "null");
assert(type.isnull(null) and rawequal(null, NULL));
assert(null ~= nil and null ~= false and null ~= 0 and null ~= {});
!]]

--[[!
@fqxn LuaEx.Libraries.null.Truthiness
@pulsarlua table null.Truthiness
@desc Null is truthy because it is a Lua object. Its operators cannot change Lua's
if, not, and or behavior. Test a value explicitly against null when checking emptiness.
@ex
require("LuaEx.init");
local bEntered = false;
if (null) then bEntered = true; end
assert(bEntered and not null == false);
assert((null or "fallback") == null); -- or sees a truthy object.
assert((null and "next") == "next");

local tRecord = {owner = null};
local sOwner = tRecord.owner == null and "unassigned" or tRecord.owner;
assert(sOwner == "unassigned");
!]]

--[[!
@fqxn LuaEx.Libraries.null.Indexing
@pulsarlua table null.Indexing
@desc Named and other nonnumeric indexing propagates null unless the key names an
actual method (clone or serialize). Numeric indexing returns nil, including zero,
negative and fractional indices. This permits modern ipairs to terminate. A chain
may continue through named indices, but cannot continue after a numeric nil result.
@ex
require("LuaEx.init");
assert(null.owner.address.city == null);
assert(null["missing"] == null and null[false] == null);
assert(null[1] == nil and null[0] == nil and null[-1] == nil and null[1.5] == nil);
assert(type(null.clone) == "function" and type(null.serialize) == "function");
assert(rawget(null, "owner") == nil); -- Raw access bypasses propagation.
!]]

--[[!
@fqxn LuaEx.Libraries.null.Immutability
@pulsarlua table null.Immutability
@desc Ordinary assignment to any null key raises an error, including assignment to
existing method names. Its metatable cannot be replaced through setmetatable.
Raw writes and debug APIs bypass normal Lua object protection and are outside this
contract. getmetatable exposes informational metadata rather than the actual operator table.
@ex
require("LuaEx.init");
assert(not pcall(function() null.owner = "Alex"; end));
assert(not pcall(function() null.clone = function() end; end));
assert(not pcall(function() null[1] = 7; end));
assert(not pcall(setmetatable, null, {}));
assert(null.owner == null and null.clone() == null);
!]]

--[[!
@fqxn LuaEx.Libraries.null.__len
@pulsarlua table null.__len
@desc #null returns zero. A surrounding sequence containing null has real occupied
slots, so its length is independent of null's own length. Ordinary Lua rules for
sequences containing nil holes still apply.
@ex
require("LuaEx.init");
assert(#null == 0);
local tSlots = {null, null, null};
assert(#tSlots == 3);
for nIndex = 1, #tSlots do assert(tSlots[nIndex] == null); end
!]]

--[[!
@fqxn LuaEx.Libraries.null.Iteration
@pulsarlua table null.Iteration
@desc pairs(null) and ipairs(null) produce no entries. Their hooks return a real
empty iterator. Numeric indexing also returns nil for runtimes that ignore __ipairs.
No meaningful fields are stored directly on the singleton; next(null) returns nil.
@ex
require("LuaEx.init");
local nCount = 0;
for _ in pairs(null) do nCount = nCount + 1; end
for _ in ipairs(null) do nCount = nCount + 1; end
assert(nCount == 0 and next(null) == nil);

-- A containing table still exposes entries whose value is null.
local tFields = {owner = null};
for sKey, vValue in pairs(tFields) do
    assert(sKey == "owner" and vValue == null);
end
!]]

--[[!
@fqxn LuaEx.Libraries.null.__call
@desc Calling null accepts any arguments, ignores them, and returns zero values.
A single assignment or equality expression adjusts that empty result to nil.
Calling null does not return null and cannot replace a callback needing a meaningful result.
@ex
require("LuaEx.init");
assert(select("#", null()) == 0);
assert(select("#", null("ignored", 42)) == 0);
assert(null() == nil);
!]]

--[[!
@fqxn LuaEx.Libraries.null.Arithmetic
@pulsarlua table null.Arithmetic
@desc Addition (+), subtraction (-), multiplication (*), division (/), integer division
(//), modulo (%) and exponentiation (^) return null when Lua dispatches to null's
operator hook. Unary minus also returns null. These operations propagate emptiness;
they do not coerce null to zero or perform numeric calculations. Another object's
operator hook may take precedence when null is the right operand.
@ex
require("LuaEx.init");
assert(null + 5 == null and 5 + null == null);
assert(null - 5 == null and 5 - null == null);
assert(null * 5 == null and 5 * null == null);
assert(null / 0 == null and 5 / null == null);
assert(null // 2 == null and 5 // null == null);
assert(null % 2 == null and 5 % null == null);
assert(null ^ 2 == null and 5 ^ null == null);
assert(-null == null);
!]]

--[[!
@fqxn LuaEx.Libraries.null.Bitwise
@pulsarlua table null.Bitwise
@desc Bitwise and (&), or (|), exclusive or (~), left shift (<<), right shift (>>)
and unary bitwise not (~) propagate null when its hook is selected. Lua's logical
keywords and/or/not retain their ordinary truthiness behavior.
@ex
require("LuaEx.init");
assert((null & 3) == null and (3 & null) == null);
assert((null | 3) == null and (3 | null) == null);
assert((null ~ 3) == null and (3 ~ null) == null);
assert((null << 1) == null and (3 << null) == null);
assert((null >> 1) == null and (3 >> null) == null);
assert((~null) == null);
!]]

--[[!
@fqxn LuaEx.Libraries.null.__concat
@pulsarlua table null.__concat
@desc Concatenation propagates the null object when its hook is selected; it does
not produce a string containing "null". Call tostring(null) explicitly to produce text.
@ex
require("LuaEx.init");
assert(("owner: "..null) == null and (null.." suffix") == null);
assert(type("owner: "..null) == "null");
assert("owner: "..tostring(null) == "owner: null");
!]]

--[[!
@fqxn LuaEx.Libraries.null.Comparisons
@pulsarlua table null.Comparisons
@desc When null's comparison hooks are selected, null is strictly less than a value
whose LuaEx type is neither null nor nil. Less-or-equal returns true when the left
value is null and the right value is non-nil, or both operands have the same LuaEx
type. Thus null &lt; null is false, null &lt;= null is true, and comparisons with nil
are false. Lua implements &gt; and &gt;= by reversing operands. Other objects may supply
competing hooks; these rules do not define a universal ordering for arbitrary objects.
@ex
require("LuaEx.init");
assert(null < 1 and null <= 1);
assert(null < "text" and null < false);
assert(not (null < null) and null <= null);
assert(not (null < nil) and not (null <= nil));
assert(not (nil < null) and not (nil <= null));
assert(1 > null and 1 >= null);
assert(not (null > 1) and not (null >= 1));
!]]

--[[!
@fqxn LuaEx.Libraries.null.__tostring
@pulsarlua table null.__tostring
@desc tostring(null) returns the string "null". This is a textual representation,
not a different placeholder object. print(null) uses this representation.
@ex
require("LuaEx.init");
assert(tostring(null) == "null");
assert(type(tostring(null)) == "string");
!]]

--[[!
@fqxn LuaEx.Libraries.null.clone
@pulsarlua function null.clone
@desc Returns the same immutable singleton. The __clone hook and global clone(null)
share this behavior; no new null instance is allocated. Dot and colon calls are both accepted.
@ret null The original singleton.
@ex
require("LuaEx.init");
assert(rawequal(null.clone(), null));
assert(rawequal(null:clone(), null));
assert(rawequal(clone({owner = null}).owner, null));
!]]

--[[!
@fqxn LuaEx.Libraries.null.serialize
@pulsarlua function null.serialize
@desc Returns the Lua expression string "null". The __serialize hook and global
serialize(null) use the same representation. Deserialization restores the singleton;
its identity is retained when it occurs inside a larger saved graph. LuaEx must be
initialized before evaluating the expression. Dot and colon calls are both accepted.
@ret string The expression "null".
@ex
require("LuaEx.init");
assert(null.serialize() == "null" and null:serialize() == "null");
assert(rawequal(deserialize(serialize(null)), null));
local tRestored = deserialize(serialize({owner = null, slots = {null, null}}));
assert(tRestored.owner == null and #tRestored.slots == 2);
assert(rawequal(tRestored.slots[1], null));
!]]

local type 			= type;
local setmetatable 	= setmetatable;

local function dummy() end

local function eq(l, r)
    return type(l) == type(r)
end


local function index(t, k)
    local vRet = null;

    -- Modern ipairs probes numeric slots directly instead of honoring __ipairs.
    -- null has no sequence entries, but named access still propagates null.
    if (type(k) == "number") then
        vRet = nil;
    end

    return vRet;
end


local function le(l, r)
    local sLType = type(l);
    local sRType = type(r);
    return (sLType == "null" and sRType ~= "nil") or (sLType == sRType);
end


local function len()
    return 0;
end


local function lt(l, r)
    local sRType = type(r);
    return type(l) == "null" and sRType ~= "null" and sRType ~= "nil";
end


local function nullval() return null; end

-- null has no entries. Return a real iterator rather than the callable null
-- object, which is a placeholder rather than an iteration protocol.
local function iterate()
    return dummy, null, nil;
end


local function tostr()
    return "null";
end

local _tMethods = {
    clone = function()
        return null;
    end,
    serialize = function()
        return "null";
    end,
};

return setmetatable({},
{
    __add 		= nullval,
    __band 		= nullval,
    __bor 		= nullval,
    __bnot 		= nullval,
    __bxor 		= nullval,
    __call 		= dummy,
    __concat	= nullval,
    __div		= nullval,
    __eq 		= eq,
    __idiv		= nullval,
    __index = function(t, k)
        local vRet = _tMethods[k];

        if (vRet == nil) then
            vRet = index(t, k);
        end

        return vRet;
    end,
    __ipairs = iterate,
    __le		= le,
    __len 		= len,
    __lt		= lt,
    __mod		= nullval,
    --__mode,
    -- Expose type/lifecycle metadata for LuaEx without exposing the actual
    -- operator and assignment rules to callers.
    __metatable = {
        __type      = "null",
        __subtype   = "null",
        __name      = "null",
        __clone     = nullval,
        __serialize = tostr,
    },
    __mul		     = nullval,
    __name		     = "null",
    __newindex       = function()
        error("Cannot modify null.", 2);
    end,
    __pairs         = iterate,
    __pow		    = nullval,
    __shl  		    = nullval,
    __shr  		    = nullval,
    __sub		    = nullval,
    __subtype	    = "null",
    __tostring	    = tostr,
    __type		    = "null",
    __unm		    = nullval,
    __clone         = nullval,
    __serialize     = tostr,
});
