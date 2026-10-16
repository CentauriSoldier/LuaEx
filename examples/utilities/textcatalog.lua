-- Independent tutorial. Edit the literal wording and names below, then Run code.
-- Locate the repository for native Lua as well as the browser's virtual files.
local sSourcePath     = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*)[/\\]") or ".";
local sRepositoryPath = sSourcePath;

for _ = 1, 8 do
    local hFile = io.open(sRepositoryPath.."/LuaEx/load.lua", "r");

    if (hFile) then hFile:close(); break; end
    sRepositoryPath = sRepositoryPath.."/..";
end

package.path = sRepositoryPath.."/?.lua;"..package.path;

if (not LUAEX_INIT) then require("LuaEx.load")(); end

--LOCALIZATION
local clone       = clone;
local deserialize = deserialize;
local rawequal    = rawequal;
local serialize   = serialize;
local textcatalog = textcatalog;
local D = require("examples.support.tutorial").new("Text catalog", "Central wording, scoped searches, persistent variables, safe edits and public persistence.");

local sPlayer = "Mira";
local sFriend = "Elian";
local tEntries = {
    dialogue = {
        merchant = {
            greeting = "Hello ${player}! Your friend ${friend} was just here.",
            farewell = "Safe travels, ${PLAYER}!",
            literal  = "Write $${friend} to show the placeholder.",
            question = "Offer: 100%? [gold] . * +",
            rumors   = {road = "A traveler says the northern road is safe."},
        },
        guard = {warning = "Keep the road clear, traveler."},
    },
    errors = {gold = "You need ${amount} more gold."},
    empty  = {},
    silence = "",
};

D.section("Create a central catalog", "String leaves are wording; tables are nodes. Declared spelling is preserved, but keys and paths ignore case. The root starts active.");
local oDialogue = textcatalog(tEntries);
local tRoot, sRoot = oDialogue.getactivenode();
D.equal("Initial root path", sRoot, "");
D.check("Root snapshot contains dialogue", tRoot.dialogue ~= nil);
D.equal("Case-insensitive exact lookup", oDialogue.gettext("DIALOGUE.MERCHANT.GREETING"), tEntries.dialogue.merchant.greeting);
D.equal("Missing exact text", oDialogue.gettext("missing"), nil);
D.equal("A node is not text", oDialogue.gettext("dialogue"), nil);
D.equal("Empty text is valid", oDialogue.gettext("silence"), "");

D.section("Persistent conversation variables", "Each object owns its variables. Set them once for every future result. String values are literal; substitutions do not alter the stored template.");
oDialogue.setvar("PLAYER", sPlayer).setvar("friend", sFriend);
D.equal("Formatted greeting", oDialogue.gettext("dialogue.merchant.greeting"), "Hello "..sPlayer.."! Your friend "..sFriend.." was just here.");
D.equal("Case-insensitive variable names", oDialogue.gettext("dialogue.merchant.farewell"), "Safe travels, "..sPlayer.."!");
D.equal("Unset placeholder stays visible", oDialogue.gettext("errors.gold"), "You need ${amount} more gold.");
D.equal("Escaped placeholder", oDialogue.gettext("dialogue.merchant.literal"), "Write ${friend} to show the placeholder.");
oDialogue.setvar("friend", "${player}");
D.equal("No variable chaining", oDialogue.gettext("dialogue.merchant.greeting"), "Hello "..sPlayer.."! Your friend ${player} was just here.");
oDialogue.setvar("friend", sFriend);
local oOther = textcatalog(tEntries);
D.equal("Other catalog has no variables", oOther.gettext("dialogue.merchant.farewell"), "Safe travels, ${PLAYER}!");

D.section("Active nodes and explicit scopes", "Exact text keys resolve within active scope. Explicit node paths start at the root. Empty-string scope means root; nil resets active selection to root.");
oDialogue.setactivenode("DIALOGUE.MERCHANT");
D.equal("Relative exact lookup", oDialogue.gettext("farewell"), "Safe travels, "..sPlayer.."!");
D.equal("Explicit root override", oDialogue.gettext("errors.gold", ""), "You need ${amount} more gold.");
D.equal("Explicit sibling scope", oDialogue.gettext("warning", "dialogue.guard"), "Keep the road clear, traveler.");
local _, sActive = oDialogue.getactivenode();
D.equal("Explicit lookups preserve active node", sActive, "dialogue.merchant");
D.reject("Text cannot become active", function() oDialogue.setactivenode("dialogue.merchant.greeting"); end);
local _, sUnchanged = oDialogue.getactivenode();
D.equal("Rejected active change is atomic", sUnchanged, sActive);

