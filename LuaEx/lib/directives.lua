--[[!
@fqxn LuaEx.Directives
@desc Composes shared source annotation, target validation and declaration selection
    services. LXC and LXE explicitly supply their own declaration semantics.
!]]
return {
    Parser = require("LuaEx.lib.directives.Parser");
    Registry = require("LuaEx.lib.directives.Registry");
    Diagnostics = require("LuaEx.lib.directives.Diagnostics");
    Selection = require("LuaEx.lib.directives.Selection");
};
