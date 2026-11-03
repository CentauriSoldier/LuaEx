/* Lua 5.4 accelerators over the production runtime's private Lua records.
   Public objects remain table facades. No parallel storage or class registry. */
#include <lua.h>
#include <lauxlib.h>
#include <string.h>

static void field(lua_State *L, int table, const char *name) {
    table = lua_absindex(L, table);
    lua_pushstring(L, name);
    lua_rawget(L, table);
}

static int flag(lua_State *L, int table, const char *name) {
    int value;
    field(L, table, name); value = lua_toboolean(L, -1); lua_pop(L, 1);
    return value;
}

static void alive(lua_State *L, int state) {
    if (flag(L, state, "Failed")) luaL_error(L, "Instance belongs to a failed load or construction.");
    field(L, state, "Class");
    if (flag(L, -1, "Discarded")) luaL_error(L, "Instance belongs to a failed load or construction.");
    lua_pop(L, 1);
}

/* Only already-established, mutable primitive slots use this branch. Every
   other assignment returns to the original Lua writer, before any mutation. */
static int write_scalar(lua_State *L, int slot, int value) {
    int type = lua_type(L, value), updates;
    const char *expected;
    lua_Integer index, count;
    slot = lua_absindex(L, slot); value = lua_absindex(L, value);
    if (type != LUA_TNUMBER && type != LUA_TSTRING && type != LUA_TBOOLEAN) return 0;
    if (flag(L, slot, "Locked")) return 0;
    field(L, slot, "Type");
    expected = lua_type(L, -1) == LUA_TSTRING ? lua_tostring(L, -1) : NULL;
    if (!expected || strcmp(expected, lua_typename(L, type)) != 0) { lua_pop(L, 1); return 0; }
    lua_pop(L, 1);
    field(L, slot, "Member"); field(L, -1, "Flags");
    if (flag(L, -1, "const") || flag(L, -1, "final")) { lua_pop(L, 2); return 0; }
    lua_pop(L, 2);
    lua_pushliteral(L, "Value"); lua_pushvalue(L, value); lua_rawset(L, slot);
    lua_pushliteral(L, "Locked"); lua_pushboolean(L, 0); lua_rawset(L, slot);
    field(L, slot, "GetterUpdates");
    if (lua_istable(L, -1)) {
        updates = lua_gettop(L); count = (lua_Integer)lua_rawlen(L, updates);
        for (index = 1; index <= count; ++index) {
            lua_rawgeti(L, updates, index); lua_pushvalue(L, value); lua_call(L, 1, 0);
        }
    }
    lua_pop(L, 1);
    return 1;
}

static int setter(lua_State *L) {
    alive(L, lua_upvalueindex(1));
    if (lua_gettop(L) == 0) lua_pushnil(L);
    if (!write_scalar(L, lua_upvalueindex(2), 1)) {
        lua_pushvalue(L, lua_upvalueindex(3)); lua_pushvalue(L, lua_upvalueindex(2));
        lua_pushvalue(L, 1); lua_pushboolean(L, 0); lua_call(L, 3, 0);
    }
    return 0;
}

static int bind_setter(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE); luaL_checktype(L, 2, LUA_TTABLE);
    luaL_checktype(L, 3, LUA_TFUNCTION); lua_settop(L, 3);
    lua_pushcclosure(L, setter, 3); return 1;
}

static int cached_slot(lua_State *L, int state, int fields, int key) {
    state = lua_absindex(L, state); fields = lua_absindex(L, fields); key = lua_absindex(L, key);
    lua_pushvalue(L, key); lua_rawget(L, fields);
    if (lua_isnil(L, -1)) { lua_pop(L, 1); return 0; }
    field(L, state, "Values"); lua_pushvalue(L, -2); lua_rawget(L, -2);
    lua_remove(L, -2); lua_remove(L, -2);
    if (!lua_istable(L, -1)) { lua_pop(L, 1); return 0; }
    return 1;
}

/* Preserve yielding Lua property/operator callbacks across the C dispatcher.
   The saved stack base excludes internal records from returned Lua results. */
static int results(lua_State *L, int status, lua_KContext context) {
    (void)status;
    return lua_gettop(L) - (int)context;
}

/* Shared C metamethods remove only the generic Lua dispatch frames. Checked
   Lua handlers still own all cold, restricted, property and operator cases. */
static int facade_index(lua_State *L) {
    int handler, state, fields, base;
    lua_settop(L, 2); lua_pushvalue(L, 1); lua_rawget(L, lua_upvalueindex(1));
    if (!lua_istable(L, -1)) return luaL_error(L, "Unknown LXC reference.");
    handler = lua_gettop(L); field(L, handler, "NativeState");
    if (lua_istable(L, -1)) {
        state = lua_gettop(L);
        field(L, handler, "NativeMethods"); lua_pushvalue(L, 2); lua_rawget(L, -2);
        if (!lua_isnil(L, -1)) { alive(L, state); return 1; }
        lua_pop(L, 2); field(L, handler, "NativeFields"); fields = lua_gettop(L);
        if (cached_slot(L, state, fields, 2)) {
            alive(L, state); field(L, -1, "Value"); return 1;
        }
    }
    base = lua_gettop(L); field(L, handler, "__index");
    if (!lua_toboolean(L, -1)) return luaL_error(L, "Unsupported LXC reference operation: __index");
    lua_pushvalue(L, 2); lua_callk(L, 1, LUA_MULTRET, (lua_KContext)base, results);
    return results(L, LUA_OK, (lua_KContext)base);
}

static int facade_newindex(lua_State *L) {
    int handler, state, fields, base;
    lua_settop(L, 3); lua_pushvalue(L, 1); lua_rawget(L, lua_upvalueindex(1));
    if (!lua_istable(L, -1)) return luaL_error(L, "Unknown LXC reference.");
    handler = lua_gettop(L); field(L, handler, "NativeState");
    if (lua_istable(L, -1)) {
        state = lua_gettop(L); alive(L, state);
        field(L, handler, "NativeFields"); fields = lua_gettop(L);
        if (cached_slot(L, state, fields, 2) && write_scalar(L, -1, 3)) return 0;
    }
    base = lua_gettop(L); field(L, handler, "__newindex");
    if (!lua_toboolean(L, -1)) return luaL_error(L, "Unsupported LXC reference operation: __newindex");
    lua_pushvalue(L, 2); lua_pushvalue(L, 3); lua_callk(L, 2, LUA_MULTRET, (lua_KContext)base, results);
    return results(L, LUA_OK, (lua_KContext)base);
}

static int dispatchers(lua_State *L) {
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_pushvalue(L, 1); lua_pushcclosure(L, facade_index, 1);
    lua_pushvalue(L, 1); lua_pushcclosure(L, facade_newindex, 1);
    return 2;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
int luaopen_lxc_hybrid(lua_State *L) {
    static const luaL_Reg functions[] = {
        {"setter", bind_setter}, {"dispatchers", dispatchers}, {NULL, NULL}
    };
    luaL_checkversion(L); luaL_newlib(L, functions);
    lua_pushinteger(L, 1); lua_setfield(L, -2, "Version");
    lua_pushboolean(L, 1); lua_setfield(L, -2, "Available");
    return 1;
}
