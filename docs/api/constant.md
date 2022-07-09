## 🇨​​​​​🇴​​​​​🇳​​​​​🇸​​​​​🇹​​​​​🇦​​​​​🇳​​​​​🇹​​​​​

Allows the creation of constants in Lua. Once set, these global values cannot be changed or deleted.

#### Usage Example
```lua
--constant(string, *)
constant("I_LOVE_LUA", "No you don't!");
constant("MAX_CHAIRS_ALLOWED", 42);
constant("THE_ANSWER_TO_THE_UNIVERSE_AND_EVERYTHING", MAX_CHAIRS_ALLOWED);

print(I_LOVE_LUA);
print(MAX_CHAIRS_ALLOWED);
print(THE_ANSWER_TO_THE_UNIVERSE_AND_EVERYTHING);

--try to break it by uncommenting one of the items below
--I_LOVE_LUA = "Yuhu!";
--I_LOVE_LUA = nil;

```

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
