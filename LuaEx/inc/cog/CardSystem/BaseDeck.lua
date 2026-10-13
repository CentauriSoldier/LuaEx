--LOCALIZATION
local class = class;

local function validateCard(oCard)
    assert(class.isinstance(oCard) and class.ischildorself(class.of(oCard), BaseCard), "Deck entries must be BaseCard instances.");
end

local function validateIndex(nIndex)
    assert(rawtype(nIndex) == "number" and nIndex >= 1 and nIndex < math.huge and nIndex % 1 == 0,
           "Card index must be a positive integer.");
end

local function copyCards(tCards)
    assert(rawtype(tCards) == "table" and not class.isinstance(tCards), "Cards must be a dense array.");
    local tCopy, tSeen, nCount = {}, {}, 0;

    for k in pairs(tCards) do
        validateIndex(k);
        nCount = nCount + 1;
    end

    for nIndex = 1, nCount do
        local oCard = tCards[nIndex];
        validateCard(oCard);
        assert(not tSeen[oCard], "The same card instance cannot appear twice in a deck.");
        tSeen[oCard] = true;
        tCopy[nIndex] = oCard;
    end

    return tCopy;
end

--[[!
    @fqxn CoG.CardSystem.BaseDeck
    @desc Ordered card collection. Index one is the top. Drawing removes the actual
    instance; discarding, hands, ownership and game rules are caller responsibilities.
    Different instances with the same suit/rank/value are permitted.
!]]
return class("BaseDeck",
{--METAMETHODS
    __len = function(this, cdat)
        return #cdat.pri.cards;
    end,

    __pairs = function(this)
        return this.eachCard();
    end,

    __clone = function(this, cdat)
        assert(class.of(this) == BaseDeck, "BaseDeck subclasses must implement __clone for their own state.");
        local tCards = {};

        for nIndex, oCard in ipairs(cdat.pri.cards) do
            tCards[nIndex] = clone(oCard);
        end

        return BaseDeck(tCards);
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
    cards = {},
    busy = false,

    validateSnapshot = function(tState)
        tState.pri.cards = copyCards(tState.pri.cards);
        tState.pri.busy = false;
    end,

    prepareSnapshot = function(tState)
        tState.pri.busy = false;
    end,

},
{--PROTECTED
},
{--PUBLIC
    BaseDeck = function(this, cdat, super, tCards)
        local tInput = tCards == nil and {} or copyCards(tCards);
        super();
        cdat.pri.cards = tInput;
    end,

    getCardCount = function(this, cdat)
        return #cdat.pri.cards;
    end,

    isEmpty = function(this, cdat)
        return #cdat.pri.cards == 0;
    end,

    eachCard = function(this, cdat)
        local tSnapshot = {};

        for nIndex, oCard in ipairs(cdat.pri.cards) do
            tSnapshot[nIndex] = oCard;
        end

        return ipairs(tSnapshot);
    end,

    getCards = function(this, cdat)
        return copyCards(cdat.pri.cards);
    end,

    containsCard = function(this, cdat, oCard)
        validateCard(oCard);

        for nIndex, oExisting in ipairs(cdat.pri.cards) do

            if (rawequal(oExisting, oCard)) then
                return true, nIndex;
            end

        end

        return false, -1;
    end,

    addCard = function(this, cdat, oCard, bTop)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        validateCard(oCard);
        assert(bTop == nil or rawtype(bTop) == "boolean", "Top flag must be a boolean.");

        if (this.containsCard(oCard)) then
            return this, false;
        end

        table.insert(cdat.pri.cards, bTop and 1 or #cdat.pri.cards + 1, oCard);
        return this, true;
    end,

    removeCard = function(this, cdat, oCard)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        local bFound, nIndex = this.containsCard(oCard);

        if (bFound) then
            table.remove(cdat.pri.cards, nIndex);
        end

        return this, bFound;
    end,

    peek = function(this, cdat, nIndex)
        nIndex = nIndex == nil and 1 or nIndex;
        validateIndex(nIndex);
        return cdat.pri.cards[nIndex];
    end,

    draw = function(this, cdat, nIndex)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        nIndex = nIndex == nil and 1 or nIndex;
        validateIndex(nIndex);

        if (not cdat.pri.cards[nIndex]) then
            return nil;
        end

        return table.remove(cdat.pri.cards, nIndex);
    end,

    drawMany = function(this, cdat, nCount)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        assert(rawtype(nCount) == "number" and nCount >= 0 and nCount < math.huge and nCount % 1 == 0,
               "Draw count must be a nonnegative integer.");

        if (nCount > #cdat.pri.cards) then
            return {}, false;
        end

        local tDrawn = {};

        for nIndex = 1, nCount do
            tDrawn[nIndex] = table.remove(cdat.pri.cards, 1);
        end

        return tDrawn, true;
    end,

    shuffle = function(this, cdat, fRandom)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        assert(fRandom == nil or rawtype(fRandom) == "function", "Random source must be a function.");
        fRandom = fRandom or math.random;
        local tCards = copyCards(cdat.pri.cards);
        cdat.pri.busy = true;
        local bOK, sReason = pcall(function()

            for nIndex = #tCards, 2, -1 do
                local nOther = fRandom(1, nIndex);
                validateIndex(nOther);
                assert(nOther <= nIndex, "Random source returned an out-of-range index.");
                tCards[nIndex], tCards[nOther] = tCards[nOther], tCards[nIndex];
            end

        end);
        cdat.pri.busy = false;
        assert(bOK, sReason);
        cdat.pri.cards = tCards;
        return this;
    end,

    reverse = function(this, cdat)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        local tCards = cdat.pri.cards;

        for nIndex = 1, math.floor(#tCards / 2) do
            local nOther = #tCards - nIndex + 1;
            tCards[nIndex], tCards[nOther] = tCards[nOther], tCards[nIndex];
        end

        return this;
    end,

    clear = function(this, cdat)
        assert(not cdat.pri.busy, "Cannot mutate the deck inside a shuffle callback.");
        local tRemoved = cdat.pri.cards;
        cdat.pri.cards = {};
        return this, tRemoved;
    end,
},
CoG,
false,
nil
);
