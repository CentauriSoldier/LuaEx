--LOCALIZATION
local class = class;

--[[!
    @fqxn CoG.CardSystem.BaseDeck.Helpers.validateCard
    @desc Requires a BaseCard instance or descendant. Invalid input raises an assertion before deck
    mutation.
    @param BaseCard oCard Candidate card instance.
    @scope local
!]]
local function validateCard(oCard)
    -- Check class identity and ancestry before accepting a reference.
    assert(class.isinstance(oCard) and class.ischildorself(class.of(oCard), BaseCard), "Deck entries must be BaseCard instances.");
end

--[[!
    @fqxn CoG.CardSystem.BaseDeck.Helpers.validateIndex
    @desc Requires a finite positive integer card position. This checks index shape, not whether the
    position exists in a deck.
    @param number nIndex Candidate one-based position.
    @scope local
!]]
local function validateIndex(nIndex)
    -- Exclude fractions, nonpositive values, NaN and infinite positions.
    assert(rawtype(nIndex) == "number" and nIndex >= 1 and nIndex < math.huge and nIndex % 1 == 0,
           "Card index must be a positive integer.");
end

--[[!
    @fqxn CoG.CardSystem.BaseDeck.Helpers.copyCards
    @desc Validates and copies a dense card array. Rejects invalid keys, holes, non-card values and
    repeated instances. The list is independent; card identities are retained.
    @param table tCards Dense source array of BaseCard instances.
    @ret table tCopy Validated shallow list copy.
    @scope local
!]]
local function copyCards(tCards)
    -- Step 1: require a list container rather than a class instance.
    assert(rawtype(tCards) == "table" and not class.isinstance(tCards), "Cards must be a dense array.");
    local tCopy, tSeen, nCount = {}, {}, 0;

    -- Step 2: count valid numeric keys without relying on # for sparse input.
    for k in pairs(tCards) do
        validateIndex(k);
        nCount = nCount + 1;
    end

    -- Step 3: require every position and reject repeated card identities.
    for nIndex = 1, nCount do
        local oCard = tCards[nIndex];
        validateCard(oCard);
        assert(not tSeen[oCard], "The same card instance cannot appear twice in a deck.");
        tSeen[oCard] = true;
        -- Keep each card reference; only the surrounding list is copied.
        tCopy[nIndex] = oCard;
    end

    return tCopy;
end

