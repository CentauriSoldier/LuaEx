--[[!
@fqxn LXC.Diagnostics
@desc Attaches source/declaration context to load and construction errors. Runtime
    method errors keep Lua's native source locations. No application state is read.
!]]
local Diagnostics = {};

--[[!
@fqxn LXC.Diagnostics.format
@param table tDefinition Class or member definition with source metadata.
@param any vError Original Lua error value.
@ret string Source, line and qualified declaration followed by the error.
!]]
function Diagnostics.format(tDefinition, vError)
    local sMessage = tostring(vError);
    if (string.match(sMessage, '^LXC %[ ')) then return sMessage; end

    local tClass = tDefinition.Owner or tDefinition;
    local sName = tClass.FullName..(tDefinition.Owner and '.'..tDefinition.Name or '');
    return 'LXC [ '..tClass.File..':'..(tDefinition.Line or tClass.Line or 1)..' '..sName..' ] '..sMessage;
end

--[[!
@fqxn LXC.Diagnostics.run
@param table tDefinition Declaration used when annotating a failure.
@param function fOperation Trusted load-time operation.
@ret any... Original operation results, preserving nil values and arity.
@desc Rethrows a failure with its innermost declaration's diagnostic context.
!]]
function Diagnostics.run(tDefinition, fOperation, ...)
    local tResults = table.pack(pcall(fOperation, ...));
    if (not tResults[1]) then error(Diagnostics.format(tDefinition, tResults[2]), 0); end
    return table.unpack(tResults, 2, tResults.n);
end

return Diagnostics;
