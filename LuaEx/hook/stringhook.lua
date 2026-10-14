local tLuaEX = rawget(_G, "luaex");

local math      = math;
local pairs     = pairs;
local ipairs    = ipairs;
local rawtype   = rawtype;
local string    = string;
local table     = table;

-- Public patterns use a decoy table because this hook loads before table.readonly.
--[[!
    @fqxn LuaEx.Lua Hooks.string.patterns
    @desc Read-only lookup of nonblank and UUID-shape Lua patterns. Unknown names return nil.
    Ordinary assignments are rejected; rawset has Lua's usual ability to bypass a metatable.
!]]
local tPatterns = {
    nonblank = "%S+",
    uuid = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$",
};

local tPatternsDecoy = {};
local tPatternsMeta = {
    __index = tPatterns,
    __newindex = function()

        error("String patterns cannot be assigned directly.", 2);
    end,
    __pairs = function()

        return pairs(tPatterns);
    end,
    __metatable = false,
};
setmetatable(tPatternsDecoy, tPatternsMeta);
string.patterns = tPatternsDecoy;

--UUID values
local _tCharsLower	 = {"7","f","1","e","3","c","6","b","5","9","a","4","8","d","0","2"};
local _tCharsUpper	 = {"7","F","1","E","3","C","6","B","5","9","A","4","8","D","0","2"};
local _sUUIDLength 	 = #_tCharsLower;
local _tUUIDSequence = {8, 4, 4, 4, 12};
local _sUUIDBlocks	 = #_tUUIDSequence;

local _bOSIsWindows  = package.config:sub(1, 1) == "\\";


-- Exact-tag replacement data used by the single-pass HTML formatting helper.
local tHTMLReplacements = {
    ["<b>"] = "**",
    ["</b>"] = "**",
    ["<strong>"] = "**",
    ["</strong>"] = "**",
    ["<h1>"] = "# ",
    ["</h1>"] = "\n",
    ["<h2>"] = "## ",
    ["</h2>"] = "\n",
    ["<h3>"] = "### ",
    ["</h3>"] = "\n",
    ["<h4>"] = "#### ",
    ["</h4>"] = "\n",
    ["<h5>"] = "##### ",
    ["</h5>"] = "\n",
    ["<h6>"] = "###### ",
    ["</h6>"] = "\n",
    ["<i>"] = "*",
    ["</i>"] = "*",
    ["<em>"] = "*",
    ["</em>"] = "*",
    ["<u>"] = "_",
    ["</u>"] = "_",
    ["<br>"] = "  \n",
    ["<br/>"] = "  \n",
    ["<p>"] = "\n\n",
    ["</p>"] = "\n\n",
    ["<blockquote>"] = "> ",
    ["</blockquote>"] = "\n",
    ["<code>"] = "`",
    ["</code>"] = "`",
    ["<pre>"] = "```\n",
    ["</pre>"] = "\n```",
    ["<ul>"] = "\n",
    ["</ul>"] = "\n",
    ["<ol>"] = "\n",
    ["</ol>"] = "\n",
    ["<li>"] = "- ",
    ["</li>"] = "\n",
    ["<hr>"] = "\n---\n",
    ["<hr/>"] = "\n---\n",
};


--[[!
    @fqxn LuaEx.Lua Hooks.string.Helpers.isReservedFilename
    @desc Checks Windows device basenames, ignoring extensions and recognizing superscript device
    digits.
    @param string sName Single filename component.
    @ret boolean bReserved Whether the basename is reserved.
    @scope local
!]]
local function isReservedFilename(sName)

    -- Extensions do not make a reserved device basename available for files.
    local sBase = sName:match("^([^%.]+)") or sName;
    sBase = sBase:gsub(" +$", ""):upper();
    local tReserved = { CON = true, PRN = true, AUX = true, NUL = true };

    if (tReserved[sBase]) then
        return true;
    end

    if (sBase:match("^COM[1-9]$") or sBase:match("^LPT[1-9]$")) then
        return true;
    end

    -- Windows also recognizes ISO superscript digits in COM/LPT device names.
    for _, sDigit in ipairs({ "¹", "²", "³" }) do
        if (sBase == "COM"..sDigit or sBase == "LPT"..sDigit) then
            return true;
        end
    end

    return false;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.cap
    @pulsarlua function string.cap
    @desc Uppercases the first byte, optionally lowercasing the remainder. Empty input returns
    empty. Uses Lua byte/locale casing, not Unicode title casing.
    @param string sInput Text to capitalize.
    @param boolean|nil bLowerRemaining Whether to lowercase remaining text.
    @ret string sRet Capitalized text.
