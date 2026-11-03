/* Isolated Lua 5.4 C backend prototype. No production runtime replacement. */
#include <lua.h>
#include <lauxlib.h>
#include <stddef.h>

#define CLASS_MT "lxc.native.prototype.class"
#define OBJECT_MT "lxc.native.prototype.object"
#define TOKEN_MT "lxc.native.prototype.authority"
#define VIEW_MT "lxc.native.prototype.view"

typedef struct { int fields; int ready; int failed; } Class;
typedef struct { int type; int integer; union { lua_Integer i; lua_Number n; int b; } value; } Slot;
typedef struct { Class *owner; int failed; Slot slots[]; } Object;

static Object *object_at(lua_State *L, int index) {
    return (Object *)luaL_checkudata(L, index, OBJECT_MT);
}
static void alive(lua_State *L, Object *object) {
    if (object->failed || object->owner->failed) luaL_error(L, "Instance belongs to a failed construction or class.");
}
static Class *authority(lua_State *L, int index) {
    Class **token = (Class **)luaL_checkudata(L, index, TOKEN_MT);
    return *token;
}
static void push_class(lua_State *L, int object) { lua_getiuservalue(L, object, 1); }
static void push_descriptor(lua_State *L, int class_index) { lua_getiuservalue(L, class_index, 1); }

/* Values stay in C slots; strings are also rooted in a Lua-managed uservalue. */
static void store(lua_State *L, Object *object, int object_index, int slot, int value, int initial) {
    Slot *target;
    int type = lua_type(L, value);
    if (slot < 1 || slot > object->owner->fields) luaL_error(L, "Invalid native field slot.");
    target = &object->slots[slot - 1];
    if (type != LUA_TNUMBER && type != LUA_TSTRING && type != LUA_TBOOLEAN) {
        if (initial) object->failed = 1;
        luaL_error(L, "Prototype fields accept only numbers, strings and booleans.");
    }
    if (!initial && target->type != type) luaL_error(L, "Typed field cannot change type.");
    target->type = type;
    if (type == LUA_TNUMBER) {
        target->integer = lua_isinteger(L, value);
        if (target->integer) target->value.i = lua_tointeger(L, value);
        else target->value.n = lua_tonumber(L, value);
    } else if (type == LUA_TBOOLEAN) target->value.b = lua_toboolean(L, value);
    else {
        lua_getiuservalue(L, object_index, 2);
        lua_pushvalue(L, value);
        lua_rawseti(L, -2, slot);
        lua_pop(L, 1);
    }
}
static int push_slot(lua_State *L, Object *object, int object_index, int slot) {
    Slot *source;
    if (slot < 1 || slot > object->owner->fields) return luaL_error(L, "Invalid native field slot.");
    source = &object->slots[slot - 1];
    switch (source->type) {
    case LUA_TNUMBER:
        if (source->integer) lua_pushinteger(L, source->value.i);
        else lua_pushnumber(L, source->value.n);
        break;
    case LUA_TBOOLEAN: lua_pushboolean(L, source->value.b); break;
    case LUA_TSTRING:
        lua_getiuservalue(L, object_index, 2);
        lua_rawgeti(L, -1, slot);
        lua_remove(L, -2);
        break;
    default: return luaL_error(L, "Field read before initialization.");
    }
    return 1;
}
static int getter(lua_State *L) {
    Object *object = object_at(L, lua_upvalueindex(1));
    int slot = (int)lua_tointeger(L, lua_upvalueindex(2));
    alive(L, object);
    return push_slot(L, object, lua_upvalueindex(1), slot);
}
/* Compiler-selected single-assignment methods need no Lua frame or lexical view.
   Keep the same bounds, primitive-type and failed-state checks as ordinary writes. */
