--[[!
@fqxn Tests.SerializerContract
@desc Core graph persistence checks. The historical filename is retained for the
    configured runner; this suite has no CoG dependency and writes no files.
!]]
if (not LUAEX_INIT) then require("LuaEx.load")(2); end
local _nChecks = 0;
local function check(bCondition, sMessage)
    assert(bCondition, sMessage);
    _nChecks = _nChecks + 1;
end
local function reject(fAction, sMessage)
    check(not pcall(fAction), sMessage);
end

local shared = {value = false};
local original = {left = shared, right = shared, text = "UTF-8 café", number = 1.25};
original.self = original;
local restored = deserialize(serialize(original));
check(restored ~= original and restored.self == restored, "Plain table cycle");
check(rawequal(restored.left, restored.right), "Shared table aliases");
check(restored.left.value == false and restored.text == original.text and restored.number == 1.25, "Scalar bytes/values");
restored.left.value = true;
check(original.left.value == false, "Independent restored table graph");

local function newCallbacks()
    local state = {count = 0};
    return function() state.count = state.count + 1; return state.count; end,
        function() return state.count; end;
end
local increment, current = newCallbacks();
local savedCallbacks = serialize({increment = increment, current = current});
local first, second = deserialize(savedCallbacks), deserialize(savedCallbacks);
check(first.increment() == 1 and first.current() == 1, "Shared closure upvalues");
check(second.current() == 0 and current() == 0, "Independent closure loads and original");

lxc.loadSources({["SerializerContract.lxc"] = [=[namespace SerializerContract {
    class Node {
        private label = "";
        public next = null;
        public callback = {};
        public Node(label) { this.label = label; }
        public read() { return this.label; }
        public compiledCallback() { return function() return this.label; end; }
    }
    class Owner {
        private class Hidden { public Hidden() {} }
        public static factory() { return Owner.Hidden; }
    }
}]=]}, _G);
local a, b = SerializerContract.Node("first"), SerializerContract.Node("second");
a.next, b.next = b, a;
a.callback[1] = increment;
local graph = {a = a, again = a, class = SerializerContract.Node};
local copy = deserialize(serialize(graph));
check(class.isinstanceof(copy.a, SerializerContract.Node) and copy.a.read() == "first", "Concrete class and private state");
check(rawequal(copy.a, copy.again) and rawequal(copy.a.next.next, copy.a), "Typed graph aliases and cycles");
check(rawequal(copy.class, SerializerContract.Node), "Canonical public class reference");
check(copy.a.callback[1]() == 1 and current() == 0, "Application callback captured state");
local save = serialize(copy);
local other = deserialize(save);
local independent = deserialize(save);
other.a.next = SerializerContract.Node("replacement");
check(independent.a.next.read() == "second" and copy.a.next.read() == "second", "Independent typed graph loads");
reject(function() return copy.a.label; end, "Private storage stays inaccessible");
reject(function() serialize(SerializerContract.Owner.factory()); end, "Hidden class reference cannot escape through persistence");
reject(function() serialize(a.compiledCallback()); end, "Compiled privileged closures are not application bytecode");

local q = Queue({false, 2});
local stack = Stack({false, 3});
local dictionary = SortedDictionary().add("shared", shared);
local tree = Tree("root");tree.Add(false);
local typed = deserialize(serialize({q = q, stack = stack, dictionary = dictionary, tree = tree}));
check(typed.q.dequeue() == false and typed.q.dequeue() == 2, "Queue false/order snapshot");
check(typed.stack.pop() == 3 and typed.stack.pop() == false, "Stack false/order snapshot");
check(typed.dictionary.get("shared").value == false, "Dictionary graph state");
check(typed.tree.Child(1).GetValue() == false and rawequal(typed.tree.Child(1).GetParent(), typed.tree), "Tree parent cycle");
check(typed.q.size() == 0 and q.size() == 2, "Original collection remains independent");

for _, value in ipairs({print, coroutine.create(function() end), io.stdout}) do
    reject(function() serialize(value); end, "Unsupported native function/thread/userdata rejected");
end
for _, sInvalid in ipairs({"not valid Lua", "{", "return broken(", "(}"}) do
    reject(function() deserialize(sInvalid); end, "Malformed saved input rejected: "..sInvalid);
end
print("PASS serializer contract: ".._nChecks.." graph checks.");