!]]
function string.cap(sInput, bLowerRemaining)

    assert(rawtype(sInput) == "string", "Input must be a string.");
    -- Step 1: uppercase the first byte; an empty string remains empty.
    local sFirst = sInput:sub(1, 1):upper();
    local sRemaining = sInput:sub(2);

    -- Step 2: lower the remaining text only when requested.
    if (bLowerRemaining) then
        sRemaining = sRemaining:lower();
    end

    return sFirst..sRemaining;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.capall
    @pulsarlua function string.capall
    @desc Capitalizes each nonempty literal-delimited item in order, rejoining with the same
    delimiter. Whitespace-only input returns empty text, zero and an empty table. Empty fields are
    omitted; the item list retains original text.
    @param string sInput Input text.
    @param string|nil sDelimiter Literal delimiter; defaults to a space.
    @ret string sRet Capitalized text.
    @ret number nItems Number of nonempty items.
    @ret table tItems Original ordered item strings.
!]]
function string.capall(sInput, sDelimiter)

    assert(rawtype(sInput) == "string", "Input must be a string.");
    sDelimiter = rawtype(sDelimiter) == "string" and sDelimiter ~= "" and sDelimiter or " ";
    local tItems = {};
    local tCapitalized = {};

    -- Step 1: whitespace-only input has a consistent empty result contract.
    if (sInput:find("%S")) then
        tItems = string.totable(sInput, sDelimiter);

        -- Step 2: preserve input order and keep original items in the returned list.
        for nIndex, sWord in ipairs(tItems) do
            tCapitalized[nIndex] = string.cap(sWord);
        end
    end

    -- Step 3: join with the supplied literal delimiter, not a hardcoded space.
    return table.concat(tCapitalized, sDelimiter), #tItems, tItems;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.collapse
    @pulsarlua function string.collapse
    @desc Removes all Lua whitespace runs from text.
    @param string sInput Input text.
    @ret string sRet Text with whitespace removed.
    @ret number nRemoved Number of whitespace runs removed.
!]]
function string.collapse(sInput)

    assert(rawtype(sInput) == "string", "Input must be a string.");
    -- Remove whitespace runs; gsub also returns the number of replacements.
    return sInput:gsub("%s+", '');
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.htmltomd
    @pulsarlua function string.htmltomd
    @desc Converts supported exact lowercase HTML tags to Markdown in a single pass. A preceding
    backslash keeps a tag literal and removes that escape. Other tags/attributes and HTML entities
    remain unchanged. This is a formatting helper, not a parser or sanitizer.
    @param string sText Text containing supported tags.
    @ret string sRet Converted text.
!]]
function string.htmltomd(sText)

    assert(rawtype(sText) == "string", "Input must be a string.");

    -- Convert supported exact tags in one pass. Escaped tags are literal text.
    -- Avoid temporary marker bytes that can collide with existing input data.
    local sRet = sText:gsub("(\\?)(<[^>]->)", function(sEscape, sTag)

        if (sEscape == "\\") then
            return sTag;
        end

        -- Unknown tags/attributes/casing remain unchanged; this is not an HTML parser.
        return tHTMLReplacements[sTag] or sTag;
    end);

    return sRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isdatevalid
    @pulsarlua function string.isdatevalid
    @desc Checks an exact YYYY-MM-DD date using Gregorian leap-year rules. Returns a boolean for all
    inputs. Four-digit year zero is accepted; no alternative format is implemented.
    @param any sInput Candidate date.
    @ret boolean bValid Valid calendar date.
