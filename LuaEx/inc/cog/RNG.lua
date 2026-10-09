local table = table;
local math  = math;
local floor = math.floor;
local rand  = math.random;

local _nDefaultDieSides     = 6;
local _n100                 = 100;
local _nDefaultCheckSides   = 20;
local _nDefaultWeight       = 0.5;

local function validateFinite(nValue, sName)
    type.assert.number(nValue);
    assert(nValue == nValue and nValue > -math.huge and nValue < math.huge,
           sName.." must be finite.");
end


local function validateInteger(nValue, nDefault, nMinimum, sName)
    nValue = nValue == nil and nDefault or nValue;
    validateFinite(nValue, sName);
    assert(nValue % 1 == 0, sName.." must be an integer.");
    assert(nMinimum == nil or nValue >= nMinimum, sName.." is below its minimum.");
    assert(math.maxinteger == nil or (nValue <= math.maxinteger and nValue >= math.mininteger),
           sName.." is outside the supported integer range.");

    return nValue;
end


local function weightedSuccess(vWeight)
    local nWeight = vWeight == nil and _nDefaultWeight or vWeight;
    validateFinite(nWeight, "Weight");
    assert(nWeight >= 0 and nWeight <= 1, "Weight must be between 0 and 1.");

    -- Draws are in [0, 1). Strict comparison makes zero weight always fail,
    -- including when the draw itself is exactly zero.
    local bSuccess = rand() < nWeight;

    return bSuccess;
end


