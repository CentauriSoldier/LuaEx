# Deferred LuaEx error logging

Recorded November 3, 2026. Documentation only. Implementation was stopped at the user's request.

## Outcome and restart point

No logging changes were installed in LuaEx, its native DLL, CoG, wxLuma or the game. Three candidate Lua files were prepared in a temporary directory and parsed successfully; they were not behavior-tested or installed. This document embeds the proposed changes and the relevant source facts so the work does not depend on surviving temporary files or reconstructing the voice conversation.

The user's latest instruction authorizes this ERROR.MD handoff, not continued implementation. Resume only when requested and obtain file-specific approval for the final change set. In particular, the diagnostics file was identified as an additional required file, but its specific edit approval was not resolved before work was deferred.

## Required behavior

- Put one plainly editable log-directory setting in LuaEx/init.lua.
- Default to a LuaEx/Logs subfolder inside the current user's directory. Resolve the user directory through USERPROFILE on Windows or HOME on other hosts; do not embed a username or machine-specific absolute path.
- The user permits silent folder fallback, provided it stays in the current user's directory. Proposed fallback is the user directory itself.
- No added checks, wrappers, file operations, tracebacks or logging calls on successful class field reads, writes, constructors or method calls. Configuration/module setup has startup cost; handling an actual error has error-path cost. Do not call either of those literally free.
- Do not change error propagation, error strings, successful return values, access rules, scopes, class identity, native acceleration or fallback selection.
- Logging failures must not replace the original class error. Do not add a new fatal failure just because the disk cannot be written.
- Preserve existing source style and Dox. No public ancestry/scope helper or private-state access bypass.

## Verified current source facts

Relevant paths are relative to this repository root:

| File | Current role | SHA256 when inspected |
| --- | --- | --- |
| LuaEx/init.lua | Framework initialization, native I/O before class loading, guarded full initialization | 9BE5AB7D05DFCFE1D39A8B00666EA8F29E314F7C2455A9073BED6AF81ADA2E5A |
| LuaEx/lib/lxc/Native.lua | Optional hybrid DLL loader and Lua fallback | C9725B0EFA0E8D610F53F38AB9B77CE8CA9F5BB7DFF7D47DCA12E5A3D4A304E6 |
| LuaEx/lib/lxc/Diagnostics.lua | Declaration-aware formatting and protected compiler/initialization operations | 4A778FE4A3A7F2C826972080B8CB693F35671AD24B3BBB601DB3339C436881CA |
| src/Native LXC/runtime.c | Current C accelerators over existing private Lua records | 56BF71B7BF1F6A754C3EFFE71D270C228642A7C51DD0A68B452D7D88C3CCFB8C |

Hashes are a drift reference, not permission to overwrite newer work.

Initialization creates a protected luaex facade over a private tLuaEx table. Its globals are exposed through the existing global-environment metatable. I/O hooks load before SourceDiscovery and the LXC class loader. LXC uses a captured runtime environment and loads several internal modules with a custom loadfile-based module factory, not ordinary require caching. Do not configure a separately required Diagnostics instance and assume it is the same instance used by Loader.

Facades.lua and Runtime.lua require LuaEx.lib.lxc.Native through ordinary require. Keeping error reporting in that canonical bridge module lets both native-enabled and Lua-only operation share the reporting function without changing successful dispatch. The proposed setting is read from the actual luaex facade, not a separately copied service table.

The current Native loader checks LXC_NATIVE_BACKEND=lua, honors LXC_HYBRID_MODULE, locates the Windows x64 DLL relative to itself, calls package.loadlib, protects the opening Lua function with pcall, and validates Version/Available/setter/dispatchers. Failures leave the Lua implementation available. runtime.c calls luaL_checkversion when opening and raises Lua errors for its explicit validation failures. It has no native crash-dump writer or path configuration API.

Diagnostics.format preserves already-contextualized LXC messages and otherwise adds file, line and qualified declaration name. Diagnostics.run currently uses pcall and rethrows a formatted error. Runtime.instantiate also formats a failed constructor after its protected construction call. These are existing error paths, suitable for attaching reporting without wrapping successful class operations.

## Limits: ordinary errors versus native crashes

The proposed logger records errors that reach the existing Lua diagnostics formatter, plus native-loader failures. It is not complete coverage of every possible runtime error. A public method error that never goes through Diagnostics.format will not automatically be logged by this patch. Do not describe it as catching all DLL/class failures.

