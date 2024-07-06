--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then
    --sSourccePath = "";

    function getsourcepath()
        --determine the call location
        local sPath = debug.getinfo(1, "S").source;
        --remove the calling filename
        local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
        --make a pattern to account for case
        local sFilename = "";
        for x = 1, #sFilenameRAW do
            local sChar = sFilenameRAW:sub(x, x);

            if (sChar:find("[%a]")) then
                sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
            else
                sFilename = sFilename..sChar;
            end

        end
        sPath = sPath:gsub("@", ""):gsub(sFilename, "");
        --remove the "/" at the end
        sPath = sPath:sub(1, sPath:len() - 1);

        return sPath;
    end

    --determine the call location
     sSourcePath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sSourcePath.."\\..\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================
local oPool = Pool(200, 200, 50);

oPool.setEventCallback(Pool.EVENT.ON_CYCLE, function(this,nRegen, nMultiplier, nCurrent, nNew, nMax, bSkipOnFull, bSkipOnEmpty, bSkipOnIncrease, bSkipOnDecrease) print("regen to x("..nMultiplier..") -> "..this.get()) end);

oPool.setEventCallback(Pool.EVENT.ON_EMPTY, function(this) print("set to empty! -> "..this.get()) end);

oPool.setEventCallback(Pool.EVENT.ON_FULL, function(this) print("set to full! -> "..this.get()) end);

oPool.setEventCallback(Pool.EVENT.ON_RESERVE, function(this) print("reserved! -> "..this.get(Pool.ASPECT.RESERVED)) end);
--oPool.setEventActive("onRegen");

--print(oPool.getCurrent());
--print(oPool.c().getValue())
--oPool.setCurrentModifier(Protean.BASE_BONUS, 10);
--oPool.setCurrentModifier(Protean.ADDATIVE_BONUS, 100);
--oPool.setMaxModifier(Protean.MULTIPLICATIVE_BONUS, 0.2);
--print(oPool.c().getValue())
--print("max: "..oPool.getMax());
--oPool.adjustRegen(12);
--oPool.regen(60);
--oPool.setEmpty();
--print(oPool.isEmpty())
--oPool.setCurrent(-114);
--oPool.setCurrent(1);
--oPool.adjustCurrent(10);
--oPool.adjustCurrent(10);
--print("current: "..oPool.get(Pool.ASPECT.RESERVED, nil, Pool.MODIFIER.ADDITIVE_BONUS));
--oPool.set(22);
--print("current value: "..oPool.get());
--oPool.set(0.4, Pool.ASPECT.REGEN, Pool.MODIFIER.MULTIPLICATIVE_BONUS);
--oPool.regen(9);
--oPool.setFull();
--print("current value: "..oPool.get());
--oPool.setEmpty();
--oPool.set(10, Pool.ASPECT.REGEN, Pool.MODIFIER.BASE)
--oPool.regen(5);
--oPool.setFull();
print("is Full: "..oPool.isFull());
oPool.setFullMarker(0.1);
oPool.set(0.2, Pool.ASPECT.RESERVED_PERCENT);
print("is Full: "..oPool.isFull());
print("current value: "..oPool.get());
