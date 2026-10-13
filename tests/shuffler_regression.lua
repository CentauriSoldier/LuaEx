if not LUAEX_INIT then require("LuaEx.init") end
local one = Shuffler({"only"});
assert(one.pop() == "only" and one.getRemaining() == 1);
one.setAutoReset(false);
assert(one.pop() == "only" and one.isEmpty() and one.pop() == nil);
assert(Shuffler().pop() == nil);
local s = Shuffler({"a", "b", false});
s.setAutoReset(false);
local drawn = s.pop();
assert(s.remove(drawn, true) and s.size() == 2);
s.reset();
for _, v in pairs(s) do assert(type(v) ~= type(drawn) or v ~= drawn); end
assert(s.isEmpty());
local r = Shuffler({"a", "b"});
assert(r.remove("a") and r.size() == 1 and r.getRemaining() == 1 and r.pop() == "b");
local deferred = Shuffler({"a", "b"});
deferred.setAutoReset(false);
assert(deferred.remove("a", true) and deferred.size() == 1 and deferred.getRemaining() == 1);
assert(deferred.pop() == "b" and deferred.pop() == nil);
local dup = Shuffler({"x", "x", false});
dup.setAutoReset(false);
assert(dup.remove("x", true) and dup.size() == 2 and dup.getRemaining() == 2);
local xs, falses = 0, 0;
for _, v in pairs(dup) do if v == false then falses = falses + 1 else xs = xs + 1; end end
assert(xs == 1 and falses == 1 and dup.isEmpty());
local auto = Shuffler({1,2,3});
local count, seen = 0, {};
for _, v in pairs(auto) do count = count + 1; assert(not seen[v]); seen[v] = true; end
assert(count == 3 and auto.getRemaining() == 3);
local iterator = select(1, pairs(auto));
assert(iterator() ~= nil);
auto.set({"new"});
assert(iterator() == nil and auto.getRemaining() == 1);
local input = {1,2};
local isolated = Shuffler(input);
input[1] = 99;
isolated.setAutoReset(false);
for _, v in pairs(isolated) do assert(v ~= 99); end
local replacement = Shuffler({"original"});
for _, invalid in ipairs({{[1]="a",[3]="c"},{named="x"},{[0]="x"},{[1.5]="x"},"bad",false}) do
    assert(not pcall(Shuffler, invalid));
    assert(not pcall(replacement.set, invalid));
    assert(replacement.size() == 1 and replacement.getRemaining() == 1);
end
assert(not replacement.add(nil));
assert(replacement.add(false, true) and replacement.size() == 2 and replacement.getRemaining() == 1);
replacement.reset();
assert(replacement.getRemaining() == 2);
replacement.purge();
assert(replacement.size() == 0 and replacement.pop() == nil);
assert(not pcall(replacement.add, "x", "false"));
print("PASS Shuffler: last/empty pop, enabled/disabled auto-reset, finite consumptive iteration, iterator invalidation, permanent removal, duplicates/false, bulk edits, dense input validation and atomic rejection");