static int setter(lua_State *L) {
    Object *object = object_at(L, lua_upvalueindex(1));
    int slot = (int)lua_tointeger(L, lua_upvalueindex(2));
    alive(L, object);
    store(L, object, lua_upvalueindex(1), slot, 1, 0);
    return 0;
}
static int method_call(lua_State *L) {
    Object *object = object_at(L, lua_upvalueindex(1));
    int count = lua_gettop(L), i;
    alive(L, object);
    luaL_checkstack(L, count + 8, "Native method argument stack overflow.");
    lua_pushvalue(L, lua_upvalueindex(2));
    lua_pushvalue(L, lua_upvalueindex(1));
    lua_pushnil(L); /* base: inheritance is deliberately unsupported. */
    lua_pushnil(L); /* accessor backing field: properties unsupported. */
    for (i = 1; i <= count; ++i) lua_pushvalue(L, i);
    lua_call(L, count + 3, LUA_MULTRET);
    return lua_gettop(L) - count;
}
static int index_object(lua_State *L, int internal) {
    Object *object;
    int instance = 1, class_index, descriptor, record, slot;
    const char *name = luaL_checkstring(L, 2);
    if (internal) { lua_getiuservalue(L, 1, 1); instance = lua_gettop(L); }
    object = object_at(L, instance);
    alive(L, object);
    lua_getiuservalue(L, instance, 3); /* Stable public bound-method cache. */
    lua_pushvalue(L, 2); lua_rawget(L, -2);
    if (!lua_isnil(L, -1)) return 1;
    lua_pop(L, 2);
    push_class(L, instance); class_index = lua_gettop(L);
    push_descriptor(L, class_index); descriptor = lua_gettop(L);
    lua_getfield(L, descriptor, "methods"); lua_pushvalue(L, 2); lua_rawget(L, -2);
    if (lua_istable(L, -1)) {
        record = lua_gettop(L);
        lua_getfield(L, record, "getter"); slot = (int)lua_tointeger(L, -1); lua_pop(L, 1);
        lua_pushvalue(L, instance);
        if (slot) { lua_pushinteger(L, slot); lua_pushcclosure(L, getter, 2); }
        else {
            lua_getfield(L, record, "setter"); slot = (int)lua_tointeger(L, -1); lua_pop(L, 1);
            if (slot) { lua_pushinteger(L, slot); lua_pushcclosure(L, setter, 2); }
            else { lua_getfield(L, record, "fn"); lua_pushcclosure(L, method_call, 2); }
        }
        lua_getiuservalue(L, instance, 3); lua_pushvalue(L, 2); lua_pushvalue(L, -3); lua_rawset(L, -3); lua_pop(L, 1);
        return 1;
    }
    lua_getfield(L, descriptor, "fields"); lua_pushvalue(L, 2); lua_rawget(L, -2);
    if (!lua_istable(L, -1)) return luaL_error(L, "Unknown prototype member: %s", name);
    record = lua_gettop(L);
    lua_getfield(L, record, "public");
    if (!internal && !lua_toboolean(L, -1)) return luaL_error(L, "Cannot access private member: %s", name);
    lua_pop(L, 1); lua_getfield(L, record, "slot"); slot = (int)lua_tointeger(L, -1);
    return push_slot(L, object, instance, slot);
}
static int object_index(lua_State *L) { return index_object(L, 0); }
static int view_index(lua_State *L) { return index_object(L, 1); }
static int assign_object(lua_State *L, int internal) {
    int instance = 1, slot, record;
    Object *object;
    const char *name = luaL_checkstring(L, 2);
    if (internal) { lua_getiuservalue(L, 1, 1); instance = lua_gettop(L); }
    object = object_at(L, instance); alive(L, object);
    push_class(L, instance); push_descriptor(L, -1);
    lua_getfield(L, -1, "fields"); lua_pushvalue(L, 2); lua_rawget(L, -2);
    if (!lua_istable(L, -1)) return luaL_error(L, "Unknown or immutable prototype member: %s", name);
    record = lua_gettop(L); lua_getfield(L, record, "public");
    if (!internal && !lua_toboolean(L, -1)) return luaL_error(L, "Cannot write private member: %s", name);
    lua_pop(L, 1); lua_getfield(L, record, "slot"); slot = (int)lua_tointeger(L, -1);
    store(L, object, instance, slot, 3, 0);
    return 0;
}
static int object_newindex(lua_State *L) { return assign_object(L, 0); }
static int view_newindex(lua_State *L) { return assign_object(L, 1); }
static int read_known(lua_State *L) {
    Object *object = object_at(L, 1);
    Class *owner = *(Class **)lua_touserdata(L, lua_upvalueindex(1));
    lua_Integer selected = luaL_checkinteger(L, 2);
    int slot;
    alive(L, object);
    if (object->owner != owner) return luaL_error(L, "Foreign receiver for lexical field read.");
    lua_rawgeti(L, lua_upvalueindex(2), selected); slot = (int)luaL_checkinteger(L, -1); lua_pop(L, 1);
    return push_slot(L, object, 1, slot);
}
static int lexical_view(lua_State *L) {
    Object *object = object_at(L, 1);
    Class *owner = *(Class **)lua_touserdata(L, lua_upvalueindex(1));
    alive(L, object);
    if (object->owner != owner) return luaL_error(L, "Foreign receiver for lexical view.");
    lua_newuserdatauv(L, 1, 1); lua_pushvalue(L, 1); lua_setiuservalue(L, -2, 1); luaL_setmetatable(L, VIEW_MT);
    return 1;
}
static int make_scope(lua_State *L) {
    authority(L, 1); luaL_checktype(L, 2, LUA_TTABLE);
    lua_pushvalue(L, 1); lua_pushvalue(L, 2); lua_pushcclosure(L, read_known, 2);
    lua_pushvalue(L, 1); lua_pushcclosure(L, lexical_view, 1);
    return 2;
}
static int construct(lua_State *L) {
    Class *owner = (Class *)luaL_checkudata(L, 1, CLASS_MT);
    int arguments = lua_gettop(L) - 1, instance, descriptor, i, status;
    Object *object;
    if (!owner->ready || owner->failed) return luaL_error(L, "Native class is unavailable.");
    luaL_checkstack(L, arguments + 12, "Native constructor argument stack overflow.");
    object = (Object *)lua_newuserdatauv(L, sizeof(Object) + sizeof(Slot) * (size_t)owner->fields, 3);
    object->owner = owner; object->failed = 0; instance = lua_gettop(L);
    for (i = 0; i < owner->fields; ++i) object->slots[i].type = LUA_TNONE;
    lua_pushvalue(L, 1); lua_setiuservalue(L, instance, 1);
    lua_newtable(L); lua_setiuservalue(L, instance, 2);
    lua_newtable(L); lua_setiuservalue(L, instance, 3);
    luaL_setmetatable(L, OBJECT_MT);
    push_descriptor(L, 1); descriptor = lua_gettop(L);
    lua_getfield(L, descriptor, "initializers");
    for (i = 1; i <= owner->fields; ++i) {
        lua_rawgeti(L, -1, i); lua_pushvalue(L, instance);
        status = lua_pcall(L, 1, 1, 0);
        if (status != LUA_OK) { object->failed = 1; return lua_error(L); }
        store(L, object, instance, i, lua_gettop(L), 1); lua_pop(L, 1);
    }
    lua_pop(L, 1); lua_getfield(L, descriptor, "constructor");
    if (!lua_isnil(L, -1)) {
        lua_pushvalue(L, instance); lua_pushnil(L); lua_pushnil(L);
        for (i = 2; i <= arguments + 1; ++i) lua_pushvalue(L, i);
        status = lua_pcall(L, arguments + 3, 0, 0);
        if (status != LUA_OK) { object->failed = 1; return lua_error(L); }
    } else lua_pop(L, 1);
    lua_pushvalue(L, instance); return 1;
}
static int define(lua_State *L) {
    Class *owner; Class **token;
    luaL_checktype(L, 1, LUA_TTABLE);
    lua_getfield(L, 1, "count");
    lua_Integer count = luaL_checkinteger(L, -1); lua_pop(L, 1);
    if (count < 0 || count > 1024) return luaL_error(L, "Invalid prototype field count.");
    owner = (Class *)lua_newuserdatauv(L, sizeof(Class), 1);
    owner->fields = (int)count; owner->ready = 0; owner->failed = 0;
    lua_pushvalue(L, 1); lua_setiuservalue(L, -2, 1); luaL_setmetatable(L, CLASS_MT);
    token = (Class **)lua_newuserdatauv(L, sizeof(Class *), 1); *token = owner;
    lua_pushvalue(L, -2); lua_setiuservalue(L, -2, 1); luaL_setmetatable(L, TOKEN_MT);
    return 2;
}
static int seal(lua_State *L) { Class *owner = authority(L, 1); owner->ready = 1; return 0; }
static int invalidate(lua_State *L) { Class *owner = authority(L, 1); owner->failed = 1; return 0; }
static void metatable(lua_State *L, const char *name, lua_CFunction index, lua_CFunction assign, lua_CFunction call) {
    luaL_newmetatable(L, name);
    lua_pushliteral(L, "locked native prototype"); lua_setfield(L, -2, "__metatable");
    if (index) { lua_pushcfunction(L, index); lua_setfield(L, -2, "__index"); }
    if (assign) { lua_pushcfunction(L, assign); lua_setfield(L, -2, "__newindex"); }
    if (call) { lua_pushcfunction(L, call); lua_setfield(L, -2, "__call"); }
    lua_pop(L, 1);
}
#if defined(_WIN32)
__declspec(dllexport)
#endif
int luaopen_lxc_native(lua_State *L) {
    static const luaL_Reg functions[] = {{"define", define}, {"scope", make_scope}, {"seal", seal}, {"invalidate", invalidate}, {NULL, NULL}};
    luaL_checkversion(L);
    metatable(L, CLASS_MT, NULL, NULL, construct);
    metatable(L, OBJECT_MT, object_index, object_newindex, NULL);
    metatable(L, VIEW_MT, view_index, view_newindex, NULL);
    metatable(L, TOKEN_MT, NULL, NULL, NULL);
    luaL_newlib(L, functions);
    return 1;
}
