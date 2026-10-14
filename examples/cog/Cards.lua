-- Independent code tutorial. Edit the values below, then Run code.
-- Locate the repository from this example (native Lua and browser virtual files).
local sExampleSource = debug.getinfo(1, "S").source:gsub("^@", "")
local sSourcePath = sExampleSource:match("^(.*)[/\\]") or "."
local sRepositoryPath = sSourcePath
for _ = 1, 8 do
    local file = io.open(sRepositoryPath .. "/LuaEx/init.lua", "r")
    if file then file:close(); break end
    sRepositoryPath = sRepositoryPath .. "/.."
end
package.path = sRepositoryPath .. "/?.lua;" .. package.path
if not LUAEX_INIT then require("LuaEx.init") end

local D = require("examples.support.tutorial").new("Cards and decks", "Card traits, actual instances, order, drawing, iteration and copying.");
local name, description = "Fireball", "A spell card."; -- Edit these directly.
D.section("A card", "Any card can use names, descriptions, rarity and tags. Specialized fields belong to your game.");
local spell = BaseCard(name, description);
D.equal("Name", spell.getName(), name);
D.equal("Description", spell.getDescription(), description);
D.check("Initially face down", not spell.isFaceUp());
D.section("Presentation state", "Flip, reveal and hide change the same instance. Enabled is caller-interpreted metadata.");
spell.flip(); D.check("Flipped up", spell.isFaceUp());
spell.hide().setEnabled(false); D.check("Disabled flag preserved", not spell.isEnabled());
D.section("Ordered deck", "Index one is the top. The constructor copies the input array, retaining card identity.");
local resource = BaseCard("Healing Potion", "A resource card.");
local deck = BaseDeck({spell, resource});
D.equal("Remaining cards", #deck, 2);
D.check("Top identity", rawequal(deck.peek(), spell));
D.check("Duplicate instance rejected", not select(2, deck.addCard(spell)));
D.section("Read without consuming", "Iteration and getCards return independent array snapshots, containing the actual cards.");
for index, card in deck.eachCard() do D.show("Card "..index, card.getName()); end
local snapshot = deck.getCards(); snapshot[1] = resource;
D.check("Snapshot edits do not reorder the deck", rawequal(deck.peek(), spell));
D.section("Drawing and returning", "Draw removes the real instance. Insufficient batch draws do nothing.");
local cards, success = deck.drawMany(3);
D.check("Oversized draw rejected", not success and #cards == 0 and #deck == 2);
D.check("Drawn identity", rawequal(deck.draw(), spell));
D.check("Return to bottom", select(2, deck.addCard(spell)));
D.section("Shuffle and reverse", "A bounded integer random callback makes deterministic examples possible. Invalid indices leave order unchanged.");
deck.shuffle(function(minimum, maximum) return maximum; end);
D.check("Deterministic order", rawequal(deck.peek(), resource));
deck.reverse(); D.check("Reversed top", rawequal(deck.peek(), spell));
D.section("Independent copies", "Base decks clone their cards. Subclasses define copying for additional state.");
local copy = clone(deck);
copy.peek().setEnabled(true);
D.check("Original enabled flag unaffected", not spell.isEnabled());
D.check("Independent copied card", not rawequal(copy.peek(), spell));
D.section("Clear and empty draws", "Clear returns the removed instances. An empty draw returns nil.");
local _, removed = deck.clear();
D.equal("Removed card count", #removed, 2);
D.check("Deck empty", deck.isEmpty() and deck.draw() == nil);
D.note("The visual uses separate BaseDeck collections for draw, hand and discard; those zones and game effects are example policy. Text serialization of cards is currently limited by inherited Eventrix state.");
D.finish();
