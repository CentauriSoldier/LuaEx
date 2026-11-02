# linter-luaex for Pulsar

Lua 5.4, LXC and LXE diagnostics plus editor annotations, hover, autocomplete
and active-parameter signature help. Runtime directive implementation is deferred.

## Installation

Copy this directory to `~/.pulsar/packages/linter-luaex`. Disable `linter-lxc`
before enabling this package to avoid duplicate grammars and diagnostics. Reload
Pulsar. Requires `linter`, `linter-ui-default`, `language-lua`, `autocomplete-plus`,
a Lua 5.4 executable and a current LuaEx repository. No npm dependencies.

## Settings

Settings use the `linter-luaex` prefix:

- `luaExRoot`: repository containing `LuaEx/lib/lxc` and `LuaEx/lib/lxe`.
  Automatic discovery checks LUAEX_ROOT, file/package/project ancestors, sibling
  LuaEx repositories and the local `~/Sync/Projects/GitHub/LuaEx` checkout.
- `luaExecutable`: Lua 5.4 executable. Automatic discovery checks LUA54, the
  existing portable Lua folder and PATH; Lua 5.3 is rejected.
- `projectRoot`: application source directory. Defaults to the Pulsar project
  root, or the framework repository for files inside it.
- `delegateLua`: default true; an active linter-lua handles ordinary Lua files.

## Editor features

Hover over a declaration or a resolved member for type and documentation details.
Completion offers visible class/enum members and generated property accessor
aliases. Signature help appears while entering a call; the active parameter is
highlighted. The command `linter-luaex:signature-help` also opens it.

`---@type Pool` and `---@type Pool?` annotate fields/properties for editor use.
Invalid, duplicate, unknown, unsupported-target and unresolved annotations produce
warnings explicitly labeled as editor annotations. They do not enforce runtime
contracts. Property overrides inherit type metadata; explicit conflicts warn.
DOx `@param` / `@ret` and `---@param` / `---@return` supply documentation metadata.
These never introduce argument/return checks. Default parameters remain deferred.

The tolerant editor index handles namespaces/imports, nested declarations,
inheritance, visibility, static/instance distinctions, inline/class-owned enums,
embedded enum members and immediate-parent extensions. Inference recognizes
simple literal initializers, named class construction, documented parameters and
annotated members. Unknown expressions remain unknown. It is not whole-program
Lua analysis; dynamic aliases, arbitrary expressions and complex control flow
may not resolve. Completion currently targets `.lxc` and `.lxe` editors.

## Diagnostics and execution

The authoritative LuaEx lexer/parser, declaration validator and compiler produce
syntax and class/enum structural diagnostics. The separate tolerant editor index
provides metadata for incomplete code. No application modules, initializers,
constructors, getters or enum payload expressions are executed for analysis.
Value-dependent enum checks remain runtime loader checks.

Project batches combine saved sources, bundled classes and unsaved buffers.
Legacy/prototype directories and symlinks are excluded. Limits: 1,000 files,
16 MiB source, 10-second worker timeout and 2 MiB diagnostic output. Diagnostics
use whole source lines; dependency errors retain navigable source references.
Broken parse/semantic dependencies can stop later compiler validation.

## Verification

`npm test` runs editor index/provider checks and real Lua 5.4 compiler tests.
Current result: 80 checks passed, including non-execution sentinels, annotation
warnings, visibility, enum nesting/extensions and active-parameter analysis.
Pulsar integration specs are in `spec/package-spec.js`. The attempted isolated
Pulsar launches have not produced a confirmed result; rendered hover/signature
behavior in the user's live editor remains unverified.
