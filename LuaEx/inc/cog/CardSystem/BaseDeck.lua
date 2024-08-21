--[[
OLD CARD DECK SYSTEM
local _nCardCount           = 52;
local _nCardCountWithJokers = 54;

local _tSuits   = { "Spades", "Hearts", "Diamonds", "Clubs"};
local _tValues  = { "Ace", "Two", "Three", "Four", "Five", "Six", "Seven",
                    "Eight", "Nine", "Ten", "Jack", "Queen", "King"};

local function createDeck(bShuffle, bRemoveJokers)
    local tCards = {};

    for _, sSuit in ipairs(_tSuits) do

        for nValue, sValue in ipairs(_tValues) do
            local tCard = {
                name    = sValue .. " of " .. sSuit,--TODO ordinal indexs
                suit    = sSuit,
                value   = nValue,
            };
            setmetatable(tCard, {
                __len = function()
                    return nValue;
                end,
                __tostring = function()
                    return sValue .. " of " .. sSuit;
                end,

            });
            tCards[#tCards + 1] = tCard;
        end

    end

    if not (bRemoveJokers) then
        local nJokerValue = 0;

        for x = 1, 2 do
            local tCard = {
                value   = nJokerValue,
                suit    = "None",
                name    = "Joker"
            };
            setmetatable(tCard, {
                __tostring = function()
                    return "Joker";
                end,
                __len = function()
                    return nJokerValue;
                end
            });
            tCards[#tCards + 1] = tCard;
        end

    end

    if (bShuffle) then

        for x = #tCards, 2, -1 do
            local y = rand(x);
            tCards[x], tCards[y] = tCards[y], tCards[x];
        end

    end

    return setmetatable(
    {
        draw = function(vIndex)
            local tCard;

            if (#tCards > 0) then
                local nIndex        = 1;

                if (rawtype(vIndex) == "number") then
                    nIndex  = (tCards[vIndex] ~= nil) and vIndex or nIndex;

                elseif (rawtype(vIndex) == "true") then
                    nIndex = rand(1, #tCards);
                end

                tCard = tCards[nIndex];
                table.remove(tCards, nIndex);
            end

            return tCard;
        end,
    },
    {
        __len = function()
            return #tCards;
        end,
        __ipairs = function(t)
            return next, tCards, nil;
        end,
        __index = function(t, k)
            return tCards[k] or nil;
        end,
        __type = "Deck",
    });
end

local _tShuffledDeck             = createDeck(true);
local _tUnshuffledDeck           = createDeck();
local _tShuffledDeckNoJokers     = createDeck(true, true);
local _tUnshuffledDeckNoJokers   = createDeck(false, true);
]]

return class("BaseDeck",
{--METAMETHODS

},
{--STATIC PUBLIC
    --BaseDeck = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    BaseDeck = function(this, cdat)

    end,
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
