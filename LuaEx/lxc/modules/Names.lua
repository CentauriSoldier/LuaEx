--[[!
@fqxn LXC.Names
@desc Identifier policy shared by declaration parsing and generated accessor names.
    Contextual accessor words stay available outside their special contexts.
!]]
local Names = {};
local _tReserved = {};
for sName in ('and break do else elseif end false for function goto if in local nil not or repeat return then true until while '..
    'namespace class public private protected final const this base abstract override static permits excludes using requires null operator'):gmatch('%S+') do
    _tReserved[sName] = true;
end

--[[!
@fqxn LXC.Names.valid
@desc Accepts variable-compliant non-reserved identifiers, excluding compiler names.
!]]
function Names.valid(sName)
    return type(sName) == 'string' and string.match(sName, '^[%a_][%w_]*$') ~= nil and
        not _tReserved[sName] and sName ~= '_ENV' and not string.match(sName, '^__lxc');
end

return Names;
