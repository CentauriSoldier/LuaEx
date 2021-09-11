--credit for this function (https://www.codegrepper.com/code-examples/lua/lua+split+string+into+table)
function string.delmitedtotable(sInput, sDelimiter)
    local tRet = {};
    for sMatch in (sInput..delimiter):gmatch("(.-)"..sDelimiter) do
        table.insert(tRet, sMatch);
    end
    return tRet;
end
