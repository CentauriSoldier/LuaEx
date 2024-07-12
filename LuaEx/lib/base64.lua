--[[!
    @fqxn LuaEx.Libraries.base64
    @author Centauri Soldier
    @license <a href="https://unlicense.org/" target="_blank">The Unlicense</a>
    @github <a href="https://github.com/CentauriSoldier/LuaEx" target="_blank">LuaEx</a>
    @desc Used for encoding/decoding strings to and from <a href="https://en.wikipedia.org/wiki/Base64" target="_blank">base64</a>.
    @ver 1.0
!]]
local base64    = {};
local string    = string;
local table     = table;

-- Character table string
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

--[[!
    @fqxn LuaEx.Libraries.base64.enc
    @desc Encodes a string to Base64.
    @param string sInput The sting to encode.
    @ret string sEncoded The encoded Base64 string.
    @ex
    local sText     = "I really like apples but only the glowing, purple ones.";
    local sEncoded  = base64.enc(sText);
    print(sEncoded) --> SSByZWFsbHkgbGlrZSBhcHBsZXMgYnV0IG9ubHkgdGhlIGdsb3dpbmcsIHB1cnBsZSBvbmVzLg==
!]]
function base64.enc(data)
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end


--[[!
    @fqxn LuaEx.Libraries.base64.enc
    @desc Encodes a string to Base64.
    @param string sInput The sting to encode.
    @ret string sEncoded The encoded Base64 string.
    @ex
    local sText     = "I really like apples but only the glowing, purple ones.";
    local sEncoded  = base64.enc(sText);
    print(sEncoded) --> SSByZWFsbHkgbGlrZSBhcHBsZXMgYnV0IG9ubHkgdGhlIGdsb3dpbmcsIHB1cnBsZSBvbmVzLg==
    local sDecoded  = base64.dec(sEncoded);
    print(sDecoded) --> I really like apples but only the glowing, purple ones.
    print (sText == sDecoded) --> true
!]]
function base64.dec(data)
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

return base64;
