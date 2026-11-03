--[[!
@fqxn LuaEx.GettingStarted
@desc LuaEx supports Lua 5.4+. Put the LuaEx repository root on package.path and
    require LuaEx.init once to initialize the full framework globally. Add application
    and extension project roots before initialization so .lxc/.lxe discovery includes
    their declarations. There is no separate init call or class load level selection.
    Native filesystem binaries must match the host platform and Lua ABI.
@ex require("LuaEx.init");
!]]
return [=[
<div class="container py-4">
  <div class="text-center">
    <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx Logo" class="img-fluid mb-4" style="max-height: 150px;">
    <p class="lead">LuaEx: an extension of Lua for Lua 5.4+</p>
  </div>
  <h2>Getting started</h2>
  <p>Make the LuaEx repository root reachable through <code>package.path</code>, then initialize the full framework:</p>
  <pre><code class="language-lua">require("LuaEx.init");</code></pre>
  <p>LuaEx installs its public bindings in the global environment. Initialization runs directly, takes no class load level, and returns no framework object. Successful requires are cached, and an explicit guard prevents repeated initialization.</p>
  <p>Add application roots to <code>package.path</code> before initialization. LuaEx discovers <code>.lxc</code> classes and <code>.lxe</code> enums together, prepares enums before class static initialization, and preserves dependency ordering.</p>
  <h2>Explore the reference</h2>
  <ul>
    <li><strong>LXC:</strong> declarations, visibility, inheritance, properties, operators, cloning and persistence.</li>
    <li><strong>LXE:</strong> immutable enum identities, payloads, embedded collections, extensions and class ownership.</li>
    <li><strong>Directives:</strong> completion-time stored-state checks and default declaration selection.</li>
    <li><strong>Libraries and classes:</strong> Eventrix, XML, collections, geometry primitives, serialization and filesystem helpers.</li>
  </ul>
  <h2>Runtime requirements</h2>
  <p>LuaEx supports Lua 5.4 and later. The debug library is required during initialization and by LXC access-context services. Native filesystem libraries in <code>LuaEx/bin/</code> must match the host platform, architecture and Lua ABI; bundled <code>lua54</code> builds target Lua 5.4. Filesystem discovery launches no shell processes.</p>
  <h2>Verification</h2>
  <pre><code class="language-text">lua dev/tests/run.lua
lua dev/tests/run.lua --list
lua dev/tests/run.lua --suite enums</code></pre>
  <p>Tests run in fresh native Lua processes. Current Windows Lua 5.4 verification does not establish every operating system or later Lua ABI. The generated reference combines the current source DOx comments with this introduction.</p>
  <p>Released under <a href="https://unlicense.org/">The Unlicense</a>.</p>
</div>
]=];