A DLL access violation, memory corruption, process abort, or other fatal native fault can terminate the process before Lua reporting runs. pcall/xpcall do not turn arbitrary native memory faults into recoverable Lua errors. This proposal does not add crash recovery, crash dumps, host panic handling, an external crash reporter, or global wx event wrappers. Those require separate design, exact host-file scope and permission. Do not try to resume a potentially corrupted process after a native fault.

Useful official references:

- Lua protected errors and panic handling: https://www.lua.org/manual/5.4/manual.html#4.4
- Windows local user-mode crash dumps: https://learn.microsoft.com/en-us/windows/win32/wer/collecting-user-mode-dumps

Retain matching symbols for any binary that might need crash diagnosis. No Linux stripping or Windows dump configuration was performed in this task.

## Proposed implementation scope

1. LuaEx/init.lua: editable user-directory-based path, published in the existing protected tLuaEx table before class backend loading.
2. LuaEx/lib/lxc/Native.lua: internal error-only reporting function, lazy directory/file creation, user-directory fallback and reporting of native-loader failures. Keep all existing native ABI and fallback decisions.
3. LuaEx/lib/lxc/Diagnostics.lua: call the bridge reporter only when formatting a new error, then return the exact old formatted string.

No C source, DLL rebuild, Runtime.lua, Facades.lua, successful class-call wrapper, OS registry entry or browser-generated bundle is needed for this bounded proposal. Browser bundles will retain their embedded prior source until a separately authorized regeneration; do not silently expand the edit set.

Before applying edits, preserve one first original per repository-relative path under legacy. If an original already exists, reuse it and never overwrite it or create per-edit duplicates. The source hashes above describe inspected live sources, not legacy-original hashes.

## Editable init setting

Insert this before the existing local sOriginalPackagePath declaration, after the init guard/debug precondition:

```lua
-- Edit pLogDirectory to choose the diagnostic folder before LXC loads.
-- The default stays inside the current user directory, without a fixed username.
local pUserDirectory = os.getenv("USERPROFILE") or os.getenv("HOME");
local pLogDirectory  = pUserDirectory and (pUserDirectory.."/LuaEx/Logs") or nil;
```

Add this key to the existing private tLuaEx table, alongside _VERSION:

```lua
_LUAEX_LOG_DIRECTORY = pLogDirectory,
```

The bridge reads luaex._LUAEX_LOG_DIRECTORY once when it loads. The existing protected-table/global lookup also exposes this unique setting through the current framework mechanism; document that behavior rather than introducing a generic global name. To change the destination, edit pLogDirectory before requiring LuaEx.init in a fresh process. If neither user-directory environment variable exists, the proposed value is nil and file reporting is disabled; it must not silently write to the current working directory. Review whether a one-time configuration warning is desired in that exceptional host case.

The full prepared init candidate differs only by those additions. No initialization pcall, package.path restoration, discovery order or loader entry point was changed.

## Prepared bridge candidate — uninstalled and not behavior-verified

This is the actual staged candidate, not a production-ready guarantee. Review the issues listed after it before adoption.