!]]
function string.isdatevalid(sInput)

    -- Step 1: require an exact YYYY-MM-DD representation.
    if (rawtype(sInput) ~= "string") then
        return false;
    end

    local sYear, sMonth, sDay = sInput:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$");

    if (not sYear) then
        return false;
    end

    -- Step 2: reject out-of-range month/day before indexing the calendar.
    local nYear = tonumber(sYear);
    local nMonth = tonumber(sMonth);
    local nDay = tonumber(sDay);

    if (nMonth < 1 or nMonth > 12 or nDay < 1) then
        return false;
    end

    local tDays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

    -- Step 3: apply the Gregorian century and 400-year leap rules.
    if (nYear % 4 == 0 and (nYear % 100 ~= 0 or nYear % 400 == 0)) then
        tDays[2] = 29;
    end

    return nDay <= tDays[nMonth];
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isempty
    @pulsarlua function string.isempty
    @desc Reports whether a string contains no non-whitespace characters. Non-string values return
    false.
    @param any sInput Candidate text.
    @ret boolean bEmpty Whether the string is blank.
!]]
function string.isempty(sInput)
    -- Predicates return false for non-string values.
    return rawtype(sInput) == "string" and sInput:find("%S") == nil;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isfilesafe
    @pulsarlua function string.isfilesafe
    @desc Checks a single filename component for the current platform using a conservative 255-byte
    limit. Rejects empty, dot/dot-dot and control-containing names. Windows also rejects device
    basenames with extensions and trailing dots/spaces. Does not verify filesystem availability or
    total path length.
    @param any sName Candidate filename, not a path.
    @ret boolean bSafe Whether the component meets these naming rules.
!]]
function string.isfilesafe(sName)

    -- Step 1: check a single nonempty component, with a conservative byte limit.
    if (rawtype(sName) ~= "string" or sName == "" or #sName > 255
        or sName == "." or sName == "..") then
        return false;
    end

    local sInvalid = _bOSIsWindows and '[<>:"/\\|?*%c]' or '[/%c]';

    if (sName:find(sInvalid)) then
        return false;
    end

    -- Step 2: apply Windows component rules in addition to forbidden characters.
    if (_bOSIsWindows) then
        if (sName:find("[%. ]$") or isReservedFilename(sName)) then
            return false;
        end
    end

    return true;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.iskeyword
    @pulsarlua function string.iskeyword
    @desc Checks exact case-sensitive membership in the initialized LuaEx keyword list.
    @param any sInput Candidate keyword.
    @ret boolean bKeyword Whether the value matches a keyword.
!]]
function string.iskeyword(sInput)
    -- Membership is case-sensitive, matching LuaEx identifier rules.
    local bRet = false;

    for x = 1, tLuaEX.__keywords__count__ do

        if sInput == tLuaEX.__keywords__[x] then
            bRet = true;
            break;
        end

    end

    return bRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isnumeric
    @pulsarlua function string.isnumeric
    @desc Uses tonumber to recognize Lua numeric syntax, including signed, exponent and hexadecimal
    forms. Rejects blank input and repeated decimal points. This checks syntax, not finiteness of
    the parsed number.
    @param any sInput Candidate numeric string.
    @ret boolean bNumeric Whether Lua can parse the string as a number.
!]]
function string.isnumeric(sInput)
    -- Use Lua's numeric parser rather than accepting arbitrary dots/digits.
    return rawtype(sInput) == "string" and tonumber(sInput) ~= nil;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isuuid
    @pulsarlua function string.isuuid
    @desc Checks hexadecimal 8-4-4-4-12 UUID shape, in either case. Does not enforce version/variant
    bits. Non-string input returns false.
    @param any sInput Candidate identifier.
    @ret boolean bUUID Whether the UUID shape matches.
!]]
function string.isuuid(sInput)

    -- Check hexadecimal block shape only; version/variant bits are not enforced.
    return rawtype(sInput) == "string" and sInput:match(tPatterns.uuid) ~= nil;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.isvariablecompliant
    @pulsarlua function string.isvariablecompliant
    @desc Checks a Lua-style identifier and, by default, excludes LuaEx keywords. Character classes
    use the Lua locale rather than Unicode identifier rules.
    @param any sInput Candidate identifier.
    @param boolean|nil bSkipKeywordCheck Whether to bypass keyword rejection.
    @ret boolean bCompliant Whether the identifier satisfies the requested policy.
