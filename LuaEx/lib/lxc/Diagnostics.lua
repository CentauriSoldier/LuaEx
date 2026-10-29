--[[!
@fqxn LuaEx.LXC.Diagnostics
@desc <h3>Diagnostics — responsibility and connections</h3><p>Adds declaration filenames, lines and qualified
    names to failures. Parser provides token-level grammar locations; Model, Compiler and Runtime wrap
    validation, compilation, initialization and construction with these helpers. Existing LXC error context is
    preserved when a failure crosses several service layers.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]

local Diagnostics = {};


--[[!
@fqxn LuaEx.LXC.Diagnostics.format
@desc Formats LXC [ file:line qualified.name ] message from a class/member definition. Already contextualized
    LXC errors pass through unchanged so outer wrappers preserve the original location.
@param table tDefinition Class/member definition supplying name and source location.
@param any vError Original error value to contextualize.
@ret string sMessage Contextualized diagnostic.
@vis internal
!]]
function Diagnostics.format(tDefinition, vError)
    local sMessage = tostring(vError);
    if (string.match(sMessage, '^LXC %[ ')) then return sMessage; end

    local tClass = tDefinition.Owner or tDefinition;
    local sName = tClass.FullName..(tDefinition.Owner and '.'..tDefinition.Name or '');
    return 'LXC [ '..tClass.File..':'..(tDefinition.Line or tClass.Line or 1)..' '..sName..' ] '..sMessage;
end


--[[!
@fqxn LuaEx.LXC.Diagnostics.run
@desc Calls an operation with pcall and rethrows failures with declaration context. Packing preserves nil values
    and the exact number of successful results.
@param table tDefinition Class/member definition supplying name and source location.
@param function fOperation Operation invoked with declaration-aware error handling.
@param any ... Additional arguments forwarded in order.
@ret any ... All successful results in order.
@vis internal
!]]
function Diagnostics.run(tDefinition, fOperation, ...)
    local tResults = table.pack(pcall(fOperation, ...));
    if (not tResults[1]) then error(Diagnostics.format(tDefinition, tResults[2]), 0); end
    return table.unpack(tResults, 2, tResults.n);
end

return Diagnostics;