--[[!
@fqxn CoG.RNG
@desc A static helper class for rolling dice, drawing cards, etc. Uses the shared math.random stream; callers control seeding with math.randomseed. Defaults apply only to omitted/nil arguments. Invalid supplied inputs raise errors. All numeric inputs must be finite; die sides and counts must be integers.
@pulsarlua table RNG
!]]
return class("RNG",
{--METAMETHODS

},
{--STATIC PUBLIC
    --[[!
    @fqxn CoG.RNG.Methods.binary
    @vis Static Public
    @desc Generates a random value of 0 or 1.
    @param number|nil vWeight An optional float value that indicates whether to favor the lower or higher result. A higher weight favors 1s while a lower weight value favors 0s. E.g., a weight value of 0.2 will produce a <b>0</b> 80% of the time and a <b>1</b> 20% of the time, while a value of 0.75 will produce a <b>1</b> 75% of the time and a <b>0</b> 25% of the time.
    <br>A nil value will force the default weight of 0.5. Supplied weights must be finite numbers in [0, 1]; 0 always selects the lower/first result, and 1 always selects the higher/second result.
    @ret number nResult Randomly, 0 or 1.
    @pulsarlua function RNG.binary
    @ex
    print(tostring(RNG.binary())) --randomly, 0 or 1
    @ex
    local nZeros = 0;
    local nOnes = 0;
    local nWeight = 0.33;
    local nTrials = 100000;

    for x = 1, nTrials do
      local nRes = RNG.binary(nWeight);

      if nRes == 0 then
        nZeros = nZeros + 1;
      elseif nRes == 1 then
        nOnes = nOnes + 1;
      end

    end

    print("Using a weight value of "..nWeight.." for "..nTrials.." trials.",
          "\r\nZeroes Rate: "..nZeros / nTrials,
          "\r\nOnes Rate: "..nOnes / nTrials);
    !]]
    binary = function(vWeight)
        local nResult = weightedSuccess(vWeight) and 1 or 0;

        return nResult;
    end,

    --[[!
    @fqxn CoG.RNG.Methods.bipolar
    @vis Static Public
    @desc Generates a random value of -1 or 1.
    @pulsarlua function RNG.bipolar
    @param number|nil vWeight An optional float value that indicates whether to favor the lower or higher result. A higher weight favors 1s while a lower weight value favors -1s. E.g., a weight value of 0.2 will produce a <b>-1</b> 80% of the time and a <b>1</b> 20% of the time, while a value of 0.75 will produce a <b>1</b> 75% of the time and a <b>-1</b> 25% of the time.
    <br>A nil value will force the default weight of 0.5. Supplied weights must be finite numbers in [0, 1]; 0 always selects the lower/first result, and 1 always selects the higher/second result.
    @ret number nResult Randomly, -1 or 1.
    @ex
    print(tostring(RNG.bipolar())) --randomly, -1 or 1
    @ex
    local nLows = 0;
    local nHighs = 0;
    local nWeight = 0.75;
    local nTrials = 100000;

    for x = 1, nTrials do
      local nRes = RNG.bipolar(nWeight);

      if nRes == -1 then
        nLows = nLows + 1;
      elseif nRes == 1 then
        nHighs = nHighs + 1;
      end

    end

    print("Using a weight value of "..nWeight.." for "..nTrials.." trials.",
          "\r\n-1s Rate: "..nLows / nTrials,
          "\r\n1s Rate: "..nHighs / nTrials);
    !]]
    bipolar = function(vWeight)
        local nResult = weightedSuccess(vWeight) and 1 or -1;

        return nResult;
    end,

    --[[!
    @fqxn CoG.RNG.Methods.boolean
    @vis Static Public
    @desc Generates a random boolean value.
    @pulsarlua function RNG.boolean
    @param number|nil vWeight An optional float value that indicates whether to favor the lower or higher result. A higher weight favors trues while a lower weight value favors falses. E.g., a weight value of 0.2 will produce a <b>false</b> 80% of the time and a <b>true</b> 20% of the time, while a value of 0.75 will produce a <b>true</b> 75% of the time and a <b>false</b> 25% of the time.
    <br>A nil value will force the default weight of 0.5. Supplied weights must be finite numbers in [0, 1]; 0 always selects the lower/first result, and 1 always selects the higher/second result.
    @ret boolean bFlag Randomly, true or false.
    @ex
    print(tostring(RNG.boolean())) --randomly, true or false
    @ex
    local nLows = 0;
    local nHighs = 0;
    local nWeight = 0.10;
    local nTrials = 100000;

    for x = 1, nTrials do
      local bRes = RNG.boolean(nWeight);

      if bRes == false then
        nLows = nLows + 1;
      elseif bRes == true then
        nHighs = nHighs + 1;
      end

    end

    print("Using a weight value of "..nWeight.." for "..nTrials.." trials.",
          "\r\nFalse Rate: "..nLows / nTrials,
          "\r\nTrue Rate: "..nHighs / nTrials);
    !]]
    boolean = function(vWeight)
        return weightedSuccess(vWeight);
    end,

    --[[!
    @fqxn CoG.RNG.Methods.choice
    @vis Static Public
    @desc Chooses between two input values.
    @param Any vItem1 Any non-nil value;
    @param Any vItem2 Any non-nil value;
    @param number|nil vWeight An optional float value that indicates whether to favor the <b>first</b> or <b>second</b> input value. A higher weight favors the <b>second</b> while a lower weight value favors the <b>first</b>. E.g., a weight value of 0.2 will choose the <b>first</b> input value 80% of the time and the <b>second</b> input value 20% of the time, while a value of 0.75 will choose the <b>second</b> input value 75% of the time and the <b>first</b> input value 25% of the time.
    <br>A nil value will force the default weight of 0.5. Supplied weights must be finite numbers in [0, 1]; 0 always selects the lower/first result, and 1 always selects the higher/second result.
    @ret any vRet Either the <b>first</b> or <b>second</b> input value.
    @ex
    print(tostring(RNG.choice("Bunny", "Cat"))) --Randomly, "Bunny" or "Cat"
    @ex
    local vItem1 = "Bunny";
    local vItem2 = 31;

    local nLows = 0;
    local nHighs = 0;
    local nWeight = 0.66;
    local nTrials = 100000;

    for x = 1, nTrials do
      local vRes = RNG.choice(vItem1, vItem2, nWeight);

      if vRes == vItem1 then
        nLows = nLows + 1;
      elseif vRes == vItem2 then
        nHighs = nHighs + 1;
      end

    end

    print("Using a weight value of "..nWeight.." for "..nTrials.." trials.",
          "\r\nItem1 Rate: "..nLows / nTrials,
          "\r\nItem2 Rate: "..nHighs / nTrials);
    !]]
    choice = function(vItem1, vItem2, vWeight)
        assert(vItem1 ~= nil and vItem2 ~= nil, "Choice items cannot be nil.");
        local vRet = vItem1;

        -- Use an explicit branch: false is a valid choice, not a fallback trigger.

        if (weightedSuccess(vWeight)) then
            vRet = vItem2;
        end

        return vRet;
    end,

    --[[!
    @fqxn CoG.RNG.Methods.multiChoice
    @vis Static Public
    @desc Accepts a variable number of arguments and randomly selects one of them. It is an unweighted selection, meaning each argument has an equal chance of being chosen.
    @param any ... At least one item to choose from; nil arguments are rejected. These can be of any non-nil type (numbers, strings, tables, etc.).
    @ex
    -- Example 1: Randomly select a fruit from a list
    local sSelectedFruit = RNG.multiChoice("apple", "banana", "cherry");
    print("Selected fruit: " .. sSelectedFruit)

    -- Example 2: Randomly select a number from a list
    local nSelectedNumber = RNG.multiChoice(10, 20, 30, 40, 50);
    print("Selected number: " .. nSelectedNumber)

    -- Example 3: Randomly select a color from a list
    local sSelectedColor = RNG.multiChoice("red", "green", "blue", "yellow");
    print("Selected color: " .. sSelectedColor)

    -- Example 4: Randomly select from mixed types (string, number, boolean)
    local vSelectedItem = RNG.multiChoice("apple", 42, true, "banana", 3.14, false);
    print("Selected item: " .. tostring(vSelectedItem))

    @ret any vItem One of the provided arguments, randomly selected.
    !]]
    multiChoice = function(...)
        local nItems = select("#", ...);
        assert(nItems > 0, "multiChoice requires at least one item.");

        -- select counts nil arguments too, so holes cannot silently skew selection.

        for nIndex = 1, nItems do
            assert(select(nIndex, ...) ~= nil, "multiChoice items cannot be nil.");
        end

        local nIndex = rand(1, nItems);
        local vRet = select(nIndex, ...);

        return vRet;
    end,
    --[[Gaussian (Normal) Distribution-based weighted random function
weightedRandom = function(nMin, nMax, vWeight)
    -- Default to nil if no weight is provided
    local nWeight = vWeight or nil
    local nRet

    -- If no weight is provided, just pick randomly in the range
    if not nWeight then
        return math.random(nMin, nMax)
    end

    -- Bell curve distribution: use nWeight as the mean of the distribution
    local nMean = nMin + (nMax - nMin) * nWeight  -- The weighted value
    local nDeviation = (nMax - nMin) / 6  -- Standard deviation, adjusting for the full range

    -- Apply Gaussian-like behavior using the Box-Muller transform to generate Gaussian-distributed values
    -- Generates two independent standard normally distributed random numbers
    local u1 = math.random()
    local u2 = math.random()
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)

    -- Scale the result to match the desired distribution
    local nGaussian = z0 * nDeviation + nMean

    -- Adjust the final result based on the Gaussian spread
    local nResult = math.floor(nGaussian)

    -- Ensure the result stays within bounds, but allow any value in range to be possible
    nRet = math.max(nMin, math.min(nMax, nResult))

    return nRet
end]]
    --[[!
    @fqxn CoG.RNG.Methods.percent
    @vis Static Public
    @desc Generates a percentage value.
    @param boolean|nil bFloat Must be boolean when supplied. Whether the result should be a float from 0.01-1 or an int from 1-100 (defaults to false).
    @ex
    print(tostring(RNG.percent(true)))  --generates a random float from 0.01-1 (inclusive).
    print(tostring(RNG.percent()))      --generates a random int from 1-100 (inclusive).
    @ret number nPercent An int or float value from 1-100 or 0.01-1 respectively (inclusive).
    !]]
    percent = function(bFloat)
        assert(bFloat == nil or type(bFloat) == "boolean", "Float flag must be boolean.");
        local nResult = rand(1, _n100);

        if (bFloat) then
            nResult = nResult / _n100;
        end

        return nResult;
    end,

    --[[!
        @fqxn CoG.RNG.Methods.pick
        @vis Static Public
        @desc Selects and returns a single random element from a numerically indexed table. Supports sparse tables and both 0-based and 1-based numeric indexing.
        @param table tInput A table containing numeric indices to choose from.
        @ret any vItem One randomly selected item from the table, or nil if no numeric entries exist in single-pick mode. With nPicks, returns a list; impossible counts raise an error. The source is unchanged.
        @param number|nil nPicks Optional nonnegative integer count. When supplied, returns a list of picks; zero returns an empty list.
        @param boolean|nil bAllowRepeats Allows the same source entry more than once when true; defaults to false. Distinct entries may hold equal values.
        @ex
        local vPick = RNG.pick({[0] = "A", [8] = "B"});
        local tPicks = RNG.pick({"A", "B", "C"}, 2, false);
    !]]
    pick = function(tInput, nPicks, bAllowRepeats)
        type.assert.table(tInput);
        assert(bAllowRepeats == nil or type(bAllowRepeats) == "boolean", "Repeat flag must be boolean.");
        local bMultiple = nPicks ~= nil;

        if (bMultiple) then
            nPicks = validateInteger(nPicks, 1, 0, "Pick count");
        end

        local tKeys = {};

        for vKey in pairs(tInput) do

            if (type(vKey) == "number") then
                tKeys[#tKeys + 1] = vKey;
            end

        end

        -- Stable key order makes seeded picks reproducible even for sparse lists.
        table.sort(tKeys);
        local vRet;

        if (bMultiple) then
            assert(nPicks == 0 or #tKeys > 0, "Cannot pick from an empty numeric list.");
            assert(bAllowRepeats or nPicks <= #tKeys, "Pick count exceeds entries without repeats.");
            vRet = {};

            for nPick = 1, nPicks do
                local nIndex = rand(1, #tKeys);
                vRet[nPick] = tInput[tKeys[nIndex]];

                -- Remove only the copied key. Never mutate the caller's source list.

                if not (bAllowRepeats) then
                    table.remove(tKeys, nIndex);
                end

            end

        elseif (#tKeys > 0) then
            vRet = tInput[tKeys[rand(1, #tKeys)]];
        end

        return vRet;
    end,

    --[[!
        @fqxn CoG.RNG.Methods.randomx
        @desc Returns an integer in [1, N] with exponential bias.
        <br>N must be an integer in [1,10]. Each step upward has nWeight times the probability of the preceding step (half as likely at the default weight 0.5).
        <br><br>
        -- Weight reference (approximate behavior)
        -- 1.00 → uniform (no bias)
        -- 0.80 → gentle bias (most values possible)
        -- 0.65 → noticeable bias
        -- 0.50 → strong bias (small values common)
        -- 0.30 → very strong bias
        -- 0.10 → extreme bias (almost always 1)
        @ex local function TestRandomX(nMax, nRuns, nWeight)
            local tCount = {};

            for i = 1, nMax do
                tCount[i] = 0;
            end

            for i = 1, nRuns do
                local nV = RNG.randomx(nMax, nWeight);
                tCount[nV] = tCount[nV] + 1;
            end

            print(("RNG.randomx(%d), weight = %.2f, runs = %d")
                :format(nMax, nWeight, nRuns));
            print("--------------------------------");

            for i = 1, nMax do
                local nPct = (tCount[i] / nRuns) * 100;
                print(("%2d : %6.2f%%"):format(i, nPct));
            end

            print("");
        end

        TestRandomX(10, 100000, 0.5);
        TestRandomX(10, 100000, 0.8);
        @param number|nil nMax Requested integer maximum from 1 through 10; defaults to 1.
        @param number|nil vWeight A finite value between 0.01 and 1 (inclusive) that sets the ratio from one number to the next; defaults to 0.5. Invalid inputs are rejected rather than clamped.
        @ret number nResult Biased random integer.
    !]]
    randomx = function(nMax, vWeight)
        nMax = validateInteger(nMax, 1, 1, "Maximum");
        assert(nMax <= 10, "randomx maximum must be between 1 and 10.");
        local nWeight = vWeight == nil and _nDefaultWeight or vWeight;
        validateFinite(nWeight, "Weight");
        assert(nWeight >= 0.01 and nWeight <= 1, "randomx weight must be between 0.01 and 1.");

        -- Geometric weights 1, w, w^2, ... form a truncated distribution.
        -- Weight 1 makes all entries equally likely; smaller weights favor lows.
        local nSum = 0;
        local nTerm = 1;

        for nIndex = 1, nMax do
            nSum = nSum + nTerm;
            nTerm = nTerm * nWeight;
        end

        local nDraw = rand() * nSum;
        local nAcc = 0;
        local nResult = nMax;
        nTerm = 1;

        for nIndex = 1, nMax do
            nAcc = nAcc + nTerm;

            if (nDraw < nAcc) then
                nResult = nIndex;
                break;
            end

            nTerm = nTerm * nWeight;
        end

        -- The initialized result covers any final floating-point rounding gap.
        return nResult;
    end,

    --[[!
    @fqxn CoG.RNG.Methods.rollCheck
    @vis Static Public
    @desc Determines whether a check is made based on the input. Often used for things like stat checks. The check will be successful if the number rolled by the function is equal to or higher than the <strong><em>nCheck</em></strong> parameter.
    @param number|nil nSides Positive integer die sides; defaults to 20.
    @param number|nil nCheck Finite integer success threshold; defaults to 10. Values below 1 always succeed, and values above nSides always fail.
    @ret boolean bSuccess True if the check was successful or false otherwise.
    @ret number nRoll The die result.
    @ret number nMargin The roll minus the threshold.
    @ex local bSuccess, nRoll, nMargin = RNG.rollCheck(20, 12);
    !]]
    rollCheck = function(nSides, nCheck)
        nSides = validateInteger(nSides, _nDefaultCheckSides, 1, "Die sides");
        nCheck = validateInteger(nCheck, _nDefaultCheckSides / 2, nil, "Check threshold");

        local nRoll = rand(1, nSides);
        local bSuccess = nRoll >= nCheck;

        return bSuccess, nRoll, nRoll - nCheck;
    end,

    --[[!
    @fqxn CoG.RNG.Methods.rollDice
    @vis Static Public
    @desc Rolls a number of dice, returning the sum total of the roll.
    <br>The number of sides on the dice is determined by the <strong><em>nSides</em></strong> parameter (defaults to 6).
    <br>The number of dice to roll is determined by the <strong><em>nDice</em></strong> parameter (defaults to 1).
    <br>The number of attempts is determined by the <strong><em>nAttempts</em></strong> parameter (defaults to 1).
    <br> If the number of attempts is set to a value greater than 1, the roll will happen that many times, keeping only the highest total out of all the attempts.
    @param number|nil nSides Positive integer die sides; defaults to 6.
    @param number|nil nDice Positive integer number of dice; defaults to 1.
    @param number|nil nAttempts Positive integer number of complete rolls; defaults to 1.
    @ret number nTotal The highest sum from the complete attempts.
    @ex local nTotal = RNG.rollDice(6, 3, 2); -- Best of two complete 3d6 rolls.
    !]]
    rollDice = function(nSides, nDice, nAttempts)
        nSides = validateInteger(nSides, _nDefaultDieSides, 1, "Die sides");
        nDice = validateInteger(nDice, 1, 1, "Dice count");
        nAttempts = validateInteger(nAttempts, 1, 1, "Attempt count");

        assert(math.maxinteger == nil or nDice <= floor(math.maxinteger / nSides),
               "Maximum dice total exceeds the integer range.");
        local nGrandTotal = 0;

        -- Each attempt rolls a fresh complete set of dice; keep its best total.
        -- Every random draw contributes a die result, with no discarded draws.

        for nAttempt = 1, nAttempts do
            local nTotal = 0;

            for nDie = 1, nDice do
                local nRoll = rand(1, nSides);
                assert(math.maxinteger == nil or nTotal <= math.maxinteger - nRoll,
                       "Dice total exceeds the integer range.");
                nTotal = nTotal + nRoll;
            end

            nGrandTotal = math.max(nGrandTotal, nTotal);
        end

        return nGrandTotal;
    end,

    --[[!
    @fqxn CoG.RNG.Methods.rollPercentage
    @vis Static Public
    @desc Rolls a percentage chance based on the input value.
    <br>The number of attempts is determined by the <strong><em>nAttempts</em></strong> parameter (defaults to 1).
    <br> If the number of attempts is set to a value greater than 1, the roll will happen that many times or until it is successful (if successful before the number of attempts runs out).
    @param number|nil nChance Finite chance in [0, 100], including exact fractional percentages; defaults to 50. Zero always fails and 100 always succeeds.
    @param number|nil nAttempts Positive integer number of attempts; defaults to 1.
    @ret boolean bSuccess True if any attempt succeeded, false otherwise.
    @ret number nRoll The lowest percentage roll made, in (0, 100]; may be fractional.
    @ret number nMargin The chance minus the lowest roll.
    @ex local bSuccess, nRoll, nMargin = RNG.rollPercentage(12.5, 3);
    !]]
    rollPercentage = function(nChance, nAttempts)
        nChance = nChance == nil and 50 or nChance;
        validateFinite(nChance, "Chance");
        assert(nChance >= 0 and nChance <= _n100, "Chance must be between 0 and 100.");
        nAttempts = validateInteger(nAttempts, 1, 1, "Attempt count");

        local nRoll = _n100;
        local bSuccess = false;

        for nAttempt = 1, nAttempts do
            -- Draw in (0, 100]: zero chance cannot succeed, and fractional
            -- chances retain their supplied probability instead of rounding up.
            local nNewRoll = (1 - rand()) * _n100;
            nRoll = math.min(nRoll, nNewRoll);
            bSuccess = nRoll <= nChance;

            if (bSuccess) then
                break;
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
