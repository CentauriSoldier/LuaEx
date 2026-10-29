# LXC / Lua 5.4 linter for Pulsar

Pulsar package for `.lxc` declarations and ordinary `.lua` syntax. Uses the actual
LuaEx lexer, parser, declaration validator and compiler from your configured
repository. It never initializes LuaEx, runs `loadSources`, requires application
modules, constructs application objects or invokes application code.

## Install

Requires Pulsar, the `linter` service and its UI, a **Lua 5.4 executable**, and the
LuaEx repository. No npm dependencies, native builds or automatic dependency
installation. The inspected machine already has linter, linter-ui-default,
language-lua and linter-lua installed.

Copy this whole folder to `~/.pulsar/packages/linter-lxc`, or link it with Pulsar's
package manager, then reload Pulsar. Do not copy only the main JavaScript file.
The sibling ZIP contains the same complete package folder. This source package
has not been published to a registry.

The installed package can record machine-local defaults in its own
`installation.json`. Pulsar settings override those defaults; no existing
editor/package settings need to be rewritten.

Settings under **linter-lxc**:

- `luaExecutable`: Lua 5.4 interpreter path, not luac. Empty searches `LUA54`, the
  user's existing `Sync/Portable Apps/Libraries/Lua/5.4/lua54.exe`, then lua54,
  lua5.4 and lua on PATH. Candidates are version checked; Lua 5.3 is rejected.
- `luaExRoot`: repository containing `LuaEx/lxc/modules`. Empty searches ancestors
  of the source file/package. Set this explicitly when linting copied application
  projects whose framework sits elsewhere.
- `projectRoot`: recursively scanned application `.lxc` source root. Empty uses the
  Pulsar project root (or the LuaEx repository itself for files inside it).
- `delegateLua`: enabled by default. An active `linter-lua` keeps handling ordinary
  `.lua` files, avoiding duplicate diagnostics. Disable this setting to use this
  package's non-executing Lua 5.4 syntax checker instead. No existing package's
  settings or executable are changed automatically.

The included grammar associates **`.lxc` with `source.lxc`**, while reusing
installed Lua strings/comments/body highlighting, with LXC declarations, modifiers, class names, this/base/field and null highlighted separately. Ordinary `.lua` retains its existing grammar. The
installed linter-lua selects source.lua, so it does not lint the new LXC scope.
Reopen existing `.lxc` tabs or select LXC after installing/reloading if needed.

## LXC category colors

Package styles apply only to `source.lxc` editors. Declaration keywords are violet; class and constructor names share warm gold,
while namespace names use a darker gold. Declaration opening/closing braces are
lime. Visibility is orange, **static alone is hot magenta**, other modifiers are
dark amber, this/base are cyan, dependencies/restrictions are green, accessors and their
field/value context are coral, operator is off-white, and null is periwinkle.
Operator symbols are ice blue; numeric literal colors are untouched. Lua control-flow
and strings/comments retain the syntax theme's styles. No global
editor/theme stylesheet is changed. Contextual accessor matching is highlighting,
not a second semantic parser; ordinary field/value identifiers are left alone.
The package palette uses scoped high-specificity rules; arbitrary custom stylesheet
overrides are not claimed to be impossible. Reload Pulsar once after this update.

Constructor highlighting uses parsed class names from the non-executing lint worker,
then specializes each enclosing class context. It does not infer constructors from
capitalization. Until a declaration parses, the generic grammar supplies structural
highlighting. Namespace/class braces track nested declaration blocks; method,
property and table braces keep their ordinary scopes, including both brace layouts.
Accessor opening/closing braces carry matching punctuation scopes; paired colors
are checked with the installed syntax theme. Bracket-matcher underline styling is unchanged.

## What it checks

LXC declaration syntax, names/modifiers, duplicates, inheritance/dependency cycles,
final and override contracts, abstract implementation, property/accessor contracts,
constructor rules and Lua bodies/initializer syntax. These are the framework's
real compile-time checks. This is not dynamic type inference or a replacement for
runtime private/protected access and field-value validation.

Each lint uses saved `.lxc` files under the application root plus bundled framework
classes. Open editors override saved source, including unsaved dependency edits.
Dependencies outside those roots must be included by selecting an appropriate
project root; the linter does not execute package.path setup or application loaders.
A missing dependency diagnosis means unavailable in this lint batch, not proof that
an externally initialized application lacks it.

A declaration parse error stops project semantic analysis until that source is
fixed. Runtime validation stops at its first project declaration-contract failure;
compilation then reports errors per member. Diagnostics are line-based, with a
whole-line editor range; token-exact columns are not claimed. Dependency errors are
shown on the requesting file with a navigable reference to the actual source.

Ordinary Lua is compiled in text mode but never run; BOM/shebang and Lua 5.4 syntax
are supported. It checks syntax, not globals, types or style. `test.lua` embedding
LXC text inside a string remains a Lua file: embedded strings are not LXC sources.

Workers use direct process arguments and length-prefixed UTF-8 input, no shell.
Limits: 1,000 files, 16 MiB source, 10 seconds per worker and 2 MiB diagnostics.
Symlinked source directories are not followed. Limits/configuration failures are
reported rather than silently treated as successful linting. Runtime framework
modules must be trusted: this is non-executing analysis of application sources,
not a sandbox for a modified framework/compiler.

## Verification

Run `npm test` or `node test/run.js` from this folder. No npm install is needed.
Current evidence: **26 checks** with real Lua 5.4.2 and the current repository,
including all bundled/playground definitions, project dependencies, syntax and
semantic errors, Unicode/CRLF, line mapping, unsaved overlays, Lua delegation,
stale-result suppression, deactivation, wrong-runtime rejection and a sentinel-file
proof that application source never executes.

An isolated real Pulsar 1.132.1 --test process also passed package activation,
.lxc grammar/cursor-scope selection, service consumption and actual Lua/LXC
diagnostics (61 assertions, including contextual constructors, declaration braces, paired property/accessor scopes and computed colors). The user subsequently reported it working in their
open editor. Visual diagnostic rendering was not independently observed.

The service follows the installed Linter v2 provider contract and Pulsar's
[community linting integration](https://docs.pulsar-edit.dev/ide-features/community-packages/).
