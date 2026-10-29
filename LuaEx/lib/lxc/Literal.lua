--[[!
@fqxn LuaEx.LXC.Literal
@desc <h3>Literal — responsibility and connections</h3><p>Writes and reads the restricted table-literal
    representation of standalone snapshots. Persistence supplies acyclic descriptor records, even when the
    represented application graph has cycles. Tokens scans strings safely; SnapshotSchema validates decoded
    structure. Decoding reads a data grammar rather than evaluating the whole input as Lua code.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

--[[!
@fqxn LuaEx.LXC.Literal.factory
@desc Creates this private service with explicit dependencies. Loader owns composition order; application code
    uses the public LXC facade.
@param table Tokens Private injected dependency; its role is described in the module map.
@ret table Service returned by this module.
@vis internal
!]]
return function(Tokens)
    local Literal = {};

    
    --[[!
    @fqxn LuaEx.LXC.Literal.encode
    @desc Writes internal descriptor records as explicit [key]=value literals, quoting strings with %q. Pass the
        acyclic records from Persistence, not a cyclic application graph.
    @param any vValue Value to inspect, assign, copy or serialize.
    @ret string sSource Restricted literal text.
    @vis internal
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
    @fqxn LuaEx.LXC.Literal.decode
    @desc Reads explicit table entries, strings, booleans and numbers; requires commas and rejects duplicate/nil
        keys and trailing code. Limits text to 16 MiB and nested depth below 256. Never evaluates the entire
        input chunk.
    @param string sSource Source text; the operation description specifies whether this is LXC, Lua or snapshot
        data.
    @ret any vValue Literal data before schema validation.
    @vis internal
    !]]
    function Literal.decode(sSource)
        assert(type(sSource) == 'string' and #sSource <= 16 * 1024 * 1024, 'Invalid snapshot text.');
        local tTokens, nIndex = Tokens.scan(sSource, 'LXC snapshot'), 1;
        local fRead;

        --[[!
        @fqxn LuaEx.LXC.Literal.decode.read
        @desc Consumes one scalar or nested table. Only individual string tokens are evaluated in an empty
            environment to interpret escapes; numeric text uses tonumber.
        @param number nDepth Current recursive literal depth for the decoder limit.
        @ret any vValue Decoded value.
        @vis internal
        !]]
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
