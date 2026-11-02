--[[!
@fqxn LuaEx.Directives.Diagnostics
@desc Produces source-located directive errors without executing application code.
!]]
local Diagnostics = {};
local _error = error;

--[[!
@fqxn LuaEx.Directives.Diagnostics.fail
@desc Raises a diagnostic at the annotation or declaration that caused it.
@param table tSource Source record containing File and Line.
@param string sMessage Explanation of the invalid declaration.
!]]
function Diagnostics.fail(tSource, sMessage)
    _error(tSource.File..":"..tSource.Line..": "..sMessage, 0);
end

return Diagnostics;
