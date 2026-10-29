--[[!
@fqxn LuaEx.LXC.SnapshotSchema
@desc <h3>SnapshotSchema — responsibility and connections</h3><p>Checks decoded snapshot shape before
    allocation: record keys, dense arrays, descriptor forms, reference IDs and supported version. GraphAccess
    separately checks visibility; Persistence separately checks actual fields, established types and locks.
    Structurally valid data is not automatically valid for the current class definitions.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

local Schema = {};


--[[!
@fqxn LuaEx.LXC.SnapshotSchema.record
@desc Requires plain metadata and rejects unknown keys; callers enforce required fields/types.
@param table tValue One encoded descriptor/metadata record to validate or translate.
@param table tAllowed Set of allowed metadata field names.
@ret nil No return value; raises for malformed records.
@vis internal
!]]
local function record(tValue, tAllowed)
    assert(type(tValue) == 'table' and getmetatable(tValue) == nil, 'Expected plain snapshot record.');
    for sKey in pairs(tValue) do assert(tAllowed[sKey], 'Unknown snapshot record field: '..tostring(sKey)); end
end

--[[!
@fqxn LuaEx.LXC.SnapshotSchema.dense
@desc Checks integer keys starting at one, no holes and no keyed extras before indexed traversal.
@param table tList Candidate dense sequence to validate.
@ret number nCount Exact list length.
@vis internal
!]]
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
@fqxn LuaEx.LXC.SnapshotSchema.validate
@desc Checks version/node limit/dense arrays/descriptor forms and node-specific fields. Host mode permits host
    nodes/nonfinite numeric descriptors; standalone mode restricts data accordingly.
@param table tGraph Decoded Root/Nodes descriptor graph, not live instance state.
@param boolean bHost Whether host nodes and host numeric allowances are enabled.
@ret nil No return value; raises for invalid shape.
@vis internal
!]]
function Schema.validate(tGraph, bHost)
    record(tGraph, {Version = true, Root = true, Nodes = true});
    assert(tGraph.Version == 1, 'Invalid snapshot version.');
    local nNodes = dense(tGraph.Nodes);
    assert(nNodes <= 100000, 'Snapshot node limit exceeded.');

    --[[!
    @fqxn LuaEx.LXC.SnapshotSchema.validate.descriptor
    @desc Checks exclusive Null/Ref/Value forms; a blank record represents nil. Reference IDs must be valid
        integer node indices and literal values supported scalars.
    @param table tValue One encoded descriptor/metadata record to validate or translate.
    @ret nil No return value; validates a descriptor.
    @vis internal
    !]]
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
