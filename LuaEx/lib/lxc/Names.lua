--[[!
@fqxn LuaEx.LXC.Names
@desc <h3>Names — responsibility and connections</h3><p>Defines declaration identifier syntax and reserved
    names. Parser applies it to namespace/type/member/parameter names; Validation also checks generated accessor
    aliases. Lua/LXC reserved words, _ENV and the compiler-private __lxc prefix cannot be declaration
    identifiers.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
!]]
-- Keep runtime string operations independent of application replacements.
local _gmatch, _match = string.gmatch, string.match;



local Names = {};
local _tReserved = {};
for sName in _gmatch('and break do else elseif end false for function goto if in local nil not or repeat return then true until while '..
    'namespace class public private protected final const this base abstract override static permits excludes using requires null operator enum extension within', '%S+') do
    _tReserved[sName] = true;
end


--[[!
@fqxn LuaEx.LXC.Names.valid
@desc Checks identifier shape and reserved exclusions: Lua/LXC words, _ENV and compiler-private __lxc prefixes.
    Does not test uniqueness against existing declarations.
@param string sName Name/path to resolve or inspect under the lookup rules described above.
@ret boolean bValid Whether the name is permitted.
@vis internal
!]]
function Names.valid(sName)
    return type(sName) == 'string' and _match(sName, '^[%a_][%w_]*$') ~= nil and
        not _tReserved[sName] and sName ~= '_ENV' and not _match(sName, '^__lxc');
end

return Names;

