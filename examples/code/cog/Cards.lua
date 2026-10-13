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
local suit, rank, value = "Spades", "Ace", 1; -- Edit these directly.
D.section("A card", "Suit/rank are labels; value is numeric. Names, rarity and tags come from BaseObject.");
local ace = BaseCard(rank.." of "..suit, "An example card.", nil, nil, suit, rank, value);
D.equal("Suit", ace.getSuit(), suit);
D.equal("Value", ace.getValue(), value);
D.check("Initially face down", not ace.isFaceUp());
D.section("Presentation state", "Flip, reveal and hide change the same instance. Enabled is caller-interpreted metadata.");
ace.flip(); D.check("Flipped up", ace.isFaceUp());
ace.hide().setEnabled(false); D.check("Disabled flag preserved", not ace.isEnabled());
D.section("Ordered deck", "Index one is the top. The constructor copies the input array, retaining card identity.");
local king = BaseCard("King", "A second card.", nil, nil, "Hearts", "King", 13);
local deck = BaseDeck({ace, king});
D.equal("Remaining cards", #deck, 2);
D.check("Top identity", rawequal(deck.peek(), ace));
D.check("Duplicate instance rejected", not select(2, deck.addCard(ace)));
D.section("Read without consuming", "Iteration and getCards return independent array snapshots, containing the actual cards.");
for index, card in deck.eachCard() do D.show("Card "..index, card.getName()); end
local snapshot = deck.getCards(); snapshot[1] = king;
D.check("Snapshot edits do not reorder the deck", rawequal(deck.peek(), ace));
D.section("Drawing and returning", "Draw removes the real instance. Insufficient batch draws do nothing.");
local cards, success = deck.drawMany(3);
D.check("Oversized draw rejected", not success and #cards == 0 and #deck == 2);
D.check("Drawn identity", rawequal(deck.draw(), ace));
D.check("Return to bottom", select(2, deck.addCard(ace)));
D.section("Shuffle and reverse", "A bounded integer random callback makes deterministic examples possible. Invalid indices leave order unchanged.");
deck.shuffle(function(minimum, maximum) return maximum; end);
D.check("Deterministic order", rawequal(deck.peek(), king));
deck.reverse(); D.check("Reversed top", rawequal(deck.peek(), ace));
D.section("Independent copies", "Base decks clone their cards. Subclasses define copying for additional state.");
local copy = clone(deck);
copy.peek().setValue(99);
D.equal("Original value unaffected", ace.getValue(), value);
D.check("Independent copied card", not rawequal(copy.peek(), ace));
D.section("Clear and empty draws", "Clear returns the removed instances. An empty draw returns nil.");
local _, removed = deck.clear();
D.equal("Removed card count", #removed, 2);
D.check("Deck empty", deck.isEmpty() and deck.draw() == nil);
D.note("The visual uses separate BaseDeck collections for draw, hand and discard; those zones and game effects are example policy. Text serialization of cards is currently limited by inherited Eventrix state.");
D.finish();
