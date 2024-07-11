return class("MyClass",
{--METAMETHODS

},
{--STATIC PUBLIC
    --MyClass = function(stapub) end,
},
{--PRIVATE

},
{--PROTECTED

},
{--PUBLIC
    MyClass = function(this, cdat)

    end,
},
nil,   --extending class
false, --if the class is final (or (if a table is provided) limited to certain subclasses)
nil    --interface(s) (either nil, or interface(s))
);

--[[
    Use the class system above. Assume all methods have two agruments injected into them (this and cdat)
    this is the object and cdat is the data table with indices, pri, pro, pub and met (references to the class tables so items within the class tables can be accessed within class methods)
    Assume metamethods have 2-3 arguments inejected. Metamethods with fewer than two operand inputs have (this, cdat) while ones with three have (this, other, cdat) where other is the other operand.
    Constructor must be the name of the class (polygon in this case)

    Other assumptions:
    line and point classes already exist and contain (or will contain) all methods your require for the polygon class and their private properties (e.g., x, y, length. etc.) are accesssed through public methods such oMyPoint.GetX() or oMyLine.getLength() (do not use : for access, just . as this class system auto-injects the class object [this] in all methods)

    instructions:
    use camelCase

    Make a polygon class with the following features:
    has vertices which are of type point
    has lines between the vertices
    has a bounding box based on the vertices and a centroid in the middle of the box (this is used for positioning)
    Anchor points (for moving the polygon) can be any of the four bounding box vertices or its centroid (but is defaulted to the centroid)
    can make calculations such as area, circumference, etc.
    can make determinations about itself such as whether it's concave, convex, complex, regular. irregualr, etc.
    can interact with other polygons for methods such intersects(oOtherPolygon)
    knows the interior and exterior angles of all vertices (except the bounding box as those are all 90 degrees)
    can do things such as setVertex(SHAPE_ANCHOR_TOP_LEFT) for example, setPos(oPointForAnchor), translate, etc.

    The polygon keeps all items (such as lines, vertices, angles, etc.) updated whenever anything relevant changes.


    has these constants available
    local QUADRANT_I         = QUADRANT_I;
    local QUADRANT_II         = QUADRANT_II
    local QUADRANT_III        = QUADRANT_III;
    local QUADRANT_IV         = QUADRANT_IV;
    local QUADRANT_O        = QUADRANT_O;
    local QUADRANT_X        = QUADRANT_X;
    local QUADRANT_X_NEG     = QUADRANT_X_NEG;
    local QUADRANT_Y        = QUADRANT_Y;
    local QUADRANT_Y_NEG    = QUADRANT_Y_NEG;
    local SHAPE_ANCHOR_COUNT        = SHAPE_ANCHOR_COUNT;
    local SHAPE_ANCHOR_TOP_LEFT     = SHAPE_ANCHOR_TOP_LEFT;
    local SHAPE_ANCHOR_TOP_RIGHT     = SHAPE_ANCHOR_TOP_RIGHT;
    local SHAPE_ANCHOR_BOTTOM_RIGHT = SHAPE_ANCHOR_BOTTOM_RIGHT;
    local SHAPE_ANCHOR_BOTTOM_LEFT     = SHAPE_ANCHOR_BOTTOM_LEFT;
    local SHAPE_ANCHOR_CENTROID        = SHAPE_ANCHOR_CENTROID;
    local SHAPE_ANCHOR_DEFAULT        = SHAPE_ANCHOR_DEFAULT;
    local SIDE_TRIANGLE_DIFFERENTIAL         = 3;
    local SIDE_ANGLE_FACTOR_DIFFERENTIAL    = 2;
    local SUM_OF_EXTERIOR_ANGLES            = 360;
]]
