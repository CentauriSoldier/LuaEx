// LuaEx-owned filesystem primitives. No shell or subprocess calls.
extern "C" {
#include <lua.h>
#include <lauxlib.h>
}
#include <cstring>
#include <filesystem>
#include <fstream>
#include <cerrno>
#if defined(_WIN32)
#include <windows.h>
#endif
#include <algorithm>
#include <string>
#include <vector>
#include <system_error>
namespace fs = std::filesystem;

static fs::path pathArgument(lua_State *L, int index) {
    size_t length = 0;
    const char *text = luaL_checklstring(L, index, &length);
    luaL_argcheck(L, length > 0 && std::memchr(text, '\0', length) == nullptr,
                  index, "Expected a nonempty UTF-8 path without NUL bytes.");
    return fs::u8path(text, text + length);
}
static int failure(lua_State *L, const std::error_code &error) {
    lua_pushnil(L);
    lua_pushstring(L, error.message().c_str());
    lua_pushinteger(L, error.value());
    return 3;
}
static void textField(lua_State *L, const char *name, const std::string &text) {
    lua_pushlstring(L, text.data(), text.size()); lua_setfield(L, -2, name);
}
static int statPath(lua_State *L) {
    const fs::path path = pathArgument(L, 1);
    std::error_code error;
    const auto link = fs::symlink_status(path, error);
    if (error) return failure(L, error);
    auto status = fs::status(path, error);
    bool dangling = fs::is_symlink(link) && (error == std::errc::no_such_file_or_directory || !fs::exists(status));
    if (error && !dangling) return failure(L, error);
    error.clear();
    if (!fs::exists(status) && !dangling) return failure(L, std::make_error_code(std::errc::no_such_file_or_directory));
    const auto identity = dangling ? fs::weakly_canonical(path, error) : fs::canonical(path, error);
    if (error) return failure(L, error);
    lua_newtable(L);
    textField(L, "Kind", dangling ? "link" : fs::is_directory(status) ? "directory" : fs::is_regular_file(status) ? "file" : "other");
    textField(L, "Identity", identity.u8string());
    bool isLink = fs::is_symlink(link);
#if defined(_WIN32)
    const DWORD attributes = GetFileAttributesW(path.c_str());
    isLink = attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
#endif
    lua_pushboolean(L, isLink); lua_setfield(L, -2, "Link");
    lua_pushinteger(L, static_cast<unsigned>(status.permissions()) & 0777); lua_setfield(L, -2, "Permissions");
    return 1;
}
static int listPath(lua_State *L) {
    const fs::path path = pathArgument(L, 1);
    const bool metadata = lua_toboolean(L, 2) != 0;
    std::error_code error;
    // Resolve the parent once. Ordinary children then inherit its canonical path.
    const auto parent = metadata ? fs::canonical(path, error) : fs::path();
    if (error) return failure(L, error);
    fs::directory_iterator iterator(path, error), end;
    if (error) return failure(L, error);
    std::vector<fs::directory_entry> entries;
    while (iterator != end) {
        entries.push_back(*iterator); // Retain metadata cached during enumeration.
        iterator.increment(error);
        if (error) return failure(L, error);
    }
    std::sort(entries.begin(), entries.end(), [](const fs::directory_entry &a, const fs::directory_entry &b) {
        return a.path().u8string() < b.path().u8string();
    });
    lua_createtable(L, static_cast<int>(entries.size()), 0);
    lua_Integer index = 0;
    for (const auto &entry : entries) {
        lua_newtable(L);
        textField(L, "Name", entry.path().filename().u8string());
        textField(L, "Path", fs::absolute(entry.path()).lexically_normal().u8string());
        if (metadata) {
            const auto link = entry.symlink_status(error);
            if (error) return failure(L, error);
            // Nonordinary types include Windows junctions as well as symlinks.
            const bool resolve = !fs::is_directory(link) && !fs::is_regular_file(link);
            auto status = resolve ? entry.status(error) : link;
            const bool dangling = resolve && (error == std::errc::no_such_file_or_directory || !fs::exists(status));
            if (error && !dangling) return failure(L, error);
            error.clear();
            auto identity = parent / entry.path().filename();
            if (resolve) identity = dangling ? fs::weakly_canonical(entry.path(), error) : fs::canonical(entry.path(), error);
            if (error) return failure(L, error);
            textField(L, "Kind", dangling ? "link" : fs::is_directory(status) ? "directory" : fs::is_regular_file(status) ? "file" : "other");
            textField(L, "Identity", identity.u8string());
        }
        lua_rawseti(L, -2, ++index);
    }
    return 1;
}
static int mkdirPath(lua_State *L) {
    const auto path = pathArgument(L, 1);
    std::error_code error;
    fs::create_directories(path, error);
    if (error) return failure(L, error);
    lua_pushboolean(L, 1); return 1;
}
static int copyPath(lua_State *L) {
    const auto source = pathArgument(L, 1);
    auto destination = pathArgument(L, 2);
    std::error_code error;
    if (fs::is_directory(destination, error)) destination /= source.filename();
    error.clear();
    fs::copy_file(source, destination, fs::copy_options::overwrite_existing, error);
    if (error) return failure(L, error);
    lua_pushboolean(L, 1); return 1;
}
static int movePath(lua_State *L) {
    const auto source = pathArgument(L, 1);
    auto destination = pathArgument(L, 2);
    std::error_code error;
    if (fs::is_directory(destination, error)) destination /= source.filename();
    error.clear();
    fs::rename(source, destination, error);
    if (error == std::errc::cross_device_link) {
        error.clear();
        fs::copy_file(source, destination, fs::copy_options::overwrite_existing, error);
        if (!error) fs::remove(source, error);
    }
    if (error) return failure(L, error);
    lua_pushboolean(L, 1); return 1;
}
static int deletePath(lua_State *L) {
    const auto path = pathArgument(L, 1);
    std::error_code error;
    const auto status = fs::symlink_status(path, error);
    if (error) return failure(L, error);
    if (fs::is_directory(status)) return failure(L, std::make_error_code(std::errc::is_a_directory));
    if (!fs::remove(path, error) && !error) error = std::make_error_code(std::errc::no_such_file_or_directory);
    if (error) return failure(L, error);
    lua_pushboolean(L, 1); return 1;
}
static bool isLinkPath(const fs::path &path, const fs::file_status &status) {
#if defined(_WIN32)
    const DWORD attributes = GetFileAttributesW(path.c_str());
    return fs::is_symlink(status) || (attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_REPARSE_POINT) != 0);
