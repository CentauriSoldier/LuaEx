local tCases = {
    { name = "point", factory = point, object = point(2, 3), mutate = function(o) o.x = 9; end },
    { name = "line", factory = line, object = line(0, 0, 3, 4), mutate = function(o) o.start.x = 2; end },
    { name = "circle", factory = circle, object = circle(1, 2, 3), mutate = function(o) o.center.x = 9; end },
    { name = "circlearc", factory = circlearc, object = circlearc(1, 2, 3, 0, math.pi), mutate = function(o) o.center.x = 9; end },
    { name = "ellipse", factory = ellipse, object = ellipse(1, 2, 6, 4), mutate = function(o) o.center.x = 9; end },
    { name = "polygon", factory = polygon, object = polygon(0, 0, 4, 0, 0, 3), mutate = function(o) o.anchor.x = o.anchor.x + 5; end },
};

for _, tCase in ipairs(tCases) do
    local oSource = tCase.object;

    if (tCase.name ~= "point") then
        oSource.autoUpdate = false;
    end

    if (tCase.name == "polygon") then
        oSource.anchorIndex = 1;
    end

    local sBefore = serialize(oSource);
    local oCopy = clone(oSource);
    assert(not rawequal(oSource, oCopy));
    assert(type(oCopy) == "primitive" and subtype(oCopy) == subtype(oSource));
    assert(serialize(oCopy) == sBefore);
    tCase.mutate(oCopy);
    assert(serialize(oSource) == sBefore);
    assert(serialize(oCopy) ~= sBefore);

    local oRestored = deserialize(sBefore);
    assert(not rawequal(oSource, oRestored));
    assert(serialize(oRestored) == sBefore);
    assert(rawequal(clone(tCase.factory), tCase.factory));
    assert(rawequal(deserialize(serialize(tCase.factory)), tCase.factory));
    assert(not pcall(tCase.factory.deserialize, {}));
end

-- Current defining inputs survive dirty caches; restored measurements are derived anew.
local oCircle = circle(0, 0, 2);
oCircle.autoUpdate = false;
oCircle.radius = 4;
local oRestored = deserialize(serialize(oCircle));
assert(oRestored.radius == 4 and not oRestored.autoUpdate);
assert(math.abs(oRestored.area - math.pi * 16) < 1e-10);
assert(not pcall(circle.deserialize, { centerX = 0, centerY = 0, radius = -1, autoUpdate = true }));
assert(not pcall(point.deserialize, { x = math.huge, y = 0 }));
assert(not pcall(point.deserialize, { x = 0, y = 0, extra = true }));
local oPolygon = polygon(0, 0, 4, 0, 0, 3);
oPolygon.anchorIndex = 2;
local oPolygonCopy = clone(oPolygon);
assert(oPolygonCopy.anchorIndex == 2);
local tGraph = { first = oCircle, second = oCircle };
local tRestored = deserialize(serialize(tGraph));
assert(rawequal(tRestored.first, tRestored.second));
print("PASS primitives: independent clones, all six round trips, factory identity, dirty geometry, anchors, shared graph references and invalid state");
