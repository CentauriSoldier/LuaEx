# LuaEx native I/O

LuaEx keeps its `io.*` extensions. Its own C++17 filesystem module performs native
operations; text search and ZIP handling run in Lua. Runtime operations launch no
shells or child processes and require no third-party filesystem/archive library.
The Lua SDK used to build the module must match the host Lua ABI.

## Layout and automatic selection

- Source and build definition: `Native IO/` at the repository root.
- Runtime module: `LuaEx/bin/luaex_io-lua54-<system>-<architecture>.<extension>`.
- Public API: `LuaEx/hook/iohook.lua`; archive implementation: `LuaEx/lib/io/Archive.lua`.
- Previous hook: byte-identical backup in `legacy/LuaEx/hook/iohook.lua`.

Windows uses `.dll`; Linux and macOS use CMake module `.so` files. Targets are
`windows-x64`, `windows-arm64`, `linux-x64`, `linux-arm64`, `macos-x64` and
`macos-arm64`. LuaEx loads a compatible installed build automatically and reports
missing/incompatible binaries explicitly. There is no shell fallback.
Windows x64 with Lua 5.4.9 has been built and runtime-tested. The following
additional binaries were cross-built with Zig 0.15.2 and inspected for architecture,
Lua entry-point exports, expected host imports and system-library dependencies:

| Binary target | Deployment target | Runtime testing |
| --- | --- | --- |
| Linux x64 | glibc 2.28+ | Pending |
| Linux ARM64 | glibc 2.28+ | Pending |
| macOS x64 | macOS 10.15+ | Pending |
| macOS ARM64 | macOS 11+ | Pending |

These Linux binaries target glibc, not musl/Alpine. Cross-built modules resolve
Lua's C API from the loading host. The macOS ARM64 output includes an ad-hoc code
signature. Windows ARM64 is not built. Native execution on each target remains
necessary; binary inspection does not establish runtime compatibility.
`Cross Builds.json` records source/compiler/artifact hashes and validation details.
Standard-runtime license notices are in `Runtime Licenses/`.
Wasmoon/browser hosts cannot use this native module; previous browser snapshots
are historical.

## Build

Requires CMake 3.20+, a C++17 toolchain and Lua 5.4 development headers/library.
From the repository root, configure and build:

```
cmake -S "Native IO" -B build/native-io
cmake --build build/native-io --config Release
cmake --install build/native-io --config Release --prefix LuaEx/bin
```

CMake's FindLua locates an installed Lua SDK. To select an existing SDK explicitly,
pass `-DLUA_INCLUDE_DIR=<headers>` and `-DLUA_LIBRARY=<library>` when configuring.
For Visual Studio use `-A x64` or `-A ARM64`. On macOS build one architecture at a
time with `-DCMAKE_OSX_ARCHITECTURES=x86_64` or `arm64`. Cross-compilation requires
the appropriate compiler/sysroot and target Lua SDK; it is not verified here.
The MSVC C++ runtime is linked statically; the module links to the host Lua library.

## Discovery

LXC/LXE derive source roots from `package.path`. `SourceDiscovery` owns the
approved `.lxc`/`.lxe` whitelist and calls `io.scanfiles` once per startup batch.
Overlapping roots share a visited-directory set; each fresh request sees current
files without a persistent cache. No source registration is required. Sorted
canonical file paths avoid duplicate declarations from relative path aliases;
directory identities stop symlink/junction recursion cycles.

Native `list(path, true)` supplies `Kind` and `Identity` along with `Name` and
`Path`. The walker consumes these fields instead of calling native `stat` for
every entry. Directory-entry metadata is retained from enumeration; an ordinary
child's canonical identity is composed from its canonical parent and filename.
Links and nonordinary entries receive target resolution, including Windows
junctions and dangling links. Platforms may perform additional native metadata
queries when their directory iterator cannot cache the necessary information.
Extension matching uses the leaf filename directly. Standalone `stat` remains
available, and `list(path)` retains its original Name/Path-only result shape.
Filesystem changes during enumeration can race this snapshot; it is not an
atomic filesystem transaction.
`io.listdirs` returns absolute child directory paths, excluding the queried root.
Both listings return `{}` for empty success or `nil, reason` on failure. Callbacks
receive `(path, isFile)` and run after enumeration; callback side effects cannot
be rolled back if a later callback fails. Invalid arguments raise errors.

