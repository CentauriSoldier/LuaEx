--package.path = package.path..";LuaEx\\?.lua;..\\?.lua;?.lua";
package.path = package.path..";LuaEx\\?.lua";
require("init");

--protect("queue")
--base64 = 44;
--queue = 12;
--mq = queue();
--print(type(queue))

--constant = 14
--stack = 45

local s = set();
s:add(1);
s:add(2);
s:add(3);
s:add(4);
s:add(4);
s:add(4);

t = set();
t:add(1);
t:add(3);

print(tostring(t))

for v in s() do
	--print(v)
end