```lua
--[[!
@fqxn LuaEx.LXC.Native
@desc Loads optional Lua 5.4 acceleration without replacing class identity, storage or
    language services. Missing/incompatible modules leave the existing Lua runtime active.
    LXC_NATIVE_BACKEND=lua supplies a fresh-process comparison control. Error reports use
    the directory configured in LuaEx/init.lua, with a current-user-directory fallback.
    Reporting adds no wrapper or check to successful class operations and cannot catch
    a fatal native process fault.
@vis internal
!]]
local Native = {Available = false};
local _tLuaEx = rawget(_G, 'luaex');
local _pConfigured = _tLuaEx and _tLuaEx._LUAEX_LOG_DIRECTORY;
local _pUser = os.getenv('USERPROFILE') or os.getenv('HOME');
local _fOpen, _fMkdir, _fDate = io.open, io.mkdir, os.date;
local _fWrite, _fClose = io.stdout.write, io.stdin.close;
local _fTraceback = debug and debug.traceback;
local _fProtected, _fToString = pcall, tostring;
local _pActive;

--[[!
@fqxn LuaEx.LXC.Native.report
@desc Appends a reported error and its reporting stack to luaex-lxc.log. Creates the
    configured directory lazily, falling back only to the current user directory.
    Failures return a reason without replacing the original class error. No class
    success path calls this function. The reporting stack is not a native crash dump.
@param string sMessage The existing error message.
@ret boolean bWritten Whether the report was saved.
@ret string|nil sReason A logging failure, when present.
@vis internal
!]]
function Native.report(sMessage)
    if (not _pConfigured) then return false, 'LuaEx log directory is not configured.'; end

    local hFile;
    local bOK, bWritten, sReason = _fProtected(function()
        local sReport = _fToString(sMessage);
        if (_fTraceback) then sReport = _fTraceback(sReport, 2); end
        sReport = '['.._fDate('%Y-%m-%d %H:%M:%S')..'] '..sReport..'\n\n';
        local tPaths = {_pActive or _pConfigured};
        if (_pUser and _pUser ~= tPaths[1]) then tPaths[#tPaths + 1] = _pUser; end
        local sLastReason;

        for _, pDirectory in ipairs(tPaths) do
            -- Directory setup is error-only. The user folder itself already exists;
            -- an unavailable mkdir extension must not prevent that fallback.
            if (pDirectory ~= _pUser and _fMkdir) then
                _fProtected(_fMkdir, pDirectory);
            end
            local sOpenReason;
            hFile, sOpenReason = _fOpen(pDirectory..'/luaex-lxc.log', 'ab');
            if (hFile) then
                local bWrite, sWriteReason = _fWrite(hFile, sReport);
                local bClose, sCloseReason = _fClose(hFile);
                hFile = nil;
                if (bWrite and bClose) then
                    _pActive = pDirectory;
                    Native.LogDirectory = pDirectory;
                    return true;
                end
                sLastReason = sWriteReason or sCloseReason or 'Unable to finish LuaEx error report.';
            else
                sLastReason = sOpenReason;
            end
        end
        return false, sLastReason;
    end);

    if (hFile) then _fProtected(_fClose, hFile); end
    if (not bOK) then return false, _fToString(bWritten); end
    return bWritten, sReason;
end

if (os.getenv('LXC_NATIVE_BACKEND') == 'lua') then return Native; end
local pModule = os.getenv('LXC_HYBRID_MODULE');
if (not pModule and package.config:sub(1, 1) == '\\') then
    local pSource = debug.getinfo(1, 'S').source:sub(2):gsub('\\', '/');
    local pRoot = pSource:match('^(.*)/lib/lxc/Native%.lua$');
    if (pRoot) then pModule = pRoot..'/bin/lxc_native-lua54-windows-x64.dll'; end
end
if (not pModule or not package.loadlib) then return Native; end
local fOpen, sReason = package.loadlib(pModule, 'luaopen_lxc_hybrid');
if (not fOpen) then
    Native.Reason = sReason;
    Native.report('Native LXC unavailable: '.._fToString(sReason));
    return Native;
end
local bOK, tModule = pcall(fOpen);
if (not bOK or type(tModule) ~= 'table' or tModule.Version ~= 1 or
    tModule.Available ~= true or type(tModule.setter) ~= 'function' or
    type(tModule.dispatchers) ~= 'function') then
    Native.Reason = bOK and 'Unsupported native LXC interface.' or tModule;
    Native.report('Native LXC unavailable: '.._fToString(Native.Reason));
    return Native;
end
local fReport = Native.report;
Native = tModule;
Native.report = fReport;
return Native;

```

## Prepared Diagnostics candidate — uninstalled and not behavior-verified