!]]
function string.isvariablecompliant(sInput, bSkipKeywordCheck)

    -- Step 1: require an ASCII-style identifier, including a valid first character.
    if (rawtype(sInput) ~= "string" or not sInput:match("^[%a_][%w_]*$")) then
        return false;
    end

    -- Step 2: reject LuaEx keywords unless the caller explicitly skips that policy.
    return bSkipKeywordCheck and true or not string.iskeyword(sInput);
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.makefilesafe
    @pulsarlua function string.makefilesafe
    @desc Normalizes text into a portable filename component using underscores, a conservative
    255-byte limit and Windows device-name protection. Empty results become underscore. May produce
    collisions; does not create files or guarantee name availability. Valid UTF-8 is not cut
    mid-character when truncating.
    @param string sInput Text to normalize.
    @param boolean|nil bLower Whether to lowercase the result.
    @ret string sRet Normalized filename component.
!]]
function string.makefilesafe(sInput, bLower)

    assert(rawtype(sInput) == "string", "Input must be a string.");

    -- Step 1: trim and replace portable forbidden filename characters.
    local sRet = sInput:match("^%s*(.-)%s*$");
    sRet = sRet:gsub('[\\/:*?"<>|]', "_");
    sRet = sRet:gsub("%c", "");

    -- Step 2: normalize separators while retaining the established underscore policy.
    sRet = sRet:gsub("%s+", "_");
    sRet = sRet:gsub("_+", "_");
    sRet = sRet:gsub("^_+", ""):gsub("_+$", "");

    if (bLower) then
        sRet = sRet:lower();
    end

    -- Step 3: enforce a conservative component length and legal trailing characters.
    local bUTF8 = utf8 and utf8.len(sRet) ~= nil;
    sRet = sRet:sub(1, 255);

    if (bUTF8) then
        -- If truncation cut a multi-byte character, remove its partial bytes.
        while (utf8.len(sRet) == nil) do
            sRet = sRet:sub(1, -2);
        end
    end

    sRet = sRet:gsub("[%. ]+$", "");

    -- Step 4: provide usable output for empty input and reserved device basenames.
    if (sRet == "") then
        sRet = "_";
    elseif (isReservedFilename(sRet)) then
        sRet = ("_"..sRet):sub(1, 255);

        if (bUTF8) then
            while (utf8.len(sRet) == nil) do
                sRet = sRet:sub(1, -2);
            end
        end
    end

    return sRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.tosid
    @pulsarlua function string.tosid
    @desc Converts tostring(input) to lowercase, collapses/trims whitespace and encodes normalized
    bytes as uppercase hex. Stable for the same normalized text; not a hash or a unique object
    identity.
    @param any sInput Value converted to text.
    @ret string sID Normalized byte-encoded identifier.
!]]
function string.tosid(sInput)

    -- Step 1: normalize text spelling and whitespace before generating a stable byte ID.
    sInput = tostring(sInput)
        :lower()
        :gsub("%s+", " ")
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    -- Step 2: encode normalized bytes as uppercase hex; this is not a hash.
    return (sInput:gsub(".", function(c)
        return string.format("%02X", string.byte(c))
    end))
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.totable
    @pulsarlua function string.totable
    @desc Splits on a literal delimiter, supporting multiple bytes and pattern punctuation. Defaults
    to comma. Optional callback transforms retained items; returning nil omits an item. Callback
    exceptions propagate. Empty input yields one empty item only when bAllowBlank is truthy.
    @param string sInput Text to split.
    @param string|nil sDelimiter Nonempty literal delimiter, default comma.
    @param boolean|nil bAllowBlank Whether to retain leading/repeated/trailing empty fields.
    @param function|nil fCallback Optional item transformer.
    @ret table tRet Dense ordered result list.
