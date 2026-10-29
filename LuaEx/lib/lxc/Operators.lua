--[[!
@fqxn LuaEx.LXC.Operators
@desc <h3>Operators — responsibility and connections</h3><p>Defines supported instance operators, parameter
    contracts and spelling-to-metamethod mappings. Parser resolves spellings, Validation checks public instance
    visibility and arity, Runtime supplies receiver-aware invocation, and Facades supplies Lua dispatch. Clone
    and snapshot operators also connect to dedicated graph services.</p>
@vis internal
@see <a href="#LuaEx.LXC.Modules">Module map</a>
@prifield table _tBinary Private local sequence: arithmetic/comparison/bitwise contracts take one or two
    explicit parameters; unary contracts take none.
!]]

local Operators = {};
local _tBinary = {'__add', '__sub', '__mul', '__div', '__idiv', '__mod', '__pow',
    '__concat', '__eq', '__lt', '__le', '__band', '__bor', '__bxor', '__shl', '__shr'};
for _, sName in ipairs(_tBinary) do Operators[sName] = {Kind = 'binary', Min = 1, Max = 2}; end
for _, sName in ipairs({'__unm', '__bnot', '__len', '__tostring', '__pairs', '__gc', '__clone'}) do
    Operators[sName] = {Kind = 'unary', Min = 0, Max = 0};
end
Operators.__call = {Kind = 'call', Min = 0, Max = math.huge, Variadic = true};
Operators.__index = {Kind = 'index', Min = 1, Max = 1};
Operators.__newindex = {Kind = 'newindex', Min = 2, Max = 2};
Operators.__close = {Kind = 'close', Min = 1, Max = 1};
Operators.__serialize = {Kind = 'snapshot', Min = 0, Max = 1};
Operators.__deserialize = {Kind = 'snapshot', Min = 0, Max = 1};

local _tSpellings = {
    ['+'] = '__add', ['*'] = '__mul', ['/'] = '__div', ['//'] = '__idiv',
    ['%'] = '__mod', ['^'] = '__pow', ['..'] = '__concat', ['#'] = '__len',
    ['<'] = '__lt', ['<='] = '__le', ['&'] = '__band', ['|'] = '__bor',
    ['<<'] = '__shl', ['>>'] = '__shr', ['=='] = '__eq',
    ['()'] = '__call', ['[]'] = '__index', ['[]='] = '__newindex',
    call = '__call', index = '__index', newindex = '__newindex',
    tostring = '__tostring', pairs = '__pairs', close = '__close', gc = '__gc',
    clone = '__clone', serialize = '__serialize', deserialize = '__deserialize',
};


--[[!
@fqxn LuaEx.LXC.Operators.resolve
@desc Maps symbols/aliases/supported metamethod names to canonical keys. Zero-parameter -/~ select unary
    operations, otherwise subtraction/xor. Validation separately enforces arity.
@param string sSpelling Source operator symbol, named alias or direct metamethod name.
@param number nParameters Explicit parameter count excluding hidden runtime arguments.
@ret string|nil sName Canonical supported key or nil.
@vis internal
!]]
function Operators.resolve(sSpelling, nParameters)
    if (sSpelling == '-') then return nParameters == 0 and '__unm' or '__sub'; end
    if (sSpelling == '~') then return nParameters == 0 and '__bnot' or '__bxor'; end
    return _tSpellings[sSpelling] or (type(Operators[sSpelling]) == 'table' and sSpelling or nil);
end

return Operators;
