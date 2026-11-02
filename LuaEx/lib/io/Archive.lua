-- Dependency-free ZIP storage and extraction. Uses LuaEx native file operations.
local Archive = {};
local _tCRC = {};
for nValue = 0, 255 do
    local nCRC = nValue;
    for _ = 1, 8 do nCRC = (nCRC >> 1) ~ ((nCRC & 1) ~= 0 and 0xedb88320 or 0); end
    _tCRC[nValue] = nCRC;
end
local function checksum(sBytes)
    local nCRC = 0xffffffff;
    for nIndex = 1, #sBytes do nCRC = (nCRC >> 8) ~ _tCRC[(nCRC ~ sBytes:byte(nIndex)) & 255]; end
    return (~nCRC) & 0xffffffff;
end

-- RFC 1951: canonical Huffman codes; bit fields use least-significant-bit order.
local function inflate(sBytes, nExpected)
    assert(nExpected <= 268435456, "ZIP entry exceeds the 256 MiB extraction limit.");
    local nPosition, nBuffer, nBits = 1, 0, 0;
    local tOutput = {};
    local function fBits(nCount)
        while (nBits < nCount) do
            assert(nPosition <= #sBytes, "Truncated DEFLATE stream.");
            nBuffer = nBuffer | (sBytes:byte(nPosition) << nBits);
            nPosition, nBits = nPosition + 1, nBits + 8;
        end
        local nValue = nBuffer & ((1 << nCount) - 1);
        nBuffer, nBits = nBuffer >> nCount, nBits - nCount;
        return nValue;
    end
    local function fTree(tLengths)
        local tCounts, tNext, tTree = {}, {}, {};
        local nLeft, nCode = 1, 0;
        for _, nLength in ipairs(tLengths) do
            assert(nLength >= 0 and nLength <= 15, "Invalid Huffman length.");
            if (nLength > 0) then tCounts[nLength] = (tCounts[nLength] or 0) + 1; end
        end
        for nLength = 1, 15 do
            nLeft = nLeft * 2 - (tCounts[nLength] or 0);
            assert(nLeft >= 0, "Oversubscribed Huffman tree.");
            nCode = (nCode + (tCounts[nLength - 1] or 0)) * 2;
            tNext[nLength], tTree[nLength] = nCode, {};
        end
        for nSymbol, nLength in ipairs(tLengths) do
            if (nLength > 0) then
                tTree[nLength][tNext[nLength]] = nSymbol - 1;
                tNext[nLength] = tNext[nLength] + 1;
            end
        end
        return tTree;
    end
    local function fDecode(tTree)
        local nCode = 0;
        for nLength = 1, 15 do
            nCode = nCode * 2 + fBits(1);
            local nSymbol = tTree[nLength][nCode];
            if (nSymbol ~= nil) then return nSymbol; end
        end
        error("Invalid Huffman code.");
    end
    local tLengthBase = {3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258};
    local tLengthBits = {0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0};
    local tDistanceBase = {1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577};
    local tDistanceBits = {0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13};
    local bFinal = false;
    repeat
        bFinal = fBits(1) == 1;
        local nKind = fBits(2);
        if (nKind == 0) then
            nBuffer, nBits = 0, 0;
            local nLength, nInverse = fBits(16), fBits(16);
            assert((nLength ~ nInverse) == 65535, "Invalid stored DEFLATE block.");
            assert(#tOutput + nLength <= nExpected, "Inflated data exceeds its declared size.");
            for _ = 1, nLength do tOutput[#tOutput + 1] = string.char(fBits(8)); end
        elseif (nKind == 1 or nKind == 2) then
            local tLengths, tDistances = {}, {};
            if (nKind == 1) then
                for nSymbol = 0, 287 do tLengths[nSymbol + 1] = nSymbol < 144 and 8 or nSymbol < 256 and 9 or nSymbol < 280 and 7 or 8; end
                for nSymbol = 0, 31 do tDistances[nSymbol + 1] = 5; end
            else
                local nLiteral, nDistance, nCodes = fBits(5) + 257, fBits(5) + 1, fBits(4) + 4;
                assert(nLiteral <= 286 and nDistance <= 32, "Invalid dynamic DEFLATE counts.");
                local tOrder = {16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15};
                local tCodes, tAll = {}, {};
                for nIndex = 1, 19 do tCodes[nIndex] = 0; end
                for nIndex = 1, nCodes do tCodes[tOrder[nIndex] + 1] = fBits(3); end
                local tCodeTree = fTree(tCodes);
                while (#tAll < nLiteral + nDistance) do
                    local nValue = fDecode(tCodeTree);
                    if (nValue < 16) then tAll[#tAll + 1] = nValue;
                    else
                        local nLength, nRepeated;
                        if (nValue == 16) then
                            assert(#tAll > 0, "Missing repeated code length.");
                            nLength, nRepeated = fBits(2) + 3, tAll[#tAll];
                        elseif (nValue == 17) then nLength, nRepeated = fBits(3) + 3, 0;
                        else nLength, nRepeated = fBits(7) + 11, 0; end
                        assert(#tAll + nLength <= nLiteral + nDistance, "Code length repetition exceeds its tree.");
                        for _ = 1, nLength do tAll[#tAll + 1] = nRepeated; end
                    end
                end
                for nIndex = 1, nLiteral do tLengths[nIndex] = tAll[nIndex]; end
                for nIndex = 1, nDistance do tDistances[nIndex] = tAll[nLiteral + nIndex]; end
            end
            assert(tLengths[257] and tLengths[257] > 0, "Missing DEFLATE end-of-block code.");
            local tLiteralTree, tDistanceTree = fTree(tLengths), fTree(tDistances);
            while (true) do
                local nValue = fDecode(tLiteralTree);
                if (nValue < 256) then
                    assert(#tOutput < nExpected, "Inflated data exceeds its declared size.");
                    tOutput[#tOutput + 1] = string.char(nValue);
                elseif (nValue == 256) then break;
                else
                    local nIndex = nValue - 256;
                    assert(tLengthBase[nIndex], "Reserved DEFLATE length code.");
                    local nLength = tLengthBase[nIndex] + fBits(tLengthBits[nIndex]);
                    local nDistanceCode = fDecode(tDistanceTree) + 1;
                    assert(tDistanceBase[nDistanceCode], "Reserved DEFLATE distance code.");
                    local nDistance = tDistanceBase[nDistanceCode] + fBits(tDistanceBits[nDistanceCode]);
                    assert(nDistance <= #tOutput and #tOutput + nLength <= nExpected, "Invalid DEFLATE back-reference.");
                    for _ = 1, nLength do tOutput[#tOutput + 1] = tOutput[#tOutput - nDistance + 1]; end
                end
            end
        else error("Reserved DEFLATE block type."); end
    until bFinal;
    assert(#tOutput == nExpected and nPosition == #sBytes + 1, "DEFLATE size mismatch.");
    return table.concat(tOutput);
end

local function entryName(sName)
    sName = sName:gsub("\\", "/");
    assert(sName ~= "" and not sName:find("%z") and not sName:match("^/") and not sName:match("^%a:"), "Unsafe ZIP path.");
    for sPart in sName:gmatch("[^/]+") do
        local sDevice = sPart:match("^([^.]*)"):upper();
        assert(sPart ~= ".." and sPart ~= "." and not sPart:find('[%c:<>"|?*]') and not sPart:match("[. ]$"),
            "Unsafe ZIP path component.");
        assert(sDevice ~= "CON" and sDevice ~= "PRN" and sDevice ~= "AUX" and sDevice ~= "NUL" and
            not sDevice:match("^COM[1-9]$") and not sDevice:match("^LPT[1-9]$"), "Reserved ZIP device name.");
    end
    return sName;
end

function Archive.write(tFiles, sDestination, tNative)
    assert(type(tFiles) == "table" and #tFiles > 0 and #tFiles < 65535, "ZIP requires 1..65534 files.");
    local nFiles = 0;
    for nIndex in pairs(tFiles) do
        assert(type(nIndex) == "number" and nIndex % 1 == 0 and nIndex >= 1 and nIndex <= #tFiles, "ZIP files must be a dense array.");
        nFiles = nFiles + 1;
    end
    assert(nFiles == #tFiles, "ZIP files must be a dense array.");
    local bOK, vResult, sReason = pcall(function()
        local tLocal, tCentral, tNames = {}, {}, {};
        local nOffset = 0;
        for _, pFile in ipairs(tFiles) do
            local sData, sReadReason = tNative.read(pFile);
            assert(sData, sReadReason);
            local sName = entryName(pFile:gsub("\\", "/"):match("([^/]+)$"));
            assert(not tNames[sName], "Duplicate ZIP entry name: "..sName);
            tNames[sName] = true;
            local nCRC = checksum(sData);
            local sHeader = string.pack("<I4I2I2I2I2I2I4I4I4I2I2", 0x04034b50, 20, 2048, 0, 0, 33, nCRC, #sData, #sData, #sName, 0);
            tLocal[#tLocal + 1] = sHeader..sName..sData;
            tCentral[#tCentral + 1] = string.pack("<I4I2I2I2I2I2I2I4I4I4I2I2I2I2I2I4I4", 0x02014b50, 20, 20, 2048, 0, 0, 33, nCRC, #sData, #sData, #sName, 0, 0, 0, 0, 0, nOffset)..sName;
            nOffset = nOffset + #sHeader + #sName + #sData;
            assert(nOffset < 0xffffffff, "ZIP64 output is unsupported.");
        end
        local sCentral = table.concat(tCentral);
        local sEnd = string.pack("<I4I2I2I2I2I4I4I2", 0x06054b50, 0, 0, #tFiles, #tFiles, #sCentral, nOffset, 0);
        return tNative.write(sDestination, table.concat(tLocal)..sCentral..sEnd);
    end);
    if (not bOK) then return nil, tostring(vResult); end
    return vResult, sReason;
end

function Archive.extract(sArchive, sDestination, tNative)
    local bOK, sReason = pcall(function()
        local sBytes, sReadReason = tNative.read(sArchive);
        assert(sBytes, sReadReason);
        local nEnd;
        for nIndex = #sBytes - 21, math.max(1, #sBytes - 65557), -1 do
            if (sBytes:sub(nIndex, nIndex + 3) == "PK\5\6" and nIndex + 21 <= #sBytes) then
                local nComment = string.unpack("<I2", sBytes, nIndex + 20);
                if (nIndex + 21 + nComment == #sBytes) then nEnd = nIndex; break; end
            end
        end
        assert(nEnd, "Missing ZIP central directory.");
        local _, nDisk, nStartDisk, nDiskCount, nCount, nCentralSize, nCentralOffset = string.unpack("<I4I2I2I2I2I4I4I2", sBytes, nEnd);
        assert(nDisk == 0 and nStartDisk == 0 and nDiskCount == nCount and nCount < 65535 and nCentralOffset + nCentralSize == nEnd - 1,
            "Multi-volume and ZIP64 archives are unsupported.");
        local nPosition, nTotal = nCentralOffset + 1, 0;
        local tEntries, tNames = {}, {};
        for _ = 1, nCount do
            local nSignature, _, _, nFlags, nMethod, _, _, nCRC, nCompressed, nSize, nName, nExtra, nComment, nEntryDisk, _, nAttributes, nLocal, nNext =
                string.unpack("<I4I2I2I2I2I2I2I4I4I4I2I2I2I2I2I4I4", sBytes, nPosition);
            assert(nSignature == 0x02014b50 and nEntryDisk == 0 and nFlags & 1 == 0 and (nMethod == 0 or nMethod == 8),
                "Unsupported or encrypted ZIP entry.");
            assert((nAttributes >> 16) & 0xf000 ~= 0xa000, "ZIP symbolic links are unsupported.");
            assert(nSize <= 268435456 and nTotal + nSize <= 1073741824, "ZIP extraction size limit exceeded.");
            nTotal = nTotal + nSize;
            local sName = entryName(sBytes:sub(nNext, nNext + nName - 1));
            assert(#sName == nName and not tNames[sName:lower()], "Truncated or duplicate ZIP name.");
            tNames[sName:lower()] = true;
            nPosition = nNext + nName + nExtra + nComment;
            assert(nPosition <= nEnd, "ZIP entry exceeds central directory.");
            local nHeader, _, nLocalFlags, nLocalMethod, _, _, _, _, _, nLocalName, nLocalExtra, nData =
                string.unpack("<I4I2I2I2I2I2I4I4I4I2I2", sBytes, nLocal + 1);
            assert(nHeader == 0x04034b50 and nLocalFlags == nFlags and nLocalMethod == nMethod, "ZIP local header mismatch.");
            assert(sBytes:sub(nData, nData + nLocalName - 1) == sName, "ZIP local filename mismatch.");
            nData = nData + nLocalName + nLocalExtra;
            assert(nData + nCompressed - 1 <= nCentralOffset, "ZIP data exceeds local area.");
            local sData = sBytes:sub(nData, nData + nCompressed - 1);
            if (nMethod == 8) then sData = inflate(sData, nSize); end
            assert(#sData == nSize and checksum(sData) == nCRC, "ZIP checksum or size mismatch.");
            tEntries[#tEntries + 1] = {Name = sName, Data = sData, Directory = sName:sub(-1) == "/"};
        end
        assert(nPosition == nEnd, "ZIP central directory size mismatch.");
        local tRoot = tNative.stat(sDestination);
        assert(not tRoot or tRoot.Kind == "directory" and not tRoot.Link, "ZIP destination must be a directory without a link.");
        assert(tNative.mkdir(sDestination));
        -- Verify every output ancestor before writing; never traverse existing links.
        for _, tEntry in ipairs(tEntries) do
            local pPath = sDestination;
            local tParts = {};
            for sPart in tEntry.Name:gmatch("[^/]+") do tParts[#tParts + 1] = sPart; end
            for nIndex, sPart in ipairs(tParts) do
                pPath = pPath.."/"..sPart;
                local tInfo = tNative.stat(pPath);
                assert(not tInfo or not tInfo.Link, "ZIP output would traverse a link.");
                if (nIndex < #tParts or tEntry.Directory) then
                    assert(not tInfo or tInfo.Kind == "directory", "ZIP directory conflicts with an existing file.");
                    assert(tNative.mkdir(pPath));
                else
                    assert(not tInfo or tInfo.Kind == "file", "ZIP file conflicts with a directory.");
                    assert(tNative.write(pPath, tEntry.Data));
                end
            end
        end
    end);
    if (not bOK) then return nil, tostring(sReason); end
    return true;
end
return Archive;