## Public operations and deliberate contract changes

- `exists`, `isdir`, `isfile`: native metadata checks; return a boolean and optional
  error details. Dangling symlinks exist but are neither regular files nor directories.
- `listfiles`, `listdirs`, `list`: sorted filesystem results, optional recursive
  traversal and callbacks. Extension matching is case-insensitive. Missing paths
  are failures, not empty successful results. Native path arguments allow literal
  shell metacharacters; NUL bytes are rejected.
- `mkdir`: creates parent directories. `copy`: copies one file, overwriting its
  destination; a directory destination receives the source basename. `move`:
  renames/moves, with regular-file cross-device copy/remove fallback. `delete`:
  removes a file or file link. `rmdir`: recursively removes a directory tree
  without descending into links/junctions; filesystem root and current directory
  removal are rejected. Mutations return `true` or `nil, reason, nativeCode`, not
  subprocess exit tuples. Partial mutations are possible on I/O errors.
- `chmod(permission, path)`: accepts numeric mode bits, octal text such as `755`,
  and symbolic `u/g/o/a` clauses with `+`, `-`, `=` and `rwx`. Windows filesystem
  permissions only support limited mode semantics. Windows ACL grant expressions
  are not accepted and this function does not promise Unix ACL equivalence.
- `findfile(filename, root)`: exact-name recursive search; optional root defaults
  to the current filesystem/drive root. Inaccessible branches are skipped.
- `findstr(text, path)`: literal line search. `grep(pattern, path)`: Lua-pattern
  line search, not POSIX regular expressions. A missing path argument reads stdin.
  Matches are written to stdout; return values are `(matched, count)` or
  `nil, reason` on failure. File reading is closed on callback/pattern errors.
- `zip(files, destination)`: writes a stored (uncompressed) ZIP with UTF-8 entry
  names using source basenames; duplicate names and ZIP64 output are rejected.
- `unzip(archive, destination)`: reads stored and DEFLATE entries (stored, fixed
  and dynamic Huffman blocks), validates sizes and CRCs before extraction, and
  rejects traversal paths, reserved device names, case-folded name collisions
  and archive symlinks. Existing output symlinks/junctions are rejected. Encryption,
  multi-volume, ZIP64 and other compression methods are unsupported and return an
  error. Limits: 256 MiB per entry, 1 GiB total extracted data, 1 GiB native reads.
  Extraction is not transactional. Search/archive helpers start no external tools.
- Existing lexical path helpers and standard Lua `io.open`, streams, etc. remain.
  Explicit calls to standard `io.popen` are still caller-requested subprocesses;
  none of the LuaEx extensions invoke it.

## Verification

`tests/io_listing_regression.lua` checks native filesystem behavior with
`os.execute` and `io.popen` replaced by failures. Independently generated archive
fixtures exercise all three DEFLATE block types. Run the suite with:

```
lua tests/run_case.lua io-listing
lua tests/run_case.lua io-discovery
```

Run the other loader levels and framework checks using `tests/run.lua` as usual.
A passing Windows run does not establish Linux/macOS or ARM64 support.

## Reproducing the cross-builds

The compiler is a build tool only; it is not packaged as a runtime dependency.
A portable Zig 0.15.2 compiler and Lua 5.4 headers were used. From this repository
root, the command shape is:

```
zig c++ -target <target> -std=c++17 -O2 -shared -fPIC -fvisibility=hidden -Wall -Wextra -Werror -I<lua-headers> "Native IO/Filesystem.cpp" -o LuaEx/bin/<module-name>.so
```

Targets: `x86_64-linux-gnu.2.28`, `aarch64-linux-gnu.2.28`,
`x86_64-macos.10.15`, `aarch64-macos.11.0`. For macOS add
`-Wl,-undefined,dynamic_lookup` so the loading Lua host supplies its C API.
Use the corresponding names `luaex_io-lua54-linux-x64.so`,
`luaex_io-lua54-linux-arm64.so`, `luaex_io-lua54-macos-x64.so`, and
`luaex_io-lua54-macos-arm64.so`. Do not link a second static Lua runtime into a
module. Revalidate binary symbols and run the I/O/discovery suites on the target.