D.section("Literal searches and return paths", "Search stored templates before substitutions. Ambiguous searches return the first encountered match with no guaranteed ordering. No match retains a valid scope path.");
local sText, sPath = oDialogue.findtext("HELLO");
D.equal("Search applies substitutions after matching", sText, oDialogue.gettext("greeting"));
D.equal("Matched full path", sPath, "dialogue.merchant.greeting");
sText, sPath = oDialogue.findtext(sFriend);
D.equal("Rendered variable value is not searched", sText, nil);
D.equal("Valid scope returned on no match", sPath, "dialogue.merchant");
sText, sPath = oDialogue.findtext("anything", "missing");
D.check("Invalid scope returns nil, nil", sText == nil and sPath == nil);
sText, sPath = oDialogue.findtext("100%?");
D.equal("Lua pattern symbols are literal", sPath, "dialogue.merchant.question");
sText, sPath = oDialogue.findtext("traveler", "");
D.check("Global ambiguous match has text and a full path", sText ~= nil and sPath ~= nil);
D.note("Do not depend on which traveler line matched. Use a precise key or narrower node when identity matters.");

D.section("Node discovery and independent snapshots", "getnode and findnode return nested tables with substitutions. Those tables are editable snapshots, not live views or private catalog state.");
local tNode, sNodePath = oDialogue.findnode("RUM");
D.equal("Case-insensitive node-name substring", sNodePath, "dialogue.merchant.rumors");
D.equal("Node includes descendants", tNode.road, "A traveler says the northern road is safe.");
local tSnapshot = oDialogue.getnode();
tSnapshot.greeting = "Snapshot only";
tSnapshot.rumors.road = "Changed nested snapshot";
D.check("Text snapshot independent", oDialogue.gettext("greeting") ~= tSnapshot.greeting);
D.equal("Nested snapshot independent", oDialogue.gettext("rumors.road"), "A traveler says the northern road is safe.");
D.equal("Text path is not a node", oDialogue.getnode("dialogue.merchant.greeting"), nil);
D.check("Empty node is valid", oDialogue.getnode("empty") ~= nil);

D.section("Fixed hierarchy, editable templates", "settext can replace only existing string entries. Store the template without formatting it so future variable changes still work. Setters support method chaining.");
D.check("Setters return this catalog", rawequal(oDialogue.settext("greeting", "Welcome ${friend}!"), oDialogue));
oDialogue.setvar("friend", "Rowan");
D.equal("Edited text remains a template", oDialogue.gettext("greeting"), "Welcome Rowan!");
D.reject("Cannot add a path", function() oDialogue.settext("newEntry", "New text"); end);
D.reject("Cannot replace a node", function() oDialogue.settext("rumors", "Not a node"); end);
D.reject("Cannot delete text", function() oDialogue.settext("greeting", nil); end);
D.reject("Variable values must be strings", function() oDialogue.setvar("amount", 50); end);
D.reject("Case-only duplicate keys", function() textcatalog({Car = "one", car = "two"}); end);

D.section("Clear context and reset scope", "Clearing variables never changes templates or hierarchy. Future results show the complete missing placeholders. Resetting scope does not change variables.");
oDialogue.clearvar("FRIEND");
D.equal("Single variable cleared", oDialogue.gettext("greeting"), "Welcome ${friend}!");
oDialogue.clearvars();
D.equal("All variables cleared", oDialogue.gettext("farewell"), "Safe travels, ${PLAYER}!");
oDialogue.setactivenode(nil);
local _, sReset = oDialogue.getactivenode();
D.equal("Nil resets to root", sReset, "");

D.section("Public serialization and independent cloning", "Use global serialize and deserialize. Copies retain raw templates, variables and active scope, and can be edited independently. No factory deserialize method is exposed.");
oDialogue.setvar("player", sPlayer).setvar("friend", sFriend).setactivenode("dialogue.merchant");
local sSaved    = serialize(oDialogue);
local oRestored = deserialize(sSaved);
D.check("Restored catalog is independent", not rawequal(oRestored, oDialogue));
D.equal("Restored variables and template", oRestored.gettext("greeting"), "Welcome "..sFriend.."!");
local _, sRestoredPath = oRestored.getactivenode();
D.equal("Restored active scope", sRestoredPath, "dialogue.merchant");
oRestored.setvar("friend", "Nova");
D.equal("Restored template still supports edits", oRestored.gettext("greeting"), "Welcome Nova!");
D.equal("Source variables unchanged", oDialogue.gettext("greeting"), "Welcome "..sFriend.."!");
local oCopy = clone(oDialogue);
oCopy.settext("greeting", "Clone only");
D.equal("Clone text independent", oDialogue.gettext("greeting"), "Welcome "..sFriend.."!");
D.check("Factory restores identity", rawequal(deserialize(serialize(textcatalog)), textcatalog));
D.equal("Restoration stays private", textcatalog.deserialize, nil);
D.finish();
