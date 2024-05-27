local base64    = {};
local string    = string;
local table     = table;

-- Character table string
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Function to encode data
function base64.encOLD(data)
    local result = {}
    local padding = 2 - ((#data - 1) % 3)
    data = data .. string.rep('\0', padding)

    for i = 1, #data, 3 do
        local bytes = data:sub(i, i+2)
        local n = (bytes:byte(1) << 16) + (bytes:byte(2) << 8) + bytes:byte(3)

        table.insert(result, b:sub((n >> 18) + 1, (n >> 18) + 1))
        table.insert(result, b:sub(((n >> 12) & 63) + 1, ((n >> 12) & 63) + 1))
        table.insert(result, b:sub(((n >> 6) & 63) + 1, ((n >> 6) & 63) + 1))
        table.insert(result, b:sub((n & 63) + 1, (n & 63) + 1))
    end

    for i = 1, padding do
        result[#result - i + 1] = '='
    end

    return table.concat(result)
end

-- Function to decode data
function base64.decOLD(data)
    data = data:gsub('%s', ''):gsub('=', '')
    local result = {}

    for i = 1, #data, 4 do
        local n = (b:find(data:sub(i, i)) - 1) << 18
                + (b:find(data:sub(i+1, i+1)) - 1) << 12
                + (b:find(data:sub(i+2, i+2)) - 1) << 6
                + (b:find(data:sub(i+3, i+3)) - 1)

        table.insert(result, string.char((n >> 16) & 255))
        table.insert(result, string.char((n >> 8) & 255))
        table.insert(result, string.char(n & 255))
    end

    return table.concat(result)
end


-- Character table string
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Function to encode data
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

-- Function to decode data
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

return base64
