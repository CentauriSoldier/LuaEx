--[[!
@fqxn LuaEx.Libraries.null
@desc <p>The <code>null</code> value represents a special type in the LuaEx library that acts as a placeholder.
      It provides a consistent way to handle "null" values without using the standard <code>nil</code> value.
      One of the primary purposes of <code>null</code> is to retain table keys while giving the value no meaningful value.
      The <code>null</code> type is designed to behave like an object, allowing for custom behavior
      when interacting with it using Lua's metatables.</p>

      <p>Instances of <code>null</code> can be compared and manipulated with various operations,
      and it is crucial not to localize <code>null</code> as it can lead to unexpected behavior.</p>
@ex
-- Equality Check:
print(NULL == null) -- Output: true
print(null == nil)  -- Output: false

-- Assign null to a variable and check its type
local a = null
print(type(a))           -- Output: "null"

-- Table Usage:
local myTable = {
    key1 = null, -- Retaining key 'key1' with no meaningful value
    key2 = "null"  -- Retaining key 'key2' with no meaningful value
}
print(myTable.key1 == null) -- Output: true
print(myTable.key2 == null) -- Output: false


-- String Representation:
print(tostring(null)) -- Output: "null"

-- Length Check:
local myKeys = { [1] = null, [2] = null }
print(#myKeys) -- Output: 2 (length check for table with null values)
!]]

local type 			= type;
local setmetatable 	= setmetatable;

local function dummy() end

local function eq(l, r)
    return type(l) == type(r)
end


local function index(t, k)
    return null;
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


local function tostr()
    return "null";
end

return setmetatable({
    clone = function()
        return "null";
    end,
    serialize = function()
        return "null";
    end,
},
{
    __add 		= nullval,
    __band 		= nullval,
    __bor 		= nullval,
    __bnot 		= nullval,
    __bxor 		= nullval,
    __call 		= dummy,
    __close 	= false,
    __concat	= nullval,
    __div		= nullval,
    __eq 		= eq,
    __gc		= false,
    __idiv		= nullval,
    __index 	= index,
    __ipairs	= nullval,
    __le		= le,
    __len 		= len,
    __lt		= lt,
    __mod		= nullval,
    --__mode,
    --__metatable	= nil,
    __mul		= nullval,
    __name		= "null",
    __newindex 	= dummy,
    __pairs		= nullval,
    __pow		= nullval,
    __shl  		= nullval,
    __shr  		= nullval,
    __sub		= nullval,
    __subtype	= "null",
    __tostring	= tostr,
    __type		= "null",
    __unm		= nullval,
});