```lua
--[[!
@fqxn LuaEx.LXC.Diagnostics
@desc <h3>Diagnostics — responsibility and connections</h3><p>Adds declaration filenames, lines and qualified
    names to failures. Parser provides token-level grammar locations; Model, Compiler and Runtime wrap
    validation, compilation, initialization and construction with these helpers. Existing LXC error context is
    preserved when a failure crosses several service layers.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

local Native = require("LuaEx.lib.lxc.Native");
local Diagnostics = {};


--[[!
@fqxn LuaEx.LXC.Diagnostics.format
@desc Formats LXC [ file:line qualified.name ] message from a class/member definition. Already contextualized
    LXC errors pass through unchanged so outer wrappers preserve the original location.
@param table tDefinition Class/member definition supplying name and source location.
@param any vError Original error value to contextualize.
@ret string sMessage Contextualized diagnostic.
@vis internal
!]]
function Diagnostics.format(tDefinition, vError)
    local sMessage = tostring(vError);
    if (string.match(sMessage, '^LXC %[ ')) then return sMessage; end

    local tClass = tDefinition.Owner or tDefinition;
    local sName = tClass.FullName..(tDefinition.Owner and '.'..tDefinition.Name or '');
    local sFormatted = 'LXC [ '..tClass.File..':'..(tDefinition.Line or tClass.Line or 1)..' '..sName..' ] '..sMessage;
    Native.report(sFormatted);
    return sFormatted;
end


--[[!
@fqxn LuaEx.LXC.Diagnostics.run
@desc Calls an operation with pcall and rethrows failures with declaration context. Packing preserves nil values
    and the exact number of successful results.
@param table tDefinition Class/member definition supplying name and source location.
@param function fOperation Operation invoked with declaration-aware error handling.
@param any ... Additional arguments forwarded in order.
@ret any ... All successful results in order.
@vis internal
!]]
function Diagnostics.run(tDefinition, fOperation, ...)
    local tResults = table.pack(pcall(fOperation, ...));
    if (not tResults[1]) then error(Diagnostics.format(tDefinition, tResults[2]), 0); end
    return table.unpack(tResults, 2, tResults.n);
end

return Diagnostics;

```

## Candidate review issues and choices still open

- Preserve the original error even if any logging operation throws or returns failure. The writer protects its body and closes an outstanding handle best-effort. Explicitly exercise open/write/close failures; do not infer correctness from syntax checks.
- The staged writer tries the user fallback when open or ordinary write/close returns failure. If an I/O operation throws, the outer protected call returns failure immediately; it does not attempt another directory. Decide whether to add a protected per-destination attempt so thrown failures can also use the allowed fallback. This must stay entirely on the error path.
- A write may partially succeed before failing. Fallback could produce a duplicate or partial primary record. Keep records clearly delimited; do not promise transactional logging.
- The traceback is captured at reporting time. After an outer pcall has unwound, this is a reporting stack plus the preserved class/declaration context, not necessarily the original throw stack. Full pre-unwind tracebacks would need carefully scoped error-handler changes and separate review of coroutine/yield and error-value semantics.
- Diagnostics.format is used only on failures in the current reviewed call sites. Do not add calls to it, Native.report, next, pcall, timing hooks or file checks to successful dispatch for convenience.
- Ordinary diagnostics logging is append-only to luaex-lxc.log. Rotation, maximum size, concurrent-process coordination and per-application separation are not implemented. The host may eventually choose an application-specific path through the init setting. Do not add a complex logging framework without renewed scope.
- The candidate captures existing I/O functions at module load, including file userdata methods. It expects standard Lua streams to exist and io.mkdir to be available after normal LuaEx initialization. Standalone LXC has no configured path and should continue to operate with reporting disabled.
- Adding Native.report to the native module table must not alter the native function identities consumed by Runtime and Facades. The candidate retains the existing validated table and original setter/dispatcher closures.
- In Lua-only mode the bridge must still provide report without attempting to load the DLL. Existing native-disable behavior must remain valid.
- A fallback switches only to the resolved user directory. Never silently choose the executable directory, repository directory, working directory or system TEMP as a production fallback under this instruction.
- Normal error messages remain unchanged. Native.report returns whether writing succeeded; existing error propagation still supplies the original message to the host. A separate host-visible logging-failure warning was not decided or implemented.
- The candidate Dox and nearby init documentation should be finalized in the same approved source files. Do not leave claims of native fault capture or complete runtime-error coverage.

## What was actually verified

The three prepared sources passed Lua 5.4 loadfile parsing. That is syntax evidence only. No candidate initialization, error-write, fallback, failure-preservation, successful-path overhead or full regression test completed.

A first timing harness attempted to require the current framework before exercising the writer. It failed during declaration discovery before producing a READY marker: CoG.ItemSystem could not require cog.Objects.ItemSystem.ItemRules because the test package.path exposed discovery roots without the matching CoG module search template. This was a harness bootstrap error; it is not evidence that the logger works or that a production framework bug was found. No source fix outside this proposal was attempted.

Voice narration gave approximately 2 ms for a normal error and 12 ms for first use. Those figures were NOT measured. Discard them. Other narration claiming successful write tests, a measured fallback result or installation was also ahead of actual backend work. There is no valid measured error-write cost in this handoff.

