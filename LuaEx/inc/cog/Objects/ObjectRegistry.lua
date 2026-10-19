--LOCALIZATION
local class = class;

local function prerequisiteTrue()
    return true;
end

local function prerequisiteFalse()
    return false;
end

local function validateEntry(vEntry)
    local cObject = class.is(vEntry) and vEntry or class.of(vEntry);
    assert((class.is(vEntry) or class.isinstance(vEntry)) and class.ischildorself(cObject, CoG),
           "ObjectRegistry entries must be CoG classes or instances.");
end

--[[!
    @fqxn CoG.ObjectRegistry
    @desc A mutable registry of allowed CoG classes and specific instances.
    Class entries match through inheritance; instance entries match exact identity.
    An object must match at least one entry before the prerequisite is called.
    Empty registries deny all objects. Register CoG to permit every CoG subtype.
    Methods use dot calls. Prerequisites receive (oObject, ...) and return a
    boolean, optionally followed by a string reason. Checks should not mutate
    game state. Callback errors propagate rather than silently denying access.
    @ex
    local oRegistry = ObjectRegistry({CoG}, nil, true);
    local bAllowed, sReason = oRegistry.allows(oActor, oItem, tContext);
!]]
return class("ObjectRegistry",
{--METAMETHODS
    -- Own the entry list independently; class/instance identities and the callback
    -- reference are shared intentionally. The callback's captured state is not cloned.
    --[[!
        @fqxn CoG.ObjectRegistry.Methods.__clone
        @desc Copies the entry array while retaining class/instance identities and the callback reference. Captured callback state is shared.
        @ret ObjectRegistry oCopy Independent registry.
    !]]
    __clone = function(this, cdat)
        local pri = cdat.pri;
        local tEntries = {};

        for nIndex, vEntry in ipairs(pri.entries) do
            tEntries[nIndex] = vEntry;
        end

        return ObjectRegistry(tEntries, pri.prerequisite, pri.defaultPrerequisite);
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.__len
        @desc Returns the number of stored entries.
        @ret number nCount Entry count.
    !]]
    __len = function(this, cdat)
        return #cdat.pri.entries;
    end,

},
{--STATIC PUBLIC
},
{--PRIVATE
    entries             = {},
    prerequisite        = prerequisiteTrue,
    defaultPrerequisite = true,
},
{--PROTECTED
},
{--PUBLIC
    --[[!
        @fqxn CoG.ObjectRegistry.Methods.ObjectRegistry
        @param table|nil tEntries An optional dense list of CoG classes or instances.
        @param function|nil fPrerequisite An optional additional eligibility check.
        @param boolean|nil bDefaultPrerequisite Dummy result; defaults to true.
        @desc A supplied callback takes precedence over the default dummy.
        @pulsarlua function ObjectRegistry
    !]]
    ObjectRegistry = function(this, cdat, tEntries, fPrerequisite, bDefaultPrerequisite)
        assert(bDefaultPrerequisite == nil or rawtype(bDefaultPrerequisite) == "boolean",
               "Default prerequisite must be a boolean or nil.");
        cdat.pri.defaultPrerequisite = bDefaultPrerequisite ~= false;
        this.setPrerequisite(fPrerequisite);

        if (tEntries ~= nil) then
            assert(rawtype(tEntries) == "table", "Registry entries must be a table.");
            local nCount = 0;

            for nIndex, vEntry in pairs(tEntries) do
                assert(rawtype(nIndex) == "number" and nIndex >= 1 and nIndex % 1 == 0,
                       "Registry entries must use positive integer indices.");
                validateEntry(vEntry);
                nCount = nCount + 1;
            end

            for nIndex = 1, nCount do
                assert(tEntries[nIndex] ~= nil, "Registry entry lists cannot contain holes.");
                this.add(tEntries[nIndex]);
            end

        end

    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.add
        @pulsarlua function ObjectRegistry.add
        @desc Adds a CoG class or instance unless the exact entry already exists.
        @param class|CoG vEntry Entry to register.
        @ret ObjectRegistry this This registry.
        @ret boolean bAdded Whether a new entry was inserted.
    !]]
    add = function(this, cdat, vEntry)
        validateEntry(vEntry);
        local tEntries = cdat.pri.entries;

        for _, vExisting in ipairs(tEntries) do

            if (rawequal(vExisting, vEntry)) then
                return this, false;
            end

        end

        tEntries[#tEntries + 1] = vEntry;
        return this, true;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.remove
        @pulsarlua function ObjectRegistry.remove
        @desc Removes only the exact class/instance entry, not its descendants.
        @param class|CoG vEntry Entry to remove.
        @ret ObjectRegistry this This registry.
        @ret boolean bRemoved Whether an entry was removed.
    !]]
    remove = function(this, cdat, vEntry)
        validateEntry(vEntry);
        local tEntries = cdat.pri.entries;

        for nIndex, vExisting in ipairs(tEntries) do

            if (rawequal(vExisting, vEntry)) then
                table.remove(tEntries, nIndex);
                return this, true;
            end

        end

        return this, false;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.clear
        @pulsarlua function ObjectRegistry.clear
        @desc Clears entries, retaining prerequisite settings. An empty registry denies all objects.
        @ret ObjectRegistry this This registry.
    !]]
    clear = function(this, cdat)
        cdat.pri.entries = {};
        return this;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.contains
        @pulsarlua function ObjectRegistry.contains
        @desc Checks exact entry identity, without inheritance matching or invoking prerequisites.
        @param class|CoG vEntry Valid CoG class or instance.
        @ret boolean bFound Whether that exact entry is stored.
    !]]
    contains = function(this, cdat, vEntry)
        validateEntry(vEntry);

        for _, vExisting in ipairs(cdat.pri.entries) do

            if (rawequal(vExisting, vEntry)) then
                return true;
            end

        end

        return false;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.getCount
        @pulsarlua function ObjectRegistry.getCount
        @desc Returns stored entry count.
        @ret number nCount Entry count.
    !]]
    getCount = function(this, cdat)
        return #cdat.pri.entries;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.eachEntry
        @pulsarlua function ObjectRegistry.eachEntry
        @desc Returns an iterator over a copied entry array. Later registry edits do not alter its order.
        @ret function fIterator Yields one-based index and class/instance entry.
    !]]
    eachEntry = function(this, cdat)
        local tEntries = {};

        for nIndex, vEntry in ipairs(cdat.pri.entries) do
            tEntries[nIndex] = vEntry;
        end

        local nIndex = 0;
        return function()
            nIndex = nIndex + 1;

            if (tEntries[nIndex]) then
                return nIndex, tEntries[nIndex];
            end

        end;

    end,

    -- Compatibility with the original class-only registry API.
    --[[!
        @fqxn CoG.ObjectRegistry.Methods.eachClass
        @pulsarlua function ObjectRegistry.eachClass
        @desc Compatibility alias of eachEntry; includes instance entries as well as classes.
        @ret function fIterator Yields one-based index and stored entry.
    !]]
    eachClass = function(this, cdat)
        return this.eachEntry();
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.setPrerequisite
        @pulsarlua function ObjectRegistry.setPrerequisite
        @desc Replaces the eligibility callback. Nil selects the current default dummy. Callback receives (oObject, ...) after entry matching and must return boolean plus optional string reason.
        @param function|nil fPrerequisite Callback or nil to restore the dummy.
        @ret ObjectRegistry this This registry.
    !]]
    setPrerequisite = function(this, cdat, fPrerequisite)
        assert(fPrerequisite == nil or rawtype(fPrerequisite) == "function",
               "Prerequisite must be a function or nil.");
        local pri = cdat.pri;
        pri.prerequisite = fPrerequisite or (pri.defaultPrerequisite and prerequisiteTrue or prerequisiteFalse);
        return this;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.getPrerequisite
        @pulsarlua function ObjectRegistry.getPrerequisite
        @desc Returns the current callback, including the selected default dummy.
        @ret function fPrerequisite Current eligibility function.
    !]]
    getPrerequisite = function(this, cdat)
        return cdat.pri.prerequisite;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.setDefaultPrerequisite
        @pulsarlua function ObjectRegistry.setDefaultPrerequisite
        @desc Changes the dummy result and updates an active dummy immediately; a custom callback remains unchanged.
        @param boolean bDefault Dummy eligibility result.
        @ret ObjectRegistry this This registry.
    !]]
    setDefaultPrerequisite = function(this, cdat, bDefault)
        assert(rawtype(bDefault) == "boolean", "Default prerequisite must be a boolean.");
        local pri = cdat.pri;
        local bDummy = pri.prerequisite == prerequisiteTrue or pri.prerequisite == prerequisiteFalse;
        pri.defaultPrerequisite = bDefault;

        if (bDummy) then
            this.setPrerequisite();
        end

        return this;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.getDefaultPrerequisite
        @pulsarlua function ObjectRegistry.getDefaultPrerequisite
        @desc Returns the selected default dummy result.
        @ret boolean bDefault Default eligibility result.
    !]]
    getDefaultPrerequisite = function(this, cdat)
        return cdat.pri.defaultPrerequisite;
    end,

    --[[!
        @fqxn CoG.ObjectRegistry.Methods.allows
        @desc Class entries use child-or-self checks (isa semantics); instance
        entries use exact identity, ignoring overloaded equality operators.
        A match invokes the prerequisite once, not once per matching entry.
        @pulsarlua function ObjectRegistry.allows
        @param CoG oObject Candidate instance; non-CoG inputs return false and a reason.
        @param varargs ... Extra prerequisite context.
        @ret boolean bAllowed Eligibility result.
        @ret string|nil sReason Optional explanation for denial.
    !]]
    allows = function(this, cdat, oObject, ...)
        local cObject = class.of(oObject);

        if (not class.isinstance(oObject) or not class.ischildorself(cObject, CoG)) then
            return false, "Object must be a CoG instance.";
        end

        local bMatch = false;

        for _, vAllowed in ipairs(cdat.pri.entries) do

            if ((class.is(vAllowed) and class.ischildorself(cObject, vAllowed)) or rawequal(oObject, vAllowed)) then
                bMatch = true;
                break;
            end

        end

        if (not bMatch) then
            return false, "Object does not match a registered entry.";
        end

        local bAllowed, sReason = cdat.pri.prerequisite(oObject, ...);
        assert(rawtype(bAllowed) == "boolean", "Prerequisite must return a boolean.");
        assert(sReason == nil or rawtype(sReason) == "string", "Prerequisite reason must be a string or nil.");
        return bAllowed, not bAllowed and (sReason or "Prerequisite not met.") or nil;
    end,

},
nil,   --extending class
false, --if the class is final
nil    --interface(s)
);

