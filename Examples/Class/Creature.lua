local cExtendor     = nil;
local vImplements   = nil;
local bIsFinal      = false;

local metamethods   = {};
local static        = {
    count = 0,
};
local private       = {};
local protected     = {
    getHP = function()

    end,
};
local public        = {
    Creature = function(this)

    end,
};



return class(   "Creature",
                metamethods, static,
                private, protected, public,
                cExtendor, vImplements, bIsFinal);
