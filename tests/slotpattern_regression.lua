if not LUAEX_INIT then require("LuaEx.init") end

local input = {{x = 0, y = 0}, {x = 0, y = 1}, {x = 1, y = 1}};
local pattern = SlotPattern(input);
assert(#pattern == 3 and pattern.getSlotCount() == 3);
assert(pattern.contains(0, 0) and not pattern.contains(1, 0));
local bounds = pattern.getBounds();
assert(bounds.width == 2 and bounds.height == 2);
input[1].x = 99;
assert(pattern.contains(0, 0));
local output = pattern.getSlots();
output[1].x = 88;
assert(pattern.contains(0, 0));
local copy = clone(pattern);
copy.setSlots({{x = -2, y = 3}});
assert(copy.getSlotCount() == 1 and pattern.getSlotCount() == 3);
local restored = deserialize(serialize(pattern));
assert(restored.getSlotCount() == 3 and restored.contains(1, 1));
local iterator = pattern.eachSlot();
pattern.setSlots({});
local count = 0;
for index, x, y in iterator do
    count = count + 1;
    assert(type(index) == "number" and type(x) == "number" and type(y) == "number");
end

assert(count == 3 and pattern.getBounds() == nil);
for _,bad in ipairs({{{x=0,y=0},{x=0,y=0}}, {{x=.5,y=0}}, {[2]={x=0,y=0}}, {{x=0}}, {{x=math.huge,y=0}}, {{x=0,y=0,z=1}}}) do
    assert(not pcall(pattern.setSlots, bad));
    assert(pattern.getSlotCount() == 0);
end

assert(SlotPattern().getSlotCount() == 0);
print("PASS SlotPattern: irregular count/layout, bounds, negative offsets, input/output isolation, stable iteration, cloning, serialization and atomic validation");
