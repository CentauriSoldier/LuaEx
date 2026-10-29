--[[!
@fqxn LXC.Operators
@desc Operator spellings and load-time contracts. Binary methods accept either
    one other operand or both original operands, preserving noncommutative order.
    Native equality uses the same contracts, with identity fallback when absent.
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
@fqxn LXC.Operators.resolve
@desc Resolves spelling after parsing parameters. Minus/tilde choose the unary
    or binary Lua operation from the declared operand count.
@ret string|nil Canonical metamethod name, or nil for an unsupported spelling.
!]]
function Operators.resolve(sSpelling, nParameters)
    if (sSpelling == '-') then return nParameters == 0 and '__unm' or '__sub'; end
    if (sSpelling == '~') then return nParameters == 0 and '__bnot' or '__bxor'; end
    return _tSpellings[sSpelling] or (type(Operators[sSpelling]) == 'table' and sSpelling or nil);
end

return Operators;
