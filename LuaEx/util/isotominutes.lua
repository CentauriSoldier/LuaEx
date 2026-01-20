function isotominutes(sISO);
    local sYear, sMonth, sDay, sHour, sMinute, sSecond =
        sISO:match("(%d+)%D+(%d+)%D+(%d+)%D*(%d+)%D+(%d+)%D+(%d+)");

    if not (sYear and sMonth and sDay and sHour and sMinute) then
        error("Error in isoToMinutes: Invalid ISO string '"..tostring(sISO).."'.");
    end;

    local nYear   = tonumber(sYear);
    local nMonth  = tonumber(sMonth);
    local nDay    = tonumber(sDay);
    local nHour   = tonumber(sHour);
    local nMinute = tonumber(sMinute);

    local tMonthDays = {31,28,31,30,31,30,31,31,30,31,30,31};

    local function isLeap(nY);
        return (nY % 4 == 0 and nY % 100 ~= 0) or (nY % 400 == 0);
    end;

    local nTotalDays = 0;

    for nY = 0, nYear - 1 do
        nTotalDays = nTotalDays + (isLeap(nY) and 366 or 365);
    end;

    for nM = 1, nMonth - 1 do
        nTotalDays = nTotalDays + tMonthDays[nM];
        if (nM == 2 and isLeap(nYear)) then
            nTotalDays = nTotalDays + 1;
        end;
    end;

    nTotalDays = nTotalDays + (nDay - 1);

    return (nTotalDays * 1440) + (nHour * 60) + nMinute;
end

return isotominutes;
