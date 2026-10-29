--[[!
@fqxn LXC.Tokens
@desc Declaration lexer. Preserves byte positions and treats Lua strings/comments
    as opaque tokens. No source is executed here.
!]]
local Tokens = {};

--[[!
@fqxn LXC.Tokens.scan
@param string sSource Source text.
@param string pFile Diagnostic filename.
@ret table Ordered {Text, Start, Stop, Line} tokens, ending with <eof>.
!]]
function Tokens.scan(sSource, pFile)
    local tTokens, nPosition, nLine = {}, 1, 1;

    --[[!
    @fqxn LXC.Tokens.scan.longEnd
    @desc Finds a matching Lua long-bracket delimiter, including its equals count.
    @ret number|nil First byte after the delimiter, or nil when not a long literal.
    !]]
    local function fLong(nStart)
        local sEquals = string.match(sSource, '^%[(=*)%[', nStart);
        if (not sEquals) then return; end
        local nEnd = string.find(sSource, ']'..sEquals..']', nStart + #sEquals + 2, true);
        assert(nEnd, pFile..':'..nLine..': Unterminated long string/comment.');
        return nEnd + #sEquals + 2;
    end

    while (nPosition <= #sSource) do
        local nStart, nStartLine = nPosition, nLine;
        local sChar = string.sub(sSource, nPosition, nPosition);
        local bEmit, sKind = true, nil;

        if (string.match(sChar, '%s')) then
            local _, nStop = string.find(sSource, '^%s+', nPosition);
            nPosition, bEmit = nStop + 1, false;
        elseif (string.sub(sSource, nPosition, nPosition + 1) == '--') then
            nPosition = fLong(nPosition + 2) or string.find(sSource, '\n', nPosition + 2, true) or (#sSource + 1);
            bEmit = false;
        elseif (sChar == '"' or sChar == "'") then
            sKind = 'string';
            nPosition = nPosition + 1;
            while (nPosition <= #sSource and string.sub(sSource, nPosition, nPosition) ~= sChar) do
                nPosition = nPosition + (string.sub(sSource, nPosition, nPosition) == '\\' and 2 or 1);
            end
            assert(nPosition <= #sSource, pFile..':'..nLine..': Unterminated string.');
            nPosition = nPosition + 1;
        else
            -- Match at the current offset rather than allocating a copy of the
            -- entire remaining source for every token. Large saves stay linear.
            local _, nWordStop = string.find(sSource, '^[%a_][%w_]*', nPosition);
            local bDots = string.sub(sSource, nPosition, nPosition + 2) == '...';
            local nLong = sChar == '[' and fLong(nPosition);
            local sPair = string.sub(sSource, nPosition, nPosition + 1);
            local bPair = sPair == '..' or sPair == '//' or sPair == '<<' or sPair == '>>' or
                sPair == '==' or sPair == '~=' or sPair == '<=' or sPair == '>=' or sPair == '::';
            if (nLong) then nPosition, sKind = nLong, 'string';
            elseif (string.match(sChar, '%d') or (sChar == '.' and string.match(string.sub(sSource, nPosition + 1, nPosition + 1), '%d'))) then
                sKind = 'number';
                nPosition = nPosition + 1;
                while (nPosition <= #sSource) do
                    local sNext = string.sub(sSource, nPosition, nPosition);
                    local sPrevious = string.sub(sSource, nPosition - 1, nPosition - 1);
                    if (string.match(sNext, '[%da-fA-FxXpP%.]') or
                        ((sNext == '+' or sNext == '-') and string.match(sPrevious, '[eEpP]'))) then
                        nPosition = nPosition + 1;
                    else break; end
                end
            else
                nPosition = (nWordStop and nWordStop + 1) or (nPosition + (bDots and 3 or (bPair and 2 or 1)));
            end
        end

        if (bEmit) then
            tTokens[#tTokens + 1] = {Text = string.sub(sSource, nStart, nPosition - 1),
                Start = nStart, Stop = nPosition - 1, Line = nStartLine, Kind = sKind};
        end
        local _, nNewLines = string.gsub(string.sub(sSource, nStart, nPosition - 1), '\n', '');
        nLine = nLine + nNewLines;
    end

    tTokens[#tTokens + 1] = {Text = '<eof>', Start = #sSource + 1, Stop = #sSource + 1, Line = nLine};
    return tTokens;
end

return Tokens;
