# BaseCard and BaseDeck

Both are loaded by LuaEx.init. Use dot-style method calls.

BaseCard extends BaseObject, inheriting name, description, rarity, tags and events. Constructor arguments are `(sName, sDescription, eRarity, wEventrix, bFaceUp, bEnabled)`. Defaults are Card, A card., inherited default rarity, face down and enabled. The base supports any card type and provides no suit, rank or numeric value fields. Developers define specialized fields and rules in their own subclasses; the library supplies no specialized card subclasses.

Getters use the existing accessor directives. Validated setters cover face state and enabled state. flip, reveal and hide return the card for chaining. Enabled is gameplay metadata; a deck does not automatically skip disabled cards.

BaseDeck extends CoG. `BaseDeck(tCards)` accepts a dense array of BaseCard instances or subclasses, copied by reference into an independent ordered list. Omission creates an empty deck. The same instance cannot occur twice in one deck; distinct cards with identical metadata are permitted. Decks are collections rather than an ownership system: hands, discard piles and exclusive ownership across collections belong to the caller.

Index one is the top. peek(index) inspects without removing; draw(index) returns/removes the actual card, or nil when no card exists. Both default to index one. drawMany(count) returns an array and success boolean; insufficient cards return an empty array and false without drawing anything. A zero count succeeds with an empty array.

addCard(card, top) appends by default, optionally inserts at the top, and returns `this, bAdded`. removeCard(card) uses exact identity and returns `this, bRemoved`. containsCard returns a boolean and index (or -1). getCardCount and #deck report remaining cards; isEmpty reports whether none remain. getCards returns a copied array; eachCard and pairs(deck) iterate an independent snapshot without consuming cards. Card objects themselves retain identity.

shuffle(randomSource) uses Fisher–Yates on a temporary list and commits only after all random indices validate. The optional callback receives `(minimum, maximum)` and must return a bounded integer. Exceptions, invalid indices and attempted deck mutations inside that callback preserve the previous order. reverse changes order in place; clear returns `this, tRemovedCards`.

Cloning an exact BaseCard copies its common traits, metadata and independent tag state, with a fresh event environment. Cloning an exact BaseDeck clones each card into an independent collection. Subclasses must define __clone for their additional state; arbitrary affix/effect callbacks are not implicitly copied. Text serialization of cards/decks containing cards currently encounters inherited Eventrix state, which has no serialization hook; no state is silently dropped to bypass that limitation.

Regression coverage: tests/card_system_regression.lua, included in examples/api/workbench/verify-baseitem.cjs. The local examples bundle includes both classes.
