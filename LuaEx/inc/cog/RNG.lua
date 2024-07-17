local table = table;
local math  = math;
local ceil  = math.ceil;
local floor = math.floor;
local rand  = math.random;

local _nDefaultDieSides     = 6;
local _n100                 = 100;
local _nDefaultCheckSides   = 20;

local _nCardCount           = 52;
local _nCardCountWithJokers = 54;

local _tSuits   = { "Spades", "Hearts", "Diamonds", "Clubs"};
local _tValues  = { "Ace", "Two", "Three", "Four", "Five", "Six", "Seven",
                    "Eight", "Nine", "Ten", "Jack", "Queen", "King"};

local function createDeck(bShuffle, bRemoveJokers)
    local tRet = {};

    for _, sSuit in ipairs(_tSuits) do

        for nValue, sValue in ipairs(_tValues) do
            local tCard = {
                name    = sValue .. " of " .. sSuit,--TODO ordinal indexs
                suit    = sSuit,
                value   = nValue,
            };
            tRet[#tRet + 1] = tCard;
        end

    end

    if not (bRemoveJokers) then

        for x = 1, 2 do
            local tCard = {
                value   = 0,
                suit    = "None",
                name    = "Joker"
            };
            tRet[#tRet + 1] = tCard;
        end

    end

    if (bShuffle) then

        for x = #tRet, 2, -1 do
            local y = rand(x);
            tRet[x], tRet[y] = tRet[y], tRet[x];
        end

    end

    return tRet;
end

local _tShuffledDeck             = createDeck(true);
local _tUnshuffledDeck           = createDeck();
local _tShuffledDeckNoJokers     = createDeck(true, true);
local _tUnshuffledDeckNoJokers   = createDeck(false, true);

local _tBooleans = {true, false}

--[[!
@fqxn LuaEx.CoG.Classes.RNG
@desc A static helper class for rolling dice, drawing cards, etc.
!]]
return class("RNG",
{--METAMETHODS

},
{--STATIC PUBLIC
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.boolean
    @vis Static Public
    @desc Generates a random boolean value.
    @ret boolean bFlag Randomly, true or false.
    !]]
    boolean = function()
        return _tBooleans[rand(1, 2)];
    end,
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.createDeck
    @vis Static Public
    @desc Generates a random boolean value.
    @param boolean|nil bShuffle Whether the deck should be suffled
    (defaults to false).
    @param boolean|nil bRemoveJokers Whether to remove the jokers from the deck
    (defaults to false).
    @ret table tDeck A numerically-indexed table whose values are subtables with the following format:
    <br>
    <pre><code class="language-lua">
    {
        name    = (string) Name of the card.
        suit    = (string) Name of the card's suit.
        value   = (number) Value of the card.
    }
    </code></pre>
    !]]
    createDeck = createDeck,
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.drawCard
    @vis Static Public
    @desc Generates a percentage value.
    @param boolean|nil bUnshuffled Whether to draw randomly from an unshuffled deck (defaults to false).
    @param boolean|nil bExcludeJokers Whether to prevent drawing jokers (defaults to false).
    @ret table tCard A table with the following format.
    <br>
    <pre><code class="language-lua">
    {
        name    = (string) Name of the card.
        suit    = (string) Name of the card's suit.
        value   = (number) Value of the card.
    }
    </code></pre>
    !]]
    drawCard = function(bUnshuffled, bExcludeJokers)
        local tCard;

        if (bUnshuffled) then

            if (bExcludeJokers) then
                tCard = _tUnshuffledDeckNoJokers[rand(1, _nCardCount)];
            else
                tCard = _tUnshuffledDeck[rand(1, _nCardCountWithJokers)];
            end

        else

            if (bExcludeJokers) then
                tCard = _tShuffledDeckNoJokers[rand(1, _nCardCount)];
            else
                tCard = _tShuffledDeck[rand(1, _nCardCountWithJokers)];
            end

        end

        return tCard;
    end,
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.percent
    @vis Static Public
    @desc Generates a percentage value.
    @param boolean|nil bFloat Whether the result should be a float from 0.01-1 or an int from 1-100 (defaults to false).
    @ret number nPercent An int or float value from 1-100 or 0.01-1 respectively.
    !]]
    percent = function(bFloat)
        return bFloat and (rand(1, 100) / 100) or rand(1, 100);
    end,
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.rollCheck
    @vis Static Public
    @desc Determines whether a check is made based on the input. Often used for things like stat checks. The check will be successful if the number rolled by the function is equal to or higher than the <strong><em>nCheck</em></strong> parameter.
    @param number|nil nSides The number of sides the check die will be (defaults to 20).
    @param number|nil nCheck The number to test against (E.g., an Agility value) (defaults to 10).
    @ret boolean bSuccess True if the check was successful or false otherwise.
    !]]
    rollCheck = function(nSides, nCheck)
        nSides = (  rawtype(nSides) == "number" and nSides > 1) and
                    ceil(nSides) or _nDefaultCheckSides;
        nCheck = (  rawtype(nCheck) == "number" and nCheck > 0) and
                    ceil(nCheck) or _nDefaultCheckSides / 2;

        local nRoll = rand(1, nSides);
        return nRoll >= nCheck, nRoll, nRoll - nCheck;
    end,
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.rollDice
    @vis Static Public
    @desc Rolls a number of dice, returning the sum total of the roll.
    <br>The number of sides on the dice is determined by the <strong><em>nSides</em></strong> parameter (defaults to 6).
    <br>The number of dice to roll is determined by the <strong><em>nDice</em></strong> parameter (defaults to 1).
    <br>The number of attempts is determined by the <strong><em>nAttempts</em></strong> parameter (defaults to 1).
    <br> If the number of attempts is set to a value greater than 1, the roll will happen that many times, keeping only the highest total out of all the attempts.
    @param number|nil nSides The number of sides the check die will be.
    @param number|nil nCheck The number to test against (E.g., an Agility value).
    @ret number|nil nTotal The total from the roll.
    !]]
    rollDice = function(nSides, nDice, nAttempts)
        -- Ensure nSides, nDice, and nAttempts are valid numbers and greater than 0
        nSides = (  rawtype(nSides) == "number" and nSides > 1) and
                    ceil(nSides) or _nDefaultDieSides;
        nDice = (  rawtype(nDice) == "number" and nDice > 0) and
                    ceil(nDice) or 1;
        nAttempts = (  rawtype(nAttempts) == "number" and nAttempts > 0) and
                    ceil(nAttempts) or 1;

        local nTotal        = 0;
        local nGrandTotal   = 0;

        if (nAttempts == 1) then

            -- Only one roll to make, sum the results of all dice
            if nDice == 1 then
                nTotal = rand(1, nSides);
            else

                for nDie = 1, nDice do
                    nTotal = nTotal + rand(1, nSides);
                end

            end

            nGrandTotal = nTotal;
        else

            -- Multiple rolls, find the best total among them
            for nRoll = 1, nAttempts do
                nTotal = 0;

                if nDice == 1 then
                    nTotal = rand(1, nSides);
                else

                    for nDie = 1, nDice do
                        nTotal = nTotal + rand(1, nSides);
                    end

                end

                nGrandTotal = (nTotal > nGrandTotal) and nTotal or nGrandTotal;
            end

        end

        return nGrandTotal;
    end,
    --[[!
    @fqxn LuaEx.CoG.Classes.RNG.Methods.rollPercentage
    @vis Static Public
    @desc Rolls a percentage chance based on the input value.
    <br>The number of sides on the dice is determined by the <strong><em>nSides</em></strong> parameter (defaults to 6).
    <br>The number of dice to roll is determined by the <strong><em>nDice</em></strong> parameter (defaults to 1).
    <br>The number of attempts is determined by the <strong><em>nAttempts</em></strong> parameter (defaults to 1).
    <br> If the number of attempts is set to a value greater than 1, the roll will happen that many times or until it is successful (if successful before the number of attempts runs out).
    @param number|nil nChance The percentage chance at success (defaults to 100).
    @param number|nil nAttempts The total number of attempts allowed to make the roll (defaults to 1).
    @ret boolean bSuccess True if the roll was successful, false otherwise.
    !]]
    rollPercentage = function(nChance, nAttempts)
        local bSuccess;
        nChance = (  rawtype(nChance) == "number" and nChance > 0 and nChance <= 100) and
                    ceil(nChance) or 50;
        nAttempts = (  rawtype(nAttempts) == "number" and nAttempts > 0) and
                    ceil(nAttempts) or 1;

        local nRoll = 100;

        if (nAttempts == 1) then
            nRoll = rand(1, 100);
        else
            local nNewRoll;

            for nRollID = 1, nAttempts do
                nNewRoll = rand(1, 100);
                nRoll = nNewRoll < nRoll and nNewRoll or nRoll;

                bSuccess = nRoll <= nChance;

                if (bSuccess) then
                    break;
                end

            end

        end

        return bSuccess, nRoll, nChance - nRoll;
    end,
    --RNG = function(stapub) end,
},
{--PRIVATE
    RNG = function(this, cdat)
    end,
},
{--PROTECTED

},
{--PUBLIC

},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);
