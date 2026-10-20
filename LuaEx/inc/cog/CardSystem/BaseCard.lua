--LOCALIZATION
local class = class;

--[[!
    @fqxn CoG.CardSystem.BaseCard
    @desc Generic foundation for any card: abilities, characters, resources, quests,
    collectibles or other developer-defined types. Concrete games define fields,
    effects and rules. No suit, rank or numeric value is required or provided.
    Methods use dot calls. FaceUp and Enabled are metadata flags, not game-rule
    enforcement. Generated flag getters are isFaceUp and isEnabled. Name, description,
    rarity, tags and event support come from CoGObject.
    @ex
    local card = BaseCard("Fireball", "A spell card.");
    card.reveal();
!]]
return class("BaseCard",
{--METAMETHODS
    --[[!
        @fqxn CoG.CardSystem.BaseCard.Metamethods.__clone
        @desc Clones a plain BaseCard with its metadata, presentation flags and tag enabled states.
        Creates fresh base infrastructure; existing event handlers and affixes are not copied.
        Subclasses must implement their own clone to preserve additional state.
        @ret BaseCard oCopy Independent card and tag system.
        @vis public
    !]]
    __clone = function(this)
        -- Step 1: prevent cloning a subclass into a BaseCard and losing its own state.
        assert(class.of(this) == BaseCard, "BaseCard subclasses must implement __clone for their own state.");
        -- Step 2: reconstruct metadata/flags with fresh base event infrastructure.
        local oCopy = BaseCard(this.getName(), this.getDescription(), this.getRarity(), nil,
                              this.isFaceUp(), this.isEnabled());

        -- Step 3: copy every tag, converting enabled state to add's disabled flag.
        for sTag, bEnabled in this.getTagSystem().eachTag() do
            oCopy.getTagSystem().add(sTag, not bEnabled);
        end

        -- Step 4: return the independent card after tag reconstruction succeeds.
        return oCopy;
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
},
{--PROTECTED
    -- Auto directives provide public accessors; explicit setters below validate input.
    FaceUp__autoA_is = false,
    Enabled__autoA_is = true,
},
{--PUBLIC
    --[[!
        @fqxn CoG.CardSystem.BaseCard.Methods.BaseCard
        @desc Validates optional presentation flags before initializing CoGObject. FaceUp defaults
        to false and Enabled to true. CoGObject validates name/description and resolves rarity.
        Specialized card fields and effects belong to developer-defined subclasses.
        @param string|nil sName Name passed to CoGObject; defaults to Card.
        @param string|nil sDescription Description passed to CoGObject; defaults to A card.
        @param Rarity.LEVEL|nil eRarity Rarity passed to CoGObject; invalid/omitted values use its
        default.
        @param table|nil wEventrix Optional event-handler environment passed to CoGObject.
        @param boolean|nil bFaceUp Whether the card starts face up, default false.
        @param boolean|nil bEnabled Whether the card starts enabled, default true.
        @vis public
    !]]
    BaseCard = function(this, cdat, super, sName, sDescription, eRarity, wEventrix,
                        bFaceUp, bEnabled)
        -- Step 1: validate only shared presentation flags.
        assert(bFaceUp == nil or rawtype(bFaceUp) == "boolean", "FaceUp must be a boolean.");
        assert(bEnabled == nil or rawtype(bEnabled) == "boolean", "Enabled must be a boolean.");
        -- Step 2: initialize inherited metadata, event support and a fresh tag system.
        super(sName or "Card", sDescription or "A card.", eRarity, wEventrix);
        -- Step 3: resolve shared presentation defaults without specialized traits.
        local pro = cdat.pro;
        pro.FaceUp = bFaceUp == true;
        -- Explicit false disables the card; nil and true leave it enabled.
        pro.Enabled = bEnabled ~= false;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseCard.Methods.setFaceUp
        @desc Sets the presentation flag after boolean validation. Does not implement visibility
        permissions or game-specific reveal effects.
        @param boolean bFaceUp True for face up; false for face down.
        @ret BaseCard this Card for chaining.
        @vis public
    !]]
    setFaceUp = function(this, cdat, bFaceUp)
        -- Step 1: validate the new field type before changing protected state.
        assert(rawtype(bFaceUp) == "boolean", "FaceUp must be a boolean.");
        -- Step 2: commit the value and return this card for chaining.
        cdat.pro.FaceUp = bFaceUp;
        return this;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseCard.Methods.setEnabled
        @desc Sets the enabled metadata flag after boolean validation. Gameplay code decides what
        enabled/disabled means; this method does not execute card effects.
        @param boolean bEnabled New enabled state.
        @ret BaseCard this Card for chaining.
        @vis public
    !]]
    setEnabled = function(this, cdat, bEnabled)
        -- Step 1: validate the new field type before changing protected state.
        assert(rawtype(bEnabled) == "boolean", "Enabled must be a boolean.");
        -- Step 2: commit the value and return this card for chaining.
        cdat.pro.Enabled = bEnabled;
        return this;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseCard.Methods.flip
        @desc Toggles FaceUp while preserving all other card data.
        @ret BaseCard this Card for chaining.
        @vis public
    !]]
    flip = function(this, cdat)
        -- Invert the presentation flag directly; other fields are unchanged.
        cdat.pro.FaceUp = not cdat.pro.FaceUp;
        return this;
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseCard.Methods.reveal
        @desc Sets FaceUp to true through the validated setter. Revealing an already face-up card is
        a normal no-op.
        @ret BaseCard this Card for chaining.
        @vis public
    !]]
    reveal = function(this)
        -- Use the setter to keep presentation changes on the same validated path.
        return this.setFaceUp(true);
    end,

    --[[!
        @fqxn CoG.CardSystem.BaseCard.Methods.hide
        @desc Sets FaceUp to false through the validated setter. Hiding an already face-down card is
        a normal no-op.
        @ret BaseCard this Card for chaining.
        @vis public
    !]]
    hide = function(this)
        -- Use the setter with an explicit false rather than applying a default.
        return this.setFaceUp(false);
    end,
},
CoGObject,
false,
nil
);
