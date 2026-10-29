--[[!
@fqxn LXC.Literal
@desc Restricted snapshot wire syntax. Encodes plain schema records and parses
    only tables, primitive literals and explicit keys. It never executes a saved
    program. Lua's loader is used solely to decode an already-tokenized quoted
    string literal in an empty environment. Graph validation belongs to Schema.
!]]
return function(Tokens)
    local Literal = {};

    --[[!
    @fqxn LXC.Literal.encode
    @param any vValue Internal schema value; not an application object graph.
    @ret string Text containing only the supported literal grammar.
    !]]
    function Literal.encode(vValue)
        if (type(vValue) == 'table') then
            local tParts = {'{'};
            for k, v in pairs(vValue) do
                tParts[#tParts + 1] = '['..Literal.encode(k)..']='..Literal.encode(v)..',';
            end
            tParts[#tParts + 1] = '}';
            return table.concat(tParts);
        end
        if (type(vValue) == 'string') then return string.format('%q', vValue); end
        return tostring(vValue);
    end

    --[[!
    @fqxn LXC.Literal.decode
    @param string sSource Snapshot text, at most 16 MiB and 255 nested literals.
    @ret any Parsed schema data, still requiring SnapshotSchema validation.
    @desc Rejects duplicate entries, executable expressions and trailing source.
    !]]
    function Literal.decode(sSource)
        assert(type(sSource) == 'string' and #sSource <= 16 * 1024 * 1024, 'Invalid snapshot text.');
        local tTokens, nIndex = Tokens.scan(sSource, 'LXC snapshot'), 1;
        local fRead;

        fRead = function(nDepth)
            assert(nDepth < 256, 'Snapshot nesting limit exceeded.');
            local tToken = tTokens[nIndex];
            local sToken = tToken.Text;
            nIndex = nIndex + 1;

            if (sToken == '{') then
                local tResult = {};
                while (tTokens[nIndex].Text ~= '}') do
                    assert(tTokens[nIndex].Text == '[', 'Invalid snapshot key.');
                    nIndex = nIndex + 1;
                    local k = fRead(nDepth + 1);
                    assert(tTokens[nIndex].Text == ']' and tTokens[nIndex + 1].Text == '=', 'Invalid snapshot entry.');
                    nIndex = nIndex + 2;
                    local v = fRead(nDepth + 1);
                    assert(k ~= nil and v ~= nil and tResult[k] == nil, 'Invalid/duplicate snapshot entry.');
                    tResult[k] = v;
                    assert(tTokens[nIndex].Text == ',', 'Missing snapshot comma.');
                    nIndex = nIndex + 1;
                end
                nIndex = nIndex + 1;
                return tResult;
            end

            if (sToken == 'true') then return true; end
            if (sToken == 'false') then return false; end
            if (tToken.Kind == 'string') then
                return assert(load('return '..sToken, 'LXC string literal', 't', {}))();
            end
            if (sToken == '-') then
                sToken = '-'..tTokens[nIndex].Text;
                nIndex = nIndex + 1;
            end
            return assert(tonumber(sToken), 'Invalid snapshot literal.');
        end;

        local vResult = fRead(0);
        assert(tTokens[nIndex].Text == '<eof>', 'Trailing snapshot code is forbidden.');
        return vResult;
    end

    return Literal;
end;