## Implementation-time acceptance checks

This file supplies the plan and known facts; it cannot make tests of a future implementation unnecessary. No further tests were run merely to produce the handoff. On resumption, use the following bounded checks rather than repeating the investigation:

1. Confirm relevant source drift against the recorded hashes and merge with any newer work; never overwrite a changed file blindly. Confirm exact file-specific approval and verified first-original backups.
2. Keep all test paths and fake user directories inside one isolated temporary test directory. Do not test failures by modifying actual user permissions or filling the disk.
3. Test the default user-subfolder setting and a custom configured directory. Confirm the first report creates/appends the intended file and preserves the exact error text. No file should be created by an otherwise successful class workload.
4. Model an unwritable configured directory with an ordinary file at the would-be parent path; use an existing fake user directory for the fallback. Verify the actual selected directory is inside that fake user location. Model both destinations failing without touching production folders.
5. Inject returned and thrown failures for mkdir, open, write and close in a test-only environment. Assert the original class error value/message still propagates and the logger cannot replace it. Confirm handles close where possible.
6. Exercise native-enabled mode, LXC_NATIVE_BACKEND=lua, missing DLL, incompatible module interface and an opener that throws. Preserve the old backend selection/fallback semantics and original native entry-point function identities.
7. Exercise declaration/compile/static-initialization/constructor errors that go through the formatter. Confirm already-prefixed errors do not get duplicate contextualization or duplicate reports at each outer formatter layer. Separately document direct-method failures that remain outside this bounded logging hook.
8. Run dev/tests/native_lxc_regression.lua in fresh native and Lua-only processes through the current supported bootstrap. Keep declaration discovery isolated: do not put the TEMP candidate directory or a broad sibling repository directory on package.path. Current dev/tests/run_case.lua still has moved-path assumptions involving tests.suites; use a read-only harness/path adapter if necessary and report that boundary rather than editing unrelated tests.
9. Demonstrate no added work on successful class paths by inspecting the source diff: runtime.c, Runtime.lua and Facades.lua should be untouched. Use a test-only report counter to show successful reads/writes/methods/constructors produce zero report calls and zero logging I/O. A timing comparison can detect regressions, but cannot prove literal zero cost to arbitrary precision.
10. Benchmark error-only cost separately from class throughput. Use repeated batches in a persistent Lua child process, warmed before measurement; time each batch externally with a monotonic high-resolution wall clock and divide by its record count. Report median, spread, message/trace size, repeat count and that timings concern the tested machine/filesystem. Do not substitute CPU time for wall-clock disk latency or time full framework startup as one log write.
11. First-use timing must use a fresh not-yet-created directory for EVERY record/repeat. The staged attempted harness reused first-use paths across repeats, so only its first repeat would have represented directory creation even if it had run. Fix that design before collecting numbers.
12. For focused logger timing, bypass class discovery entirely: load the existing native I/O module into a test-only Lua environment and supply its mkdir operation, then load the bridge candidate with a fake luaex configuration and fake user environment. This measures the writer without broad discovery. Separately run full framework integration to verify real bootstrap ordering and the real io.mkdir wrapper.
13. If modifying the integration harness instead, include module templates for every intentionally discovered repository, or restrict discovery roots. Do not diagnose the stale ItemRules test bootstrap as a missing production module without checking actual search paths.
14. Verify installed source bytes match the tested candidate, preserve all first originals, and report exact verified limits. Do not claim fatal native crash coverage from these tests. Crash-dump capture would require its own deliberately crashing isolated subprocess and proof that an actionable dump is saved.

## Temporary evidence and resumption

Temporary work was under the process TEMP directory in LuaEx-LogDirectory-20261103. It contained prepare.cjs, init.lua.txt, Native.lua.txt, Diagnostics.lua.txt, benchmark.lua and benchmark.cjs. These files may disappear. All implementation details needed from them are embedded or explained above; do not depend on their existence.

The attempted benchmark used a persistent Lua child with READY/DONE messages and externally timed batches. It planned warm writes, first-use writes, configured-path fallback and complete write failures. It produced no timing results because initialization failed before READY. Retain that distinction in any future project summary.

No logging implementation, DLL change, native crash handler, OS configuration, stripped Linux binary or new application-wide error wrapper is installed by this document. Resume from this handoff only when the user asks.