!]]
function string.totable(sInput, sDelimiter, bAllowBlank, fCallback)

    assert(rawtype(sInput) == "string", "Input must be a string.");
    local tRet = {};
    sDelimiter = rawtype(sDelimiter) == "string" and sDelimiter ~= "" and sDelimiter or ",";
    fCallback = rawtype(fCallback) == "function" and fCallback or false;

    --[[!
        @fqxn LuaEx.Lua Hooks.string.Helpers.pushSplitItem
        @desc Applies the blank-item policy and optional callback, appending non-nil results.
        @param string sItem Extracted field from the split input.
        @scope local
    !]]
    local function push(sItem)

        -- Skip empty items before invoking the callback, unless explicitly requested.
        if (sItem ~= "" or bAllowBlank) then
            local vItem = sItem;

            if (fCallback) then
                vItem = fCallback(sItem);
            end

            -- A callback returning nil omits that item without creating a list hole.
            if (vItem ~= nil) then
                tRet[#tRet + 1] = vItem;
            end
        end
    end

    -- Use literal find: delimiters can contain Lua pattern characters or multiple bytes.
    local nStart = 1;

    while (true) do
        local nFirst, nLast = sInput:find(sDelimiter, nStart, true);

        if (not nFirst) then
            push(sInput:sub(nStart));
            break;
        end

        push(sInput:sub(nStart, nFirst - 1));
        nStart = nLast + 1;
    end

    return tRet;
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.trim
    @pulsarlua function string.trim
    @desc Removes leading and trailing Lua whitespace. Empty/whitespace-only input returns empty.
    @param string sInput Text to trim.
    @ret string sRet Trimmed text.
!]]
function string.trim(sInput)
    assert(rawtype(sInput) == "string", "Input must be a string.");
    -- Capture between leading/trailing whitespace; empty input returns an empty string.
    return sInput:match("^%s*(.-)%s*$");
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.trimleft
    @pulsarlua function string.trimleft
    @desc Removes leading Lua whitespace, preserving trailing content.
    @param string sInput Text to trim.
    @ret string sRet Left-trimmed text.
!]]
function string.trimleft(sInput)
    assert(rawtype(sInput) == "string", "Input must be a string.");
    -- Preserve trailing content exactly, including whitespace.
    return sInput:match("^%s*(.*)$");
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.trimright
    @pulsarlua function string.trimright
    @desc Removes trailing Lua whitespace, preserving leading content. All-whitespace input returns
    empty rather than nil.
    @param string sInput Text to trim.
    @ret string sRet Right-trimmed text.
!]]
function string.trimright(sInput)
    assert(rawtype(sInput) == "string", "Input must be a string.");
    -- An optional non-whitespace capture is not needed; all-blank strings return empty.
    return sInput:match("^(.-)%s*$");
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.uuid
    @pulsarlua function string.uuid
    @desc Generates a random hexadecimal 8-4-4-4-12 identifier using math.random. Does not enforce
    UUID version/variant bits and is not a cryptographic generator. Host controls RNG seeding.
    @param boolean|nil bUppercase Whether hexadecimal letters are uppercase.
    @ret string sUUID Generated identifier.
!]]
function string.uuid(bUppercase)
    local sRet 			= "";
    local tChars = bUppercase and _tCharsUpper or _tCharsLower;

    -- Block order must be deterministic even though character selection is random.
    for nBlock, nBlockCharCount in ipairs(_tUUIDSequence) do
        local sDash = nBlock < _sUUIDBlocks and "-" or "";

        for x = 1, nBlockCharCount do
            sRet = sRet..tChars[math.random(1, _sUUIDLength)];
        end

        sRet = sRet..sDash;
    end

    return sRet
end


--[[!
    @fqxn LuaEx.Lua Hooks.string.Legacy.stringtotableOLD
    @desc Legacy global alias for string.totable. Supports the corrected literal splitter.
    @param string sInput Text to split.
    @param string|nil sDelimiter Literal delimiter, default comma.
    @param boolean|nil bAllowBlank Whether empty items are retained.
    @param function|nil fCallback Optional item transformer.
    @ret table tRet Ordered result list.
!]]
function stringtotableOLD(sInput, sDelimiter, bAllowBlank, fCallback)

    -- Retain the legacy global entry point while sharing the corrected literal splitter.
    return string.totable(sInput, sDelimiter, bAllowBlank, fCallback);
end


return string;
