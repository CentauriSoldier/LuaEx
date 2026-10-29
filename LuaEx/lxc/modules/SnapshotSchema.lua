--[[!
@fqxn LXC.SnapshotSchema
@desc Preflights the literal graph format before allocating any restored object.
    Rejects extra fields, sparse arrays, unknown references and invalid descriptors.
!]]
local Schema = {};

--[[!
@fqxn LXC.SnapshotSchema.record
@desc Rejects undeclared record fields and metatable-bearing schema containers.
!]]
local function record(tValue, tAllowed)
    assert(type(tValue) == 'table' and getmetatable(tValue) == nil, 'Expected plain snapshot record.');
    for sKey in pairs(tValue) do assert(tAllowed[sKey], 'Unknown snapshot record field: '..tostring(sKey)); end
end

local function dense(tList)
    assert(type(tList) == 'table' and getmetatable(tList) == nil, 'Expected snapshot list.');
    local nCount = 0;
    for k in pairs(tList) do
        assert(type(k) == 'number' and k >= 1 and k % 1 == 0, 'Invalid snapshot list key.'); nCount = nCount + 1;
    end
    for n = 1, nCount do assert(tList[n] ~= nil, 'Sparse snapshot list.'); end
    return nCount;
end

--[[!
@fqxn LXC.SnapshotSchema.validate
@param table tGraph Version-one decoded wire records, not application objects.
@desc Validates the entire descriptor graph without following graph cycles.
!]]
function Schema.validate(tGraph, bHost)
    record(tGraph, {Version = true, Root = true, Nodes = true});
    assert(tGraph.Version == 1, 'Invalid snapshot version.');
    local nNodes = dense(tGraph.Nodes);
    assert(nNodes <= 100000, 'Snapshot node limit exceeded.');

    local function fDescriptor(tValue)
        record(tValue, {Null = true, Ref = true, Value = true});
        local nKinds = (tValue.Null ~= nil and 1 or 0) + (tValue.Ref ~= nil and 1 or 0) + (tValue.Value ~= nil and 1 or 0);
        assert(nKinds <= 1, 'Conflicting graph value forms.');
        if (tValue.Null ~= nil) then assert(tValue.Null == true, 'Invalid null descriptor.'); end
        if (tValue.Ref ~= nil) then
            assert(type(tValue.Ref) == 'number' and tValue.Ref % 1 == 0 and tValue.Ref >= 1 and tValue.Ref <= nNodes, 'Invalid graph reference.');
        end
        if (tValue.Value ~= nil) then
            local sType = type(tValue.Value);
            assert(sType == 'string' or sType == 'number' or sType == 'boolean', 'Nonprimitive graph literal.');
            if (sType == 'number' and not bHost) then assert(tValue.Value == tValue.Value and math.abs(tValue.Value) < math.huge, 'Nonfinite snapshot literal.'); end
        end
    end

    fDescriptor(tGraph.Root);
    for _, tNode in ipairs(tGraph.Nodes) do
        if (tNode.Kind == 'table') then
            record(tNode, {Kind = true, Entries = true}); dense(tNode.Entries);
            for _, tEntry in ipairs(tNode.Entries) do assert(dense(tEntry) == 2, 'Invalid saved table pair.'); fDescriptor(tEntry[1]); fDescriptor(tEntry[2]); end
        elseif (tNode.Kind == 'host' and bHost) then
            record(tNode, {Kind = true, Value = true, Captures = true});
            assert(type(tNode.Value) == 'function' or type(tNode.Value) == 'table', 'Invalid host graph value.');
            dense(tNode.Captures);
            for _, tValue in ipairs(tNode.Captures) do fDescriptor(tValue); end
        elseif (tNode.Kind == 'class') then
            record(tNode, {Kind = true, Class = true}); assert(type(tNode.Class) == 'string', 'Invalid saved class name.');
        else
            record(tNode, {Kind = true, Class = true, Fields = true});
            assert(tNode.Kind == 'instance' and type(tNode.Class) == 'string' and type(tNode.Fields) == 'table', 'Invalid instance record.');
            for sKey, tField in pairs(tNode.Fields) do
                assert(type(sKey) == 'string', 'Invalid field key.');
                record(tField, {Value = true, Type = true, ClassType = true, Locked = true});
                assert(tField.Type == nil or type(tField.Type) == 'string', 'Invalid saved field type.');
                assert(type(tField.ClassType) == 'boolean' and type(tField.Locked) == 'boolean', 'Invalid saved field flags.');
                fDescriptor(tField.Value);
            end
        end
    end
end

return Schema;
