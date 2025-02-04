--TODO sort and label sections of this file this properly

--[[The anchor point of a shape
    is the point that is used
    when setting or getting
    the position of the shape.
    Note: the anchor point may
    or may not lie outside the
    bounds of the shape.]]
constant("SHAPE_ANCHOR_COUNT",	 		 5); --DO NOT CHANGE THIS VALUE
constant("SHAPE_ANCHOR_TOP_LEFT", 		-5); --DO NOT CHANGE THIS VALUE
constant("SHAPE_ANCHOR_TOP_RIGHT", 		-4); --DO NOT CHANGE THIS VALUE
constant("SHAPE_ANCHOR_BOTTOM_RIGHT", 	-3); --DO NOT CHANGE THIS VALUE
constant("SHAPE_ANCHOR_BOTTOM_LEFT", 	-2); --DO NOT CHANGE THIS VALUE
constant("SHAPE_ANCHOR_CENTROID",	 	-1); --DO NOT CHANGE THIS VALUE
--constant("SHAPE_ANCHOR_VERTEX",	 		-1); --DO NOT CHANGE THIS VALUE
--[[For any shape that DOES NOT
    define it's own anchor point,
    this will be the default anchor
    point for that shape. Keep in
    mind, that some shapes do define
    their own anchor point and, in
    that case, this default will
    not	be used.]]
constant("SHAPE_ANCHOR_DEFAULT",		SHAPE_ANCHOR_CENTROID);

constant("VISIBILITY_PRIVATE",      "private");
constant("VISIBILITY_PROTECTED",    "protected");
constant("VISIBILITY_PUBLIC",       "public");
