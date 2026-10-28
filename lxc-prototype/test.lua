--[[!
@fqxn Experiments.LXC.Tests
@desc Runs the standalone prototype without LuaEx initialization. Negative source
    fixtures are virtual io.open results; no temporary files or GUI are needed.
!]]
local pSource = debug.getinfo(1, "S").source:sub(2):gsub("\\", "/");
local pRoot = pSource:match("^(.*)/[^/]+$") or ".";
local LXC = assert(loadfile(pRoot.."/lxc.lua"))();
local nChecks = 0;

--[[!
@fqxn Experiments.LXC.Tests.check
@desc Counts contracts and identifies failed expectations.
!]]
local function check(bOK, sMessage)
    assert(bOK, sMessage);
    nChecks = nChecks + 1;
end

--[[!
@fqxn Experiments.LXC.Tests.virtual
@desc Supplies trusted in-memory source fixtures and always restores io.open.
!]]
local function virtual(sSource, tEnvironment)
    local fOpen = io.open;
    io.open = function(pFile, ...)
        if (pFile == "virtual.lxc") then return {read = function() return sSource; end, close = function() end}; end
        return fOpen(pFile, ...);
    end;
    local bOK, vResult = pcall(LXC.loadFiles, {"virtual.lxc"}, tEnvironment);
    io.open = fOpen;
    return bOK, vResult;
end

local tEnvironment = setmetatable({}, {__index = _G});
local tOrder = LXC.loadFiles({pRoot.."/examples/01_Player.lxc", pRoot.."/examples/02_Creature.lxc"}, tEnvironment);
check(tOrder[1] == "Demo.Characters.Creature" and tOrder[2] == "Demo.Characters.Player", "Parent must load before alphabetically earlier child file.");
check(_G.Demo == nil, "Publication stays in the requested environment.");
local oPlayer = tEnvironment.Demo.Characters.Player("James");
check(oPlayer.Name == "James" and oPlayer.getName() == "James", "Namespace construction and explicit parent constructor work.");
check(oPlayer.Label == "Player", "Unmarked fields default to public.");
check(oPlayer.getItemCount() == 2, "Methods execute Lua loops against private fields.");
check(oPlayer.describe() == "James: 100", "Override dispatch and protected access work.");
check(oPlayer.getSecret() == "Creature secret", "Inherited methods retain declaring-class private access.");
check(not pcall(function() return oPlayer.inventory; end), "External private access is rejected.");
check(not pcall(function() return oPlayer.energy; end), "External protected access is rejected.");
check(not pcall(function() oPlayer.secret = "changed"; end), "External private writes are rejected.");
check(not pcall(function() oPlayer.Unknown = 1; end), "Undeclared instance writes are rejected.");
check(not pcall(function() oPlayer.getName = function() end; end), "Methods cannot be replaced on instances.");
oPlayer.Name = "Jane";
check(oPlayer.getName() == "Jane", "Public fields remain writable.");
check(oPlayer.getLiteral() == "} { } ", "Lua table constructors, long strings and comments preserve braces.");
local oOther = tEnvironment.Demo.Characters.Player("Other");
check(oOther.Name == "Other" and oPlayer.Name == "Jane", "Instances own independent state.");

local tCases = {
    {"namespace X { class A : Missing {} }", "Missing parent"},
    {"namespace X { class A : B {} class B : A {} }", "Inheritance cycle"},
    {"namespace X { class A {} class A {} }", "Duplicate class"},
    {"namespace X { class A { final run() {} } class B : A { run() {} } }", "final member"},
    {"namespace X { class A { private x = 1; public read() { return this.x; } } class B : A { steal() { return this.x; } } }", false},
    {"namespace X { class A { public run() {} } class B : A { private run() {} } }", "preserve member"},
    {"namespace X { class A { run() { local x = ; } } }", "virtual.lxc"},
    {"namespace X { class A { x = 1 } }", "semicolon"},
    {"namespace X { class A { run() { return 'unterminated } } }", "Unterminated"},
    {"namespace X { class A { static run() {} } }", "Expected"},
    {"namespace X { class A { A() {} A() {} } }", "Duplicate constructor"},
    {"namespace X { class A { x = ; } }", "initializer"},
    {"namespace X { class A {} } namespace Y { class B {} }", "Expected"},
};
for _, tCase in ipairs(tCases) do
    local tTarget = setmetatable({}, {__index = _G});
    local bOK, vResult = virtual(tCase[1], tTarget);
    if (tCase[2]) then
        check(not bOK and tostring(vResult):find(tCase[2], 1, true), "Invalid source must fail clearly: "..tostring(tCase[2]));
        check(rawget(tTarget, "X") == nil, "Failed compilation does not publish classes.");
    else
        check(bOK and not pcall(tTarget.X.B().steal), "Descendants cannot read parent-private members.");
    end
end

local tCollision = {X = 42};
check(not virtual("namespace X { class A {} }", tCollision) and tCollision.X == 42, "Namespace collisions preserve existing values.");
local tExisting = {X = {Keep = true}};
check(virtual("namespace X { class A {} }", tExisting) and tExisting.X.Keep, "Existing plain namespace tables are reused.");
check(not virtual("namespace X { class A {} }", tExisting), "Existing class bindings cannot be replaced.");

local tNames = setmetatable({}, {__index = _G});
check(virtual([[namespace X { class A { private x = 1; self() { return this; } make() { return A(); } } }]], tNames), "Same-namespace test compiles.");
local oNamed = tNames.X.A();
check(oNamed.self() == oNamed and not pcall(function() return oNamed.self().x; end), "Returning this directly preserves public instance identity and access.");
check(oNamed.make().self() ~= oNamed, "Bare class names resolve within the current namespace.");
check(virtual("namespace IsClass.Definition { class Children {} }", {}), "Internal staging names cannot collide with user namespace names.");

local tShared = setmetatable({}, {__index = _G});
check(virtual([[namespace X { class A { Items = {}; add(sItem) { table.insert(this.Items, sItem); } } }]], tShared), "Mutable field test compiles.");
local oLeft, oRight = tShared.X.A(), tShared.X.A();
oLeft.add("one");
check(#oLeft.Items == 1 and #oRight.Items == 0, "Table-valued initializers execute separately per instance.");

-- Exercise the discovery adapter without starting LuaEx or shell listing processes.
local fListFiles, nCalls = io.listfiles, 0;
io.listfiles = function(pRootFound, bRecursive, fCallback, sExtension)
    nCalls = nCalls + 1;
    check(bRecursive and fCallback == nil and sExtension == "lxc", "Discovery uses LuaEx extension filtering.");
    return {"/classes/Player.lxc", "/classes/Creature.lxc"};
end;
local tFound = LXC.discover("/classes/?.lua;/classes/?/init.lua;/other/?.lua");
io.listfiles = fListFiles;
check(nCalls == 2 and #tFound == 2, "Discovery deduplicates roots and overlapping results.");

print("LXC prototype: "..nChecks.." checks passed.");
print("Load order: "..table.concat(tOrder, " -> "));
print("Example: "..oPlayer.describe()..", "..oPlayer.getItemCount().." inventory items.");
