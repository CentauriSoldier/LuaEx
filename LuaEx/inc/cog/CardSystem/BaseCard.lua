--LOCALIZATION
local class = class;

local function validateValue(nValue)
    assert(rawtype(nValue) == "number" and nValue == nValue and math.abs(nValue) < math.huge,
           "Card value must be a finite number.");
end

--[[!
    @fqxn CoG.CardSystem.BaseCard
    @desc Common card metadata and presentation state. Suit and rank are optional
    labels; value is numeric. Concrete games define effects and scoring rules.
!]]
return class("BaseCard",
{--METAMETHODS
    __clone = function(this)
        assert(class.of(this) == BaseCard, "BaseCard subclasses must implement __clone for their own state.");
        local oCopy = BaseCard(this.getName(), this.getDescription(), this.getRarity(), nil,
                              this.getSuit(), this.getRank(), this.getValue(), this.isFaceUp(), this.isEnabled());

        for sTag, bEnabled in this.getTagSystem().eachTag() do
            oCopy.getTagSystem().add(sTag, not bEnabled);
        end

        return oCopy;
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
},
{--PROTECTED
    Suit__autoA_ = "",
    Rank__autoA_ = "",
    Value__autoA_ = 0,
    FaceUp__autoA_is = false,
    Enabled__autoA_is = true,
},
{--PUBLIC
    BaseCard = function(this, cdat, super, sName, sDescription, eRarity, wEventrix,
                        sSuit, sRank, nValue, bFaceUp, bEnabled)
        assert(sSuit == nil or rawtype(sSuit) == "string", "Card suit must be a string.");
        assert(sRank == nil or rawtype(sRank) == "string", "Card rank must be a string.");
        nValue = nValue == nil and 0 or nValue;
        validateValue(nValue);
        assert(bFaceUp == nil or rawtype(bFaceUp) == "boolean", "FaceUp must be a boolean.");
        assert(bEnabled == nil or rawtype(bEnabled) == "boolean", "Enabled must be a boolean.");
        super(sName or "Card", sDescription or "A card.", eRarity, wEventrix);
        local pro = cdat.pro;
        pro.Suit, pro.Rank, pro.Value = sSuit or "", sRank or "", nValue;
        pro.FaceUp = bFaceUp == true;
        pro.Enabled = bEnabled ~= false;
    end,

    setSuit = function(this, cdat, sSuit)
        assert(rawtype(sSuit) == "string", "Card suit must be a string.");
        cdat.pro.Suit = sSuit;
        return this;
    end,

    setRank = function(this, cdat, sRank)
        assert(rawtype(sRank) == "string", "Card rank must be a string.");
        cdat.pro.Rank = sRank;
        return this;
    end,

    setValue = function(this, cdat, nValue)
        validateValue(nValue);
        cdat.pro.Value = nValue;
        return this;
    end,

    setFaceUp = function(this, cdat, bFaceUp)
        assert(rawtype(bFaceUp) == "boolean", "FaceUp must be a boolean.");
        cdat.pro.FaceUp = bFaceUp;
        return this;
    end,

    setEnabled = function(this, cdat, bEnabled)
        assert(rawtype(bEnabled) == "boolean", "Enabled must be a boolean.");
        cdat.pro.Enabled = bEnabled;
        return this;
    end,

    flip = function(this, cdat)
        cdat.pro.FaceUp = not cdat.pro.FaceUp;
        return this;
    end,

    reveal = function(this)
        return this.setFaceUp(true);
    end,

    hide = function(this)
        return this.setFaceUp(false);
    end,
},
BaseObject,
false,
nil
);
