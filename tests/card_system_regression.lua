if not LUAEX_INIT then require("LuaEx.init") end
local a = BaseCard("Ace", "Ace of spades", nil, nil, "Spades", "Ace", 1, false, false);
local b = BaseCard("King", "King of hearts", nil, nil, "Hearts", "King", 13);
local c = BaseCard("Twin", "Another ace", nil, nil, "Spades", "Ace", 1);
assert(a.getName() == "Ace" and a.getSuit() == "Spades" and a.getRank() == "Ace" and a.getValue() == 1);
assert(not a.isEnabled() and not a.isFaceUp());
a.flip().hide().reveal().setEnabled(true).setValue(2);
assert(a.isFaceUp() and a.isEnabled() and a.getValue() == 2);
local input = {a,b,c};
local deck = BaseDeck(input);
input[1] = b;
assert(rawequal(deck.peek(), a) and #deck == 3);
assert(not select(2, deck.addCard(a)));
local drawn, ok = deck.drawMany(4);
assert(not ok and #drawn == 0 and #deck == 3);
assert(rawequal(deck.draw(), a));
assert(select(2, deck.addCard(a, true)) and rawequal(deck.peek(), a));
local snapshot = deck.getCards(); snapshot[1] = b;
assert(rawequal(deck.peek(), a));
assert(not pcall(deck.shuffle, function() return 100 end) and rawequal(deck.peek(), a));
assert(not pcall(deck.shuffle, function() deck.draw(); return 1 end) and #deck == 3);
deck.shuffle(function(lo,hi) return hi end);
assert(rawequal(deck.peek(), a));
deck.reverse();
assert(rawequal(deck.peek(), c));
local cloned = clone(deck);
assert(#cloned == 3 and not rawequal(cloned.peek(), c));
cloned.peek().setValue(999);
assert(c.getValue() == 1);
a.getTagSystem().add("TEST", true);
local copy = clone(a);
assert(not rawequal(copy.getTagSystem(), a.getTagSystem()));
local seen = false;
for tag, enabled in copy.getTagSystem().eachTag() do
    if tag == "TEST" then assert(not enabled); seen = true; end
end
assert(seen);
drawn, ok = deck.drawMany(3);
assert(ok and #drawn == 3 and deck.isEmpty() and deck.draw() == nil);
assert(not pcall(BaseDeck, {a,a}));
assert(not pcall(BaseDeck, {[1] = a, [3] = b}));
assert(not pcall(BaseDeck, {Point(0,0)}));
assert(not pcall(a.setValue, math.huge));
local Child = class("BaseCardRegressionChild", {}, {}, {}, {}, {
    BaseCardRegressionChild = function(this, cdat, super)
        super("Child", "Concrete card.");
    end,
}, BaseCard);
assert(select(2, deck.addCard(Child())));
local _, removed = deck.clear();
assert(#removed == 1 and deck.isEmpty());
print("PASS cards/decks: metadata, flags, subclasses, exact identity, dense validation, safe drawing, atomic shuffle, copies, reversal, clearing and deep cloning");