#else
    (void)path;
    return fs::is_symlink(status);
#endif
}
static void removeTree(const fs::path &path, std::error_code &error) {
    const auto status = fs::symlink_status(path, error);
    if (error) return;
    if (fs::is_directory(status) && !isLinkPath(path, status)) {
        fs::directory_iterator iterator(path, error), end;
        if (error) return;
        while (iterator != end) {
            const auto child = iterator->path();
            iterator.increment(error);
            if (error) return;
            removeTree(child, error);
            if (error) return;
        }
    }
    fs::remove(path, error);
}
static int rmdirPath(lua_State *L) {
    const auto path = pathArgument(L, 1);
    std::error_code error;
    const auto status = fs::symlink_status(path, error);
    if (error) return failure(L, error);
    if (!fs::is_directory(status) && !fs::is_symlink(status)) return failure(L, std::make_error_code(std::errc::not_a_directory));
    const auto resolved = fs::weakly_canonical(path, error);
    if (error) return failure(L, error);
    const auto current = fs::current_path(error);
    if (error) return failure(L, error);
    if (resolved == resolved.root_path() || resolved == current)
        return failure(L, std::make_error_code(std::errc::operation_not_permitted));
    removeTree(path, error); // Never descend into symlinks or Windows junctions.
    if (error) return failure(L, error);
    lua_pushboolean(L, 1); return 1;
}
static int chmodPath(lua_State *L) {
    const auto path = pathArgument(L, 1);
    const lua_Integer mode = luaL_checkinteger(L, 2);
    luaL_argcheck(L, mode >= 0 && mode <= 0777, 2, "Mode must be in 000..777 octal.");
    std::error_code error;
    fs::permissions(path, static_cast<fs::perms>(mode), fs::perm_options::replace, error);
    if (error) return failure(L, error);
    lua_pushboolean(L, 1); return 1;
}
static int rootPath(lua_State *L) {
    std::error_code error;
    const auto path = fs::current_path(error);
    if (error) return failure(L, error);
    const auto root = path.root_path().u8string();
    lua_pushlstring(L, root.data(), root.size()); return 1;
}
static int readPath(lua_State *L) {
    const auto path = pathArgument(L, 1);
    std::ifstream stream(path, std::ios::binary | std::ios::ate);
    if (!stream) return failure(L, std::error_code(errno ? errno : EIO, std::generic_category()));
    const auto length = stream.tellg();
    if (length < 0 || length > 1073741824) return failure(L, std::make_error_code(std::errc::file_too_large));
    std::string data(static_cast<size_t>(length), '\0');
    stream.seekg(0);
    if (length && !stream.read(&data[0], length)) return failure(L, std::make_error_code(std::errc::io_error));
    lua_pushlstring(L, data.data(), data.size()); return 1;
}
static int writePath(lua_State *L) {
    size_t length = 0;
    const char *data = luaL_checklstring(L, 2, &length);
    const auto path = pathArgument(L, 1);
    std::ofstream stream(path, std::ios::binary | std::ios::trunc);
    if (!stream) return failure(L, std::error_code(errno ? errno : EIO, std::generic_category()));
    stream.write(data, static_cast<std::streamsize>(length)); stream.close();
    if (!stream) return failure(L, std::make_error_code(std::errc::io_error));
    lua_pushboolean(L, 1); return 1;
}
// Keep C++ failures inside the native boundary; no exception may cross Lua's C API.
template<lua_CFunction Function> static int checked(lua_State *L) {
    if constexpr (Function != rootPath) {
        size_t length = 0;
        luaL_checktype(L, 1, LUA_TSTRING);
        const char *text = luaL_checklstring(L, 1, &length);
        luaL_argcheck(L, length > 0 && std::memchr(text, '\0', length) == nullptr, 1, "Expected a nonempty path without NUL bytes.");
        if constexpr (Function == copyPath || Function == movePath) {
            luaL_checktype(L, 2, LUA_TSTRING);
            text = luaL_checklstring(L, 2, &length);
            luaL_argcheck(L, length > 0 && std::memchr(text, '\0', length) == nullptr, 2, "Expected a nonempty path without NUL bytes.");
        }
        if constexpr (Function == chmodPath) {
            const lua_Integer mode = luaL_checkinteger(L, 2);
            luaL_argcheck(L, mode >= 0 && mode <= 0777, 2, "Mode must be in 000..777 octal.");
        }
        if constexpr (Function == listPath) {
            if (!lua_isnoneornil(L, 2)) luaL_checktype(L, 2, LUA_TBOOLEAN);
        }
        if constexpr (Function == writePath) luaL_checktype(L, 2, LUA_TSTRING);
    }
    try { return Function(L); }
    catch (const std::exception &error) { lua_pushnil(L); lua_pushstring(L, error.what()); return 2; }
}
#if defined(_WIN32)
#define LUAEX_EXPORT extern "C" __declspec(dllexport)
#else
#define LUAEX_EXPORT extern "C" __attribute__((visibility("default")))
#endif
LUAEX_EXPORT int luaopen_luaex_io(lua_State *L) {
    const luaL_Reg functions[] = {
        {"read", checked<readPath>}, {"write", checked<writePath>}, {"stat", checked<statPath>}, {"list", checked<listPath>}, {"mkdir", checked<mkdirPath>},
        {"copy", checked<copyPath>}, {"move", checked<movePath>}, {"delete", checked<deletePath>},
        {"rmdir", checked<rmdirPath>}, {"chmod", checked<chmodPath>}, {"root", checked<rootPath>}, {nullptr, nullptr}
    };
    luaL_checkversion(L); luaL_newlib(L, functions);
    lua_pushinteger(L, 1); lua_setfield(L, -2, "Version");
#if defined(_WIN32)
    lua_pushliteral(L, "windows");
#elif defined(__APPLE__)
    lua_pushliteral(L, "macos");
#else
    lua_pushliteral(L, "linux");
#endif
    lua_setfield(L, -2, "Platform");
    return 1;
}
