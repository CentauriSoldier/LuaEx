local table = table;
local math  = math;
local ceil  = math.ceil;
local floor = math.floor;
local rand  = math.random;

local _nDefaultDieSides     = 6;
local _n100                 = 100;
local _nDefaultCheckSides   = 20;
local _nDefaultWeight       = 0.5;

--[[!
@fqxn CoG.RNG
@desc A static helper class for rolling dice, drawing cards, etc.
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
    @ret number 0 or 1.
    <br>A nil value will force the default weight of 0.5.
    @ex
    print(tostring(RNG.binary())) --randomly, 0 or 1
    @ex
    local nZeros = 0;
    local nOnes = 0;
    local nWeight = 0.33;
    local nTrials = 100000;

    for x = 1, nTrials do
      local nRes = binary(nWeight);

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
        local nWeight = vWeight or _nDefaultWeight;
        local nProbability = rand();
        return nProbability > nWeight and 0 or 1;
    end,
    --[[!
    @fqxn CoG.RNG.Methods.bipolar
    @vis Static Public
    @desc Generates a random value of -1 or 1.
    @param number|nil vWeight An optional float value that indicates whether to favor the lower or higher result. A higher weight favors 1s while a lower weight value favors -1s. E.g., a weight value of 0.2 will produce a <b>-1</b> 80% of the time and a <b>1</b> 20% of the time, while a value of 0.75 will produce a <b>1</b> 75% of the time and a <b>-1</b> 25% of the time.
    <br>A nil value will force the default weight of 0.5.
    @ret boolean bFlag Randomly, true or false.
    @ret number -1 or 1.
    @ex
    print(tostring(RNG.bipolar())) --randomly, -1 or 1
    @ex
    local nLows = 0;
    local nHighs = 0;
    local nWeight = 0.75;
    local nTrials = 100000;

    for x = 1, nTrials do
      local nRes = bipolar(nWeight);

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
        local nWeight = vWeight or _nDefaultWeight;
        local nProbability = rand();
        return nProbability > nWeight and -1 or 1;
    end,
    --[[!
    @fqxn CoG.RNG.Methods.boolean
    @vis Static Public
    @desc Generates a random boolean value.
    @param number|nil vWeight An optional float value that indicates whether to favor the lower or higher result. A higher weight favors trues while a lower weight value favors falses. E.g., a weight value of 0.2 will produce a <b>false</b> 80% of the time and a <b>true</b> 20% of the time, while a value of 0.75 will produce a <b>true</b> 75% of the time and a <b>false</b> 25% of the time.
    <br>A nil value will force the default weight of 0.5.
    @ret boolean bFlag Randomly, true or false.
    @ex
    print(tostring(RNG.boolean())) --randomly, true or false
    @ex
    local nLows = 0;
    local nHighs = 0;
    local nWeight = 0.10;
    local nTrials = 100000;

    for x = 1, nTrials do
      local bRes = boolean(nWeight);

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
        local nWeight = vWeight or _nDefaultWeight;
        local nProbability = rand();
        return nProbability > nWeight and true or false;
    end,
    --[[!
    @fqxn CoG.RNG.Methods.choice
    @vis Static Public
    @desc Chooses between two input values.
    @param Any vItem1 Any non-nil value;
    @param Any vItem2 Any non-nil value;
    @param number|nil vWeight An optional float value that indicates whether to favor the <b>first</b> or <b>second</b> input value. A higher weight favors the <b>second</b> while a lower weight value favors the <b>first</b>. E.g., a weight value of 0.2 will choose the <b>first</b> input value 80% of the time and the <b>second</b> input value 20% of the time, while a value of 0.75 will choose the <b>second</b> input value 75% of the time and the <b>first</b> input value 25% of the time.
    <br>A nil value will force the default weight of 0.5.
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
      local vRes = choice(vItem1, vItem2, nWeight);

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
        local vRet = vItem1;
        local nWeight = vWeight or _nDefaultWeight;
        local nProbability = rand();

        if (nProbability < nWeight) then
            vRet = vItem2;
        end

        return vRet;
    end,
    --[[!
    @fqxn CoG.RNG.Methods.multiChoice
    @vis Static Public
    @desc Accepts a variable number of arguments and randomly selects one of them. It is an unweighted selection, meaning each argument has an equal chance of being chosen.
    @param ... (any number of arguments): The items to choose from. These can be of any non-nil type (numbers, strings, tables, etc.).
    @ex
    -- Example 1: Randomly select a fruit from a list
    local sSelectedFruit = multiChoice("apple", "banana", "cherry");
    print("Selected fruit: " .. sSelectedFruit)

    -- Example 2: Randomly select a number from a list
    local nSelectedNumber = multiChoice(10, 20, 30, 40, 50);
    print("Selected number: " .. nSelectedNumbernSelectedNumber)

    -- Example 3: Randomly select a color from a list
    local sSelectedColor = multiChoice("red", "green", "blue", "yellow");
    print("Selected color: " .. sSelectedColor)

    -- Example 4: Randomly select from mixed types (string, number, boolean)
    local vSelectedItem = multiChoice("apple", 42, true, "banana", 3.14, false);
    print("Selected item: " .. tostring(vSelectedItem))

    @ret vRet vItem One of the provided arguments, randomly selected.
    !]]
    multiChoice = function(...)--TODO add an optional weights table
        local vItems = {...}
        return vItems[math.random(#vItems)]
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
    @param boolean|nil bFloat Whether the result should be a float from 0.01-1 or an int from 1-100 (defaults to false).
    @ex
    print(tostring(RNG.percent(true)))  --generates a random float from 0.01-1 (inclusive).
    print(tostring(RNG.percent()))      --generates a random int from 1-100 (inclusive).
    @ret number nPercent An int or float value from 1-100 or 0.01-1 respectively (inclusive).
    !]]
    percent = function(bFloat)
        return bFloat and (rand(1, 100) / 100) or rand(1, 100);
    end,
    --[[!
    @fqxn CoG.RNG.Methods.rollCheck
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
    @fqxn CoG.RNG.Methods.rollDice
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
                rand();--rand();

                if nDice == 1 then
                    nTotal = rand(1, nSides);
                else

                    for nDie = 1, nDice do
                        rand();--rand();
                        nTotal = nTotal + rand(1, nSides);
                    end

                end

                nGrandTotal = (nTotal > nGrandTotal) and nTotal or nGrandTotal;
            end

        end

        return nGrandTotal;
    end,
    --[[!
    @fqxn CoG.RNG.Methods.rollPercentage
    @vis Static Public
    @desc Rolls a percentage chance based on the input value.
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
            bSuccess = nRoll <= nChance;
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