--[[!
    @fqxn CoG.CardSystem.BaseDeck
    @desc Ordered card collection. Index one is the top. Drawing removes the actual
    instance; discarding, hands, ownership and game rules are caller responsibilities.
    Different instances with identical metadata are permitted. Methods use
    dot calls. List snapshots retain actual card references; cloning duplicates
    cards. Draw-many and shuffle preserve the live list when their operation fails.
    @ex
    local deck = BaseDeck({ BaseCard(), BaseCard() });
    local card = deck.draw();
    local remaining = deck.getCardCount();
!]]
return class("BaseDeck",
{--METAMETHODS
    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Metamethods.__len
        @desc Returns the current card count for the length operator.
        @ret number nCount Number of cards.
        @vis public
    !]]
    __len = function(this, cdat)
        -- Read the current list size without allocating a snapshot.
        return #cdat.pri.cards;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Metamethods.__pairs
        @desc Provides the same snapshot iteration as eachCard for pairs(deck). Cards remain the
        actual instances.
        @ret function fIterator ipairs iterator.
        @ret table tSnapshot Independent ordered list of existing card references.
        @ret number nInitial Initial iterator position.
        @vis public
    !]]
    __pairs = function(this)
        -- Delegate to the public snapshot iterator so both iteration paths agree.
        return this.eachCard();
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Metamethods.__clone
        @desc Creates a new BaseDeck with each card cloned in order. Subclasses must implement their
        own clone operation; card cloning failures propagate.
        @ret BaseDeck oCopy Independent deck containing cloned cards.
        @vis public
    !]]
    __clone = function(this, cdat)
        -- Step 1: prevent a subclass clone from silently discarding subclass state.
        assert(class.of(this) == BaseDeck, "BaseDeck subclasses must implement __clone for their own state.");
        local tCards = {};

        -- Step 2: clone each card into an independent ordered list.
        for nIndex, oCard in ipairs(cdat.pri.cards) do
            tCards[nIndex] = clone(oCard);
        end

        -- Step 3: construct a new deck after all card clones succeed.
        return BaseDeck(tCards);
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
    cards = {}, -- Dense ordered list; index one is the top.
    busy = false, -- Temporary guard while the random source runs.

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.validateSnapshot
        @desc Validates restored snapshot cards and replaces their list with a copy. Clears the
        transient shuffle lock. Invalid snapshots raise an assertion.
        @param table tState Snapshot state with pri.cards and pri.busy.
        @vis private
    !]]
    validateSnapshot = function(tState)
        -- Validate restored identities/list shape before accepting snapshot state.
        tState.pri.cards = copyCards(tState.pri.cards);
        -- A restored deck must not inherit an in-progress callback lock.
        tState.pri.busy = false;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.prepareSnapshot
        @desc Clears the transient shuffle lock in prepared snapshot state so it is not persisted as
        runtime activity.
        @param table tState Snapshot state being prepared by the class system.
        @vis private
    !]]
    prepareSnapshot = function(tState)
        -- Persist data, not the temporary shuffle lock.
        tState.pri.busy = false;
    end,

},
{--PROTECTED
},
{--PUBLIC
    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.BaseDeck
        @desc Initializes an ordered deck and the CoG base. Omitted cards create an empty deck.
        Supplied lists are validated/copied before base initialization; card objects are retained by
        reference.
        @param table|nil tCards Dense, duplicate-free list of BaseCard instances.
        @vis public
    !]]
    BaseDeck = function(this, cdat, super, tCards)
        -- Step 1: prepare valid independent list storage before constructing the base.
        local tInput = tCards == nil and {} or copyCards(tCards);
        -- Step 2: initialize CoG, then attach the prepared cards.
        super();
        cdat.pri.cards = tInput;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.getCardCount
        @desc Returns the number of cards currently held, equivalent to the length operator.
        @ret number nCount Current card count.
        @vis public
    !]]
    getCardCount = function(this, cdat)
        -- Report the current list size directly.
        return #cdat.pri.cards;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.isEmpty
        @desc Checks whether the deck contains no cards.
        @ret boolean bEmpty True when the current card count is zero.
        @vis public
    !]]
    isEmpty = function(this, cdat)
        -- No card lookup or copy is needed to determine emptiness.
        return #cdat.pri.cards == 0;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.eachCard
        @desc Iterates a shallow snapshot in top-to-bottom order. Later deck mutations do not change
        the iterator list; yielded cards are the actual objects, not clones.
        @ret function fIterator ipairs iterator.
        @ret table tSnapshot Independent ordered list of card references.
        @ret number nInitial Initial iterator position.
        @vis public
    !]]
    eachCard = function(this, cdat)
        -- Step 1: capture order and membership without cloning card objects.
        local tSnapshot = {};

        for nIndex, oCard in ipairs(cdat.pri.cards) do
            tSnapshot[nIndex] = oCard;
        end

        -- Step 2: iterate this fixed list, independent of later deck mutations.
        return ipairs(tSnapshot);
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.getCards
        @desc Returns a new ordered list containing the existing card instances. Editing the list
        does not reorder the deck; editing a card affects that shared object.
        @ret table tCards Independent shallow copy of the current list.
        @vis public
    !]]
    getCards = function(this, cdat)
        -- Copy list storage while retaining each existing card identity.
        return copyCards(cdat.pri.cards);
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.containsCard
        @desc Finds a card using raw identity, ignoring overloaded equality. Requires a valid
        BaseCard instance even when the deck is empty.
        @param BaseCard oCard Exact instance to locate.
        @ret boolean bFound Whether this instance is present.
        @ret number nIndex One-based position, or -1 when absent.
        @vis public
    !]]
    containsCard = function(this, cdat, oCard)
        -- Step 1: reject invalid card arguments before searching.
        validateCard(oCard);

        -- Step 2: inspect current order and compare exact object identities.
        for nIndex, oExisting in ipairs(cdat.pri.cards) do

            if (rawequal(oExisting, oCard)) then
                return true, nIndex;
            end

        end

        -- Step 3: use -1 as the explicit not-found position.
        return false, -1;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.addCard
        @desc Adds a valid instance at the top or bottom. Existing identical instances are not added
        again. Invalid arguments or mutation during a shuffle callback raise assertions.
        @param BaseCard oCard Card instance to insert.
        @param boolean|nil bTop True inserts at index one; false/nil appends at the bottom.
        @ret BaseDeck this Deck for chaining.
        @ret boolean bAdded False when the same instance was already present.
        @vis public
    !]]
    addCard = function(this, cdat, oCard, bTop)
        -- Step 1: reject callback-time mutation and validate card/position policy.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        validateCard(oCard);
        assert(bTop == nil or rawtype(bTop) == "boolean", "Top flag must be a boolean.");

        -- Step 2: leave the deck unchanged when this identity is already present.
        if (this.containsCard(oCard)) then
            return this, false;
        end

        -- Step 3: insert at the chosen end and report that membership changed.
        table.insert(cdat.pri.cards, bTop and 1 or #cdat.pri.cards + 1, oCard);
        return this, true;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.removeCard
        @desc Removes the exact instance if present while preserving the remaining order. Invalid
        cards and mutation inside a shuffle callback raise assertions.
        @param BaseCard oCard Exact card instance to remove.
        @ret BaseDeck this Deck for chaining.
        @ret boolean bRemoved Whether the instance was found and removed.
        @vis public
    !]]
    removeCard = function(this, cdat, oCard)
        -- Step 1: guard callback-time mutation and locate the exact card.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        local bFound, nIndex = this.containsCard(oCard);

        -- Step 2: remove only an existing identity; absent cards are a normal no-op.
        if (bFound) then
            table.remove(cdat.pri.cards, nIndex);
        end

        return this, bFound;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.peek
        @desc Returns the actual card at a position without removing it. Defaults to the top; a
        valid position beyond the deck returns nil. Invalid index shapes raise an assertion.
        @param number|nil nIndex One-based position; defaults to one.
        @ret BaseCard|nil oCard Existing card instance or nil.
        @vis public
    !]]
    peek = function(this, cdat, nIndex)
        -- Step 1: apply the top-card default, then validate index shape.
        nIndex = nIndex == nil and 1 or nIndex;
        validateIndex(nIndex);
        -- Step 2: return the reference without changing deck membership.
        return cdat.pri.cards[nIndex];
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.draw
        @desc Removes and returns the actual card at a position, defaulting to the top. A valid
        position beyond the deck returns nil without mutation. Invalid index shapes and shuffle-time
        mutation raise assertions.
        @param number|nil nIndex One-based position; defaults to one.
        @ret BaseCard|nil oCard Removed instance, or nil when no card occupies the position.
        @vis public
    !]]
    draw = function(this, cdat, nIndex)
        -- Step 1: guard mutation, apply the top default and validate index shape.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        nIndex = nIndex == nil and 1 or nIndex;
        validateIndex(nIndex);

        -- Step 2: check existence before calling table.remove on an out-of-range position.
        if (not cdat.pri.cards[nIndex]) then
            return nil;
        end

        -- Step 3: remove the actual instance and close the gap in the remaining order.
        return table.remove(cdat.pri.cards, nIndex);
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.drawMany
        @desc Draws exactly the requested number from the top in order. Insufficient cards return an
        empty list and false with no mutation; zero is a successful empty draw. Invalid counts or
        shuffle-time mutation raise assertions.
        @param number nCount Finite nonnegative integer number of cards to draw.
        @ret table tDrawn Removed card instances in draw order.
        @ret boolean bSuccess Whether the entire requested count was available.
        @vis public
    !]]
    drawMany = function(this, cdat, nCount)
        -- Step 1: enforce mutation guard and a finite nonnegative integer count.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        assert(rawtype(nCount) == "number" and nCount >= 0 and nCount < math.huge and nCount % 1 == 0,
               "Draw count must be a nonnegative integer.");

        -- Step 2: reject insufficient capacity before removing any cards.
        if (nCount > #cdat.pri.cards) then
            -- Step 4: report the complete draw, including the successful zero-card case.
        return {}, false;
        end

        -- Step 3: remove one top card at a time, preserving draw order.
        local tDrawn = {};

        for nIndex = 1, nCount do
            tDrawn[nIndex] = table.remove(cdat.pri.cards, 1);
        end

        return tDrawn, true;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.shuffle
        @desc Uses Fisher-Yates on a temporary list. The random source receives (1, currentIndex)
        and must return an integer in that inclusive range. Callback errors/bad indexes propagate
        after unlocking; the original order is retained on failure. Deck-mutating methods are
        blocked during the callback.
        @param function|nil fRandom Random integer source; defaults to math.random.
        @ret BaseDeck this Deck for chaining after the new order is committed.
        @vis public
    !]]
    shuffle = function(this, cdat, fRandom)
        -- Step 1: validate the random source and prohibit nested shuffle mutations.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        assert(fRandom == nil or rawtype(fRandom) == "function", "Random source must be a function.");
        fRandom = fRandom or math.random;
        -- Step 2: work on a copy so partial swaps never alter the live order.
        local tCards = copyCards(cdat.pri.cards);
        -- Step 3: lock mutating methods while invoking the caller-supplied random source.
        cdat.pri.busy = true;
        local bOK, sReason = pcall(function()

            -- Fisher-Yates chooses one position in the remaining prefix for each swap.
            for nIndex = #tCards, 2, -1 do
                local nOther = fRandom(1, nIndex);
                -- Validate every result before indexing/swapping the temporary list.
                validateIndex(nOther);
                assert(nOther <= nIndex, "Random source returned an out-of-range index.");
                tCards[nIndex], tCards[nOther] = tCards[nOther], tCards[nIndex];
            end

        end);
        -- Step 4: unlock even after callback failure, then propagate the failure.
        cdat.pri.busy = false;
        assert(bOK, sReason);
        -- Step 5: publish the new order only when all swaps succeeded.
        cdat.pri.cards = tCards;
        return this;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.reverse
        @desc Reverses the current list in place, retaining all card identities. Empty and one-card
        decks are unchanged. Mutation inside a shuffle callback raises an assertion.
        @ret BaseDeck this Deck for chaining.
        @vis public
    !]]
    reverse = function(this, cdat)
        -- Step 1: block callback-time mutation before accessing live storage.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        local tCards = cdat.pri.cards;

        -- Step 2: swap mirrored positions once each, leaving a middle card untouched.
        for nIndex = 1, math.floor(#tCards / 2) do
            local nOther = #tCards - nIndex + 1;
            tCards[nIndex], tCards[nOther] = tCards[nOther], tCards[nIndex];
        end

        return this;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseDeck.Methods.clear
        @desc Replaces the current list with an empty list and returns the removed list in its
        former order. Cards are retained, not destroyed. Mutation inside a shuffle callback raises
        an assertion.
        @ret BaseDeck this Deck for chaining.
        @ret table tRemoved Former list containing removed card instances.
        @vis public
    !]]
    clear = function(this, cdat)
        -- Step 1: reject mutation during a shuffle callback.
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        -- Step 2: detach the old list and install fresh empty storage.
        local tRemoved = cdat.pri.cards;
        cdat.pri.cards = {};
        -- Step 3: return the old references so the caller decides their next destination.
        return this, tRemoved;
    end,
},
CoG,
false,
nil
);
