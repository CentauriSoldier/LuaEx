--[[!
@fqxn LuaEx.Directives.Registry
@desc Defines supported directive syntax and declaration targets. LXC owns type
    resolution and completion semantics; selection owns default semantics.
!]]
-- Keep runtime string operations independent of application replacements.
local _find, _gmatch, _gsub, _match, _sub = string.find, string.gmatch, string.gsub, string.match, string.sub;


local Diagnostics = require("LuaEx.lib.directives.Diagnostics");
local Registry = {};
local _ipairs = ipairs;
local _tDefinitions = {
    type = {field = true, property = true};
    default = {class = true, enum = true, extension = true};
};

--[[!
@fqxn LuaEx.Directives.Registry.attach
@desc Checks names, arguments, duplicate annotations and supported declaration kinds.
@param table tAnnotations Ordered source-bearing annotation records.
@param table tDeclaration Parsed declaration receiving the metadata.
@param string sKind Declaration kind supplied by the integrating parser.
!]]
function Registry.attach(tAnnotations, tDeclaration, sKind)
    local tSeen = {};
    for _, tAnnotation in _ipairs(tAnnotations or {}) do
        local sName, sValue = tAnnotation.Name, tAnnotation.Value;
        local tDefinition = _tDefinitions[sName];
        if (not tDefinition) then Diagnostics.fail(tAnnotation, "Unknown directive: @"..sName); end
        if (not tDefinition[sKind]) then Diagnostics.fail(tAnnotation, "@"..sName.." does not support "..sKind.." declarations."); end
        if (tSeen[sName]) then Diagnostics.fail(tAnnotation, "Duplicate @"..sName.." directive."); end
        tSeen[sName] = true;
        if (sName == "default") then
            if (sValue ~= "") then Diagnostics.fail(tAnnotation, "@default takes no arguments."); end
            tDeclaration.Default = true;
        else
            local sType = _gsub(sValue, "%?$", "");
            if (not _match(sType, "^[%a_][%w_%.]*$") or _find(sType, "%.%.") or _sub(sType, -1) == "." or sType == "nil") then
                Diagnostics.fail(tAnnotation, "Invalid @type expression: "..sValue);
            end
            for sPart in _gmatch(sType, "[^.]+") do
                if (not _match(sPart, "^[%a_][%w_]*$")) then Diagnostics.fail(tAnnotation, "Invalid @type expression: "..sValue); end
            end
            tDeclaration.TypeAnnotation = {Name = sType, Nullable = _sub(sValue, -1) == "?",
                File = tAnnotation.File, Line = tAnnotation.Line};
        end
    end
end

return Registry;
