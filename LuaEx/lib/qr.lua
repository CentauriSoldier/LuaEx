local qr = {};

local MODE_NUMERIC         = 0x1;
local MODE_ALPHANUMERIC    = 0x2;
local MODE_BYTE            = 0x4;

local ECL_FORMAT_BITS = {
    L = 1,
    M = 0,
    Q = 3,
    H = 2,
};

local ALPHANUMERIC_MAP = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:";
local ALPHANUMERIC_LUT = {};

do
    for nIndex = 1, #ALPHANUMERIC_MAP do
        ALPHANUMERIC_LUT[ALPHANUMERIC_MAP:sub(nIndex, nIndex)] = nIndex - 1;
    end
end

local ALIGNMENT_POSITIONS = {
    [1]  = {},
    [2]  = {6, 18},
    [3]  = {6, 22},
    [4]  = {6, 26},
    [5]  = {6, 30},
    [6]  = {6, 34},
    [7]  = {6, 22, 38},
    [8]  = {6, 24, 42},
    [9]  = {6, 26, 46},
    [10] = {6, 28, 50},
    [11] = {6, 30, 54},
    [12] = {6, 32, 58},
    [13] = {6, 34, 62},
    [14] = {6, 26, 46, 66},
    [15] = {6, 26, 48, 70},
    [16] = {6, 26, 50, 74},
    [17] = {6, 30, 54, 78},
    [18] = {6, 30, 56, 82},
    [19] = {6, 30, 58, 86},
    [20] = {6, 34, 62, 90},
    [21] = {6, 28, 50, 72, 94},
    [22] = {6, 26, 50, 74, 98},
    [23] = {6, 30, 54, 78, 102},
    [24] = {6, 28, 54, 80, 106},
    [25] = {6, 32, 58, 84, 110},
    [26] = {6, 30, 58, 86, 114},
    [27] = {6, 34, 62, 90, 118},
    [28] = {6, 26, 50, 74, 98, 122},
    [29] = {6, 30, 54, 78, 102, 126},
    [30] = {6, 26, 52, 78, 104, 130},
    [31] = {6, 30, 56, 82, 108, 134},
    [32] = {6, 34, 60, 86, 112, 138},
    [33] = {6, 30, 58, 86, 114, 142},
    [34] = {6, 34, 62, 90, 118, 146},
    [35] = {6, 30, 54, 78, 102, 126, 150},
    [36] = {6, 24, 50, 76, 102, 128, 154},
    [37] = {6, 28, 54, 80, 106, 132, 158},
    [38] = {6, 32, 58, 84, 110, 136, 162},
    [39] = {6, 26, 54, 82, 110, 138, 166},
    [40] = {6, 30, 58, 86, 114, 142, 170},
};

local RS_BLOCK_TABLE = {
    L = {
        [1]  = {1, 26, 19},
        [2]  = {1, 44, 34},
        [3]  = {1, 70, 55},
        [4]  = {1, 100, 80},
        [5]  = {1, 134, 108},
        [6]  = {2, 86, 68},
        [7]  = {2, 98, 78},
        [8]  = {2, 121, 97},
        [9]  = {2, 146, 116},
        [10] = {2, 86, 68, 2, 87, 69},
        [11] = {4, 101, 81},
        [12] = {2, 116, 92, 2, 117, 93},
        [13] = {4, 133, 107},
        [14] = {3, 145, 115, 1, 146, 116},
        [15] = {5, 109, 87, 1, 110, 88},
        [16] = {5, 122, 98, 1, 123, 99},
        [17] = {1, 135, 107, 5, 136, 108},
        [18] = {5, 150, 120, 1, 151, 121},
        [19] = {3, 141, 113, 4, 142, 114},
        [20] = {3, 135, 107, 5, 136, 108},
        [21] = {4, 144, 116, 4, 145, 117},
        [22] = {2, 139, 111, 7, 140, 112},
        [23] = {4, 151, 121, 5, 152, 122},
        [24] = {6, 147, 117, 4, 148, 118},
        [25] = {8, 132, 106, 4, 133, 107},
        [26] = {10, 142, 114, 2, 143, 115},
        [27] = {8, 152, 122, 4, 153, 123},
        [28] = {3, 147, 117, 10, 148, 118},
        [29] = {7, 146, 116, 7, 147, 117},
        [30] = {5, 145, 115, 10, 146, 116},
        [31] = {13, 145, 115, 3, 146, 116},
        [32] = {17, 145, 115},
        [33] = {17, 145, 115, 1, 146, 116},
        [34] = {13, 145, 115, 6, 146, 116},
        [35] = {12, 151, 121, 7, 152, 122},
        [36] = {6, 151, 121, 14, 152, 122},
        [37] = {17, 152, 122, 4, 153, 123},
        [38] = {4, 152, 122, 18, 153, 123},
        [39] = {20, 147, 117, 4, 148, 118},
        [40] = {19, 148, 118, 6, 149, 119},
    },
    M = {
        [1]  = {1, 26, 16},
        [2]  = {1, 44, 28},
        [3]  = {1, 70, 44},
        [4]  = {2, 50, 32},
        [5]  = {2, 67, 43},
        [6]  = {4, 43, 27},
        [7]  = {4, 49, 31},
        [8]  = {2, 60, 38, 2, 61, 39},
        [9]  = {3, 58, 36, 2, 59, 37},
        [10] = {4, 69, 43, 1, 70, 44},
        [11] = {1, 80, 50, 4, 81, 51},
        [12] = {6, 58, 36, 2, 59, 37},
        [13] = {8, 59, 37, 1, 60, 38},
        [14] = {4, 64, 40, 5, 65, 41},
        [15] = {5, 65, 41, 5, 66, 42},
        [16] = {7, 73, 45, 3, 74, 46},
        [17] = {10, 74, 46, 1, 75, 47},
        [18] = {9, 69, 43, 4, 70, 44},
        [19] = {3, 70, 44, 11, 71, 45},
        [20] = {3, 67, 41, 13, 68, 42},
        [21] = {17, 68, 42},
        [22] = {17, 74, 46},
        [23] = {4, 75, 47, 14, 76, 48},
        [24] = {6, 73, 45, 14, 74, 46},
        [25] = {8, 75, 47, 13, 76, 48},
        [26] = {19, 74, 46, 4, 75, 47},
        [27] = {22, 73, 45, 3, 74, 46},
        [28] = {3, 73, 45, 23, 74, 46},
        [29] = {21, 73, 45, 7, 74, 46},
        [30] = {19, 75, 47, 10, 76, 48},
        [31] = {2, 74, 46, 29, 75, 47},
        [32] = {10, 74, 46, 23, 75, 47},
        [33] = {14, 74, 46, 21, 75, 47},
        [34] = {14, 74, 46, 23, 75, 47},
        [35] = {12, 75, 47, 26, 76, 48},
        [36] = {6, 75, 47, 34, 76, 48},
        [37] = {29, 74, 46, 14, 75, 47},
        [38] = {13, 74, 46, 32, 75, 47},
        [39] = {40, 75, 47, 7, 76, 48},
        [40] = {18, 75, 47, 31, 76, 48},
    },
    Q = {
        [1]  = {1, 26, 13},
        [2]  = {1, 44, 22},
        [3]  = {2, 35, 17},
        [4]  = {2, 50, 24},
        [5]  = {2, 33, 15, 2, 34, 16},
        [6]  = {4, 43, 19},
        [7]  = {2, 32, 14, 4, 33, 15},
        [8]  = {4, 40, 18, 2, 41, 19},
        [9]  = {4, 36, 16, 4, 37, 17},
        [10] = {6, 43, 19, 2, 44, 20},
        [11] = {4, 50, 22, 4, 51, 23},
        [12] = {4, 46, 20, 6, 47, 21},
        [13] = {8, 44, 20, 4, 45, 21},
        [14] = {11, 36, 16, 5, 37, 17},
        [15] = {5, 54, 24, 7, 55, 25},
        [16] = {15, 43, 19, 2, 44, 20},
        [17] = {1, 50, 22, 15, 51, 23},
        [18] = {17, 50, 22, 1, 51, 23},
        [19] = {17, 47, 21, 4, 48, 22},
        [20] = {15, 54, 24, 5, 55, 25},
        [21] = {17, 50, 22, 6, 51, 23},
        [22] = {7, 54, 24, 16, 55, 25},
        [23] = {11, 54, 24, 14, 55, 25},
        [24] = {11, 54, 24, 16, 55, 25},
        [25] = {7, 54, 24, 22, 55, 25},
        [26] = {28, 50, 22, 6, 51, 23},
        [27] = {8, 53, 23, 26, 54, 24},
        [28] = {4, 54, 24, 31, 55, 25},
        [29] = {1, 53, 23, 37, 54, 24},
        [30] = {15, 54, 24, 25, 55, 25},
        [31] = {42, 54, 24, 1, 55, 25},
        [32] = {10, 54, 24, 35, 55, 25},
        [33] = {29, 54, 24, 19, 55, 25},
        [34] = {44, 54, 24, 7, 55, 25},
        [35] = {39, 54, 24, 14, 55, 25},
        [36] = {46, 54, 24, 10, 55, 25},
        [37] = {49, 54, 24, 10, 55, 25},
        [38] = {48, 54, 24, 14, 55, 25},
        [39] = {43, 54, 24, 22, 55, 25},
        [40] = {34, 54, 24, 34, 55, 25},
    },
    H = {
        [1]  = {1, 26, 9},
        [2]  = {1, 44, 16},
        [3]  = {2, 35, 13},
        [4]  = {4, 25, 9},
        [5]  = {2, 33, 11, 2, 34, 12},
        [6]  = {4, 43, 15},
        [7]  = {4, 39, 13, 1, 40, 14},
        [8]  = {4, 40, 14, 2, 41, 15},
        [9]  = {4, 36, 12, 4, 37, 13},
        [10] = {6, 43, 15, 2, 44, 16},
        [11] = {3, 36, 12, 8, 37, 13},
        [12] = {7, 42, 14, 4, 43, 15},
        [13] = {12, 33, 11, 4, 34, 12},
        [14] = {11, 36, 12, 5, 37, 13},
        [15] = {11, 36, 12, 7, 37, 13},
        [16] = {3, 45, 15, 13, 46, 16},
        [17] = {2, 42, 14, 17, 43, 15},
        [18] = {2, 42, 14, 19, 43, 15},
        [19] = {9, 39, 13, 16, 40, 14},
        [20] = {15, 43, 15, 10, 44, 16},
        [21] = {19, 46, 16, 6, 47, 17},
        [22] = {34, 37, 13},
        [23] = {16, 45, 15, 14, 46, 16},
        [24] = {30, 46, 16, 2, 47, 17},
        [25] = {22, 45, 15, 13, 46, 16},
        [26] = {33, 46, 16, 4, 47, 17},
        [27] = {12, 45, 15, 28, 46, 16},
        [28] = {11, 45, 15, 31, 46, 16},
        [29] = {19, 45, 15, 26, 46, 16},
        [30] = {23, 45, 15, 25, 46, 16},
        [31] = {23, 45, 15, 28, 46, 16},
        [32] = {19, 45, 15, 35, 46, 16},
        [33] = {11, 45, 15, 46, 46, 16},
        [34] = {59, 46, 16, 1, 47, 17},
        [35] = {22, 45, 15, 41, 46, 16},
        [36] = {2, 45, 15, 64, 46, 16},
        [37] = {24, 45, 15, 46, 46, 16},
        [38] = {42, 45, 15, 32, 46, 16},
        [39] = {10, 45, 15, 67, 46, 16},
        [40] = {20, 45, 15, 61, 46, 16},
    },
};

local function Assert(bCond, sMsg)
    if not bCond then
        error(sMsg, 3);
    end
end

local function Copy2D(tMatrix)
    local tOut = {};
    for nY = 1, #tMatrix do
        local tRow = {};
        tOut[nY] = tRow;
        for nX = 1, #tMatrix[nY] do
            tRow[nX] = tMatrix[nY][nX];
        end
    end
    return tOut;
end

local function GetSizeFromVersion(nVersion)
    return 21 + (nVersion - 1) * 4;
end

local function MakeMatrix(nSize, bValue)
    local t = {};
    for nY = 1, nSize do
        local tRow = {};
        t[nY] = tRow;
        for nX = 1, nSize do
            tRow[nX] = bValue;
        end
    end
    return t;
end

local function GetBit(nValue, nBitIndex)
    return ((nValue >> nBitIndex) & 1) ~= 0;
end

local function BCHDigit(nData)
    local nDigits = 0;
    while nData ~= 0 do
        nDigits = nDigits + 1;
        nData = nData >> 1;
    end
    return nDigits;
end

local function BCHTypeInfo(nData)
    local nD = nData << 10;
    local nG15 = 0x537;
    local nMask = 0x5412;

    while BCHDigit(nD) - BCHDigit(nG15) >= 0 do
        nD = nD ~ (nG15 << (BCHDigit(nD) - BCHDigit(nG15)));
    end

    return ((nData << 10) | nD) ~ nMask;
end

local function BCHTypeNumber(nData)
    local nD = nData << 12;
    local nG18 = 0x1F25;

    while BCHDigit(nD) - BCHDigit(nG18) >= 0 do
        nD = nD ~ (nG18 << (BCHDigit(nD) - BCHDigit(nG18)));
    end

    return (nData << 12) | nD;
end

local GF_EXP = {};
local GF_LOG = {};

do
    for nIndex = 0, 255 do
        GF_EXP[nIndex] = nIndex;
        GF_LOG[nIndex] = nIndex;
    end

    for nIndex = 0, 7 do
        GF_EXP[nIndex] = 1 << nIndex;
    end

    for nIndex = 8, 255 do
        GF_EXP[nIndex] = GF_EXP[nIndex - 4] ~ GF_EXP[nIndex - 5] ~ GF_EXP[nIndex - 6] ~ GF_EXP[nIndex - 8];
    end

    for nIndex = 0, 254 do
        GF_LOG[GF_EXP[nIndex]] = nIndex;
    end
end

local function GFExp(nValue)
    return GF_EXP[nValue % 255];
end

local function GFLog(nValue)
    Assert(nValue > 0, "GFLog: value must be > 0.");
    return GF_LOG[nValue];
end

local function GFMul(nA, nB)
    if nA == 0 or nB == 0 then
        return 0;
    end

    return GFExp(GFLog(nA) + GFLog(nB));
end

local function RSBuildDivisor(nDegree)
    local tResult = {1};

    for nI = 0, nDegree - 1 do
        tResult[#tResult + 1] = 0;

        for nJ = #tResult - 1, 1, -1 do
            tResult[nJ + 1] = tResult[nJ + 1] ~ GFMul(tResult[nJ], GFExp(nI));
        end
    end

    return tResult;
end

local function RSComputeRemainder(tData, tDivisor)
    local tResult = {};
    local nDegree = #tDivisor - 1;

    for nI = 1, nDegree do
        tResult[nI] = 0;
    end

    for nI = 1, #tData do
        local nFactor = tData[nI] ~ tResult[1];

        for nJ = 1, nDegree - 1 do
            tResult[nJ] = tResult[nJ + 1];
        end
        tResult[nDegree] = 0;

        if nFactor ~= 0 then
            for nJ = 1, nDegree do
                tResult[nJ] = tResult[nJ] ~ GFExp(GFLog(tDivisor[nJ + 1]) + GFLog(nFactor));
            end
        end
    end

    return tResult;
end

local function GetRSBlocks(nVersion, sECL)
    local tSrc = RS_BLOCK_TABLE[sECL][nVersion];
    local tBlocks = {};

    for nI = 1, #tSrc, 3 do
        local nCount = tSrc[nI];
        local nTotal = tSrc[nI + 1];
        local nData  = tSrc[nI + 2];

        for _ = 1, nCount do
            tBlocks[#tBlocks + 1] = {
                total_count = nTotal,
                data_count = nData,
            };
        end
    end

    return tBlocks;
end

local function GetDataCapacityBits(nVersion, sECL)
    local tBlocks = GetRSBlocks(nVersion, sECL);
    local nBits = 0;

    for nI = 1, #tBlocks do
        nBits = nBits + tBlocks[nI].data_count * 8;
    end

    return nBits;
end

local function GetCharCountBits(nMode, nVersion)
    if nVersion < 10 then
        if nMode == MODE_NUMERIC then return 10; end
        if nMode == MODE_ALPHANUMERIC then return 9; end
        if nMode == MODE_BYTE then return 8; end
    elseif nVersion < 27 then
        if nMode == MODE_NUMERIC then return 12; end
        if nMode == MODE_ALPHANUMERIC then return 11; end
        if nMode == MODE_BYTE then return 16; end
    else
        if nMode == MODE_NUMERIC then return 14; end
        if nMode == MODE_ALPHANUMERIC then return 13; end
        if nMode == MODE_BYTE then return 16; end
    end

    error("Unsupported mode.", 3);
end

local function IsNumeric(sData)
    return sData:match("^%d*$") ~= nil;
end

local function IsAlphanumeric(sData)
    return sData:match("^[0-9A-Z %$%%%*%+%-%.%/:]*$") ~= nil;
end

local function ChooseMode(sData)
    if IsNumeric(sData) then
        return MODE_NUMERIC;
    end

    if IsAlphanumeric(sData) then
        return MODE_ALPHANUMERIC;
    end

    return MODE_BYTE;
end

local function AppendBits(tBits, nValue, nCount)
    Assert(nCount >= 0, "AppendBits: count must be >= 0.");

    for nI = nCount - 1, 0, -1 do
        tBits[#tBits + 1] = ((nValue >> nI) & 1);
    end
end

local function EncodeSegmentBits(sData, nMode, nVersion)
    local tBits = {};

    AppendBits(tBits, nMode, 4);
    AppendBits(tBits, #sData, GetCharCountBits(nMode, nVersion));

    if nMode == MODE_NUMERIC then
        local nIndex = 1;
        while nIndex <= #sData do
            local sChunk = sData:sub(nIndex, nIndex + 2);
            local nLen = #sChunk;
            local nValue = tonumber(sChunk);

            if nLen == 3 then
                AppendBits(tBits, nValue, 10);
            elseif nLen == 2 then
                AppendBits(tBits, nValue, 7);
            else
                AppendBits(tBits, nValue, 4);
            end

            nIndex = nIndex + 3;
        end

    elseif nMode == MODE_ALPHANUMERIC then
        local nIndex = 1;
        while nIndex <= #sData do
            local sA = sData:sub(nIndex, nIndex);
            local sB = sData:sub(nIndex + 1, nIndex + 1);

            if sB ~= "" then
                local nValue = ALPHANUMERIC_LUT[sA] * 45 + ALPHANUMERIC_LUT[sB];
                AppendBits(tBits, nValue, 11);
                nIndex = nIndex + 2;
            else
                AppendBits(tBits, ALPHANUMERIC_LUT[sA], 6);
                nIndex = nIndex + 1;
            end
        end

    elseif nMode == MODE_BYTE then
        for nIndex = 1, #sData do
            AppendBits(tBits, sData:byte(nIndex), 8);
        end

    else
        error("Unsupported mode.", 3);
    end

    return tBits;
end

local function BitsToBytes(tBits)
    local tBytes = {};
    local nValue = 0;

    for nIndex = 1, #tBits do
        nValue = (nValue << 1) | tBits[nIndex];

        if (nIndex % 8) == 0 then
            tBytes[#tBytes + 1] = nValue;
            nValue = 0;
        end
    end

    return tBytes;
end

local function PadDataBits(tBits, nCapacityBits)
    local nTerminator = math.min(4, nCapacityBits - #tBits);
    AppendBits(tBits, 0, nTerminator);

    while (#tBits % 8) ~= 0 do
        tBits[#tBits + 1] = 0;
    end

    local bPadToggle = true;
    while #tBits < nCapacityBits do
        AppendBits(tBits, bPadToggle and 0xEC or 0x11, 8);
        bPadToggle = not bPadToggle;
    end
end

local function MakeCodewords(tDataBytes, nVersion, sECL)
    local tBlocks = GetRSBlocks(nVersion, sECL);
    local tDataBlocks = {};
    local tECCBlocks = {};
    local nOffset = 1;

    for nBlockIndex = 1, #tBlocks do
        local tBlock = tBlocks[nBlockIndex];
        local tData = {};

        for nI = 1, tBlock.data_count do
            tData[nI] = tDataBytes[nOffset];
            nOffset = nOffset + 1;
        end

        tDataBlocks[nBlockIndex] = tData;

        local nECCCount = tBlock.total_count - tBlock.data_count;
        local tDivisor = RSBuildDivisor(nECCCount);
        tECCBlocks[nBlockIndex] = RSComputeRemainder(tData, tDivisor);
    end

    local tCodewords = {};
    local nMaxData = 0;
    local nMaxECC = 0;

    for nI = 1, #tBlocks do
        if tBlocks[nI].data_count > nMaxData then
            nMaxData = tBlocks[nI].data_count;
        end

        local nECCCount = tBlocks[nI].total_count - tBlocks[nI].data_count;
        if nECCCount > nMaxECC then
            nMaxECC = nECCCount;
        end
    end

    for nByteIndex = 1, nMaxData do
        for nBlockIndex = 1, #tBlocks do
            if nByteIndex <= #tDataBlocks[nBlockIndex] then
                tCodewords[#tCodewords + 1] = tDataBlocks[nBlockIndex][nByteIndex];
            end
        end
    end

    for nByteIndex = 1, nMaxECC do
        for nBlockIndex = 1, #tBlocks do
            if nByteIndex <= #tECCBlocks[nBlockIndex] then
                tCodewords[#tCodewords + 1] = tECCBlocks[nBlockIndex][nByteIndex];
            end
        end
    end

    return tCodewords;
end

local function DrawModule(tModules, tIsFunction, nX, nY, bDark)
    if nX >= 0 and nY >= 0 and nY + 1 <= #tModules and nX + 1 <= #tModules then
        tModules[nY + 1][nX + 1] = bDark;
        tIsFunction[nY + 1][nX + 1] = true;
    end
end

local function DrawFinder(tModules, tIsFunction, nX, nY)
    for nDY = -4, 4 do
        for nDX = -4, 4 do
            local nDist = math.max(math.abs(nDX), math.abs(nDY));
            local bDark = (nDist ~= 2 and nDist ~= 4);
            DrawModule(tModules, tIsFunction, nX + nDX, nY + nDY, bDark);
        end
    end
end

local function DrawAlignment(tModules, tIsFunction, nX, nY)
    for nDY = -2, 2 do
        for nDX = -2, 2 do
            local nDist = math.max(math.abs(nDX), math.abs(nDY));
            local bDark = (nDist ~= 1);
            DrawModule(tModules, tIsFunction, nX + nDX, nY + nDY, bDark);
        end
    end
end

local function DrawFunctionPatterns(tModules, tIsFunction, nVersion)
    local nSize = #tModules;

    DrawFinder(tModules, tIsFunction, 3, 3);
    DrawFinder(tModules, tIsFunction, nSize - 4, 3);
    DrawFinder(tModules, tIsFunction, 3, nSize - 4);

    for nI = 0, nSize - 1 do
        if not tIsFunction[7][nI + 1] then
            DrawModule(tModules, tIsFunction, nI, 6, (nI % 2) == 0);
        end
        if not tIsFunction[nI + 1][7] then
            DrawModule(tModules, tIsFunction, 6, nI, (nI % 2) == 0);
        end
    end

    local tAlign = ALIGNMENT_POSITIONS[nVersion];
    for nI = 1, #tAlign do
        for nJ = 1, #tAlign do
            local nX = tAlign[nJ];
            local nY = tAlign[nI];
            local bCornerOverlap =
                (nI == 1 and nJ == 1) or
                (nI == 1 and nJ == #tAlign) or
                (nI == #tAlign and nJ == 1);

            if not bCornerOverlap then
                DrawAlignment(tModules, tIsFunction, nX, nY);
            end
        end
    end

    --reserve format information areas exactly
    for nY = 0, 5 do
        DrawModule(tModules, tIsFunction, 8, nY, false);
    end
    DrawModule(tModules, tIsFunction, 8, 7, false);
    DrawModule(tModules, tIsFunction, 8, 8, false);
    DrawModule(tModules, tIsFunction, 7, 8, false);

    for nX = 0, 5 do
        DrawModule(tModules, tIsFunction, nX, 8, false);
    end

    for nX = nSize - 8, nSize - 1 do
        DrawModule(tModules, tIsFunction, nX, 8, false);
    end

    for nY = nSize - 7, nSize - 1 do
        DrawModule(tModules, tIsFunction, 8, nY, false);
    end

    --dark module
    DrawModule(tModules, tIsFunction, 8, nSize - 8, true);

    if nVersion >= 7 then
        local nBits = BCHTypeNumber(nVersion);

        for nI = 0, 17 do
            local bBit = GetBit(nBits, nI);
            local nA = nSize - 11 + (nI % 3);
            local nB = math.floor(nI / 3);
            DrawModule(tModules, tIsFunction, nA, nB, bBit);
            DrawModule(tModules, tIsFunction, nB, nA, bBit);
        end
    end
end

local function DrawFormatBits(tModules, tIsFunction, sECL, nMask)
    local nSize = #tModules;
    local nData = (ECL_FORMAT_BITS[sECL] << 3) | nMask;
    local nBits = BCHTypeInfo(nData);

    for nI = 0, 5 do
        DrawModule(tModules, tIsFunction, 8, nI, GetBit(nBits, nI));
    end
    DrawModule(tModules, tIsFunction, 8, 7, GetBit(nBits, 6));
    DrawModule(tModules, tIsFunction, 8, 8, GetBit(nBits, 7));
    DrawModule(tModules, tIsFunction, 7, 8, GetBit(nBits, 8));

    for nI = 9, 14 do
        DrawModule(tModules, tIsFunction, 14 - nI, 8, GetBit(nBits, nI));
    end

    for nI = 0, 7 do
        DrawModule(tModules, tIsFunction, nSize - 1 - nI, 8, GetBit(nBits, nI));
    end
    for nI = 8, 14 do
        DrawModule(tModules, tIsFunction, 8, nSize - 15 + nI, GetBit(nBits, nI));
    end

    DrawModule(tModules, tIsFunction, 8, nSize - 8, true);
end

local function GetMaskBit(nMask, nX, nY)
    if nMask == 0 then return ((nX + nY) % 2) == 0; end
    if nMask == 1 then return (nY % 2) == 0; end
    if nMask == 2 then return (nX % 3) == 0; end
    if nMask == 3 then return ((nX + nY) % 3) == 0; end
    if nMask == 4 then return (((nY // 2) + (nX // 3)) % 2) == 0; end
    if nMask == 5 then return (((nX * nY) % 2) + ((nX * nY) % 3)) == 0; end
    if nMask == 6 then return ((((nX * nY) % 2) + ((nX * nY) % 3)) % 2) == 0; end
    if nMask == 7 then return ((((nX * nY) % 3) + ((nX + nY) % 2)) % 2) == 0; end
    error("Invalid mask.", 3);
end

local function DrawCodewords(tModules, tIsFunction, tCodewords)
    local nSize = #tModules;
    local nBitIndex = 0;
    local nTotalBits = #tCodewords * 8;
    local nCol = nSize - 1;
    local bUp = true;

    while nCol >= 1 do
        if nCol == 6 then
            nCol = nCol - 1;
        end

        for nRowOffset = 0, nSize - 1 do
            local nY = bUp and (nSize - 1 - nRowOffset) or nRowOffset;

            for nDX = 0, 1 do
                local nX = nCol - nDX;

                if not tIsFunction[nY + 1][nX + 1] then
                    local bDark = false;

                    if nBitIndex < nTotalBits then
                        local nByte = tCodewords[(nBitIndex // 8) + 1];
                        bDark = ((nByte >> (7 - (nBitIndex % 8))) & 1) ~= 0;
                    end

                    tModules[nY + 1][nX + 1] = bDark;
                    nBitIndex = nBitIndex + 1;
                end
            end
        end

        bUp = not bUp;
        nCol = nCol - 2;
    end
end

local function ApplyMask(tModules, tIsFunction, nMask)
    local nSize = #tModules;

    for nY = 0, nSize - 1 do
        for nX = 0, nSize - 1 do
            if not tIsFunction[nY + 1][nX + 1] then
                if GetMaskBit(nMask, nX, nY) then
                    tModules[nY + 1][nX + 1] = not tModules[nY + 1][nX + 1];
                end
            end
        end
    end
end

local function GetPenaltyScore(tModules)
    local nSize = #tModules;
    local nPenalty = 0;

    for nY = 1, nSize do
        local bPrev = tModules[nY][1];
        local nRun = 1;

        for nX = 2, nSize do
            if tModules[nY][nX] == bPrev then
                nRun = nRun + 1;
            else
                if nRun >= 5 then
                    nPenalty = nPenalty + (nRun - 2);
                end
                bPrev = tModules[nY][nX];
                nRun = 1;
            end
        end

        if nRun >= 5 then
            nPenalty = nPenalty + (nRun - 2);
        end
    end

    for nX = 1, nSize do
        local bPrev = tModules[1][nX];
        local nRun = 1;

        for nY = 2, nSize do
            if tModules[nY][nX] == bPrev then
                nRun = nRun + 1;
            else
                if nRun >= 5 then
                    nPenalty = nPenalty + (nRun - 2);
                end
                bPrev = tModules[nY][nX];
                nRun = 1;
            end
        end

        if nRun >= 5 then
            nPenalty = nPenalty + (nRun - 2);
        end
    end

    for nY = 1, nSize - 1 do
        for nX = 1, nSize - 1 do
            local b = tModules[nY][nX];
            if tModules[nY][nX + 1] == b and
               tModules[nY + 1][nX] == b and
               tModules[nY + 1][nX + 1] == b then
                nPenalty = nPenalty + 3;
            end
        end
    end

    local function IsDark(nX, nY)
        return tModules[nY + 1][nX + 1];
    end

    for nY = 0, nSize - 1 do
        for nX = 0, nSize - 11 do
            local b1 =
                IsDark(nX + 0, nY) and
                not IsDark(nX + 1, nY) and
                IsDark(nX + 2, nY) and
                IsDark(nX + 3, nY) and
                IsDark(nX + 4, nY) and
                not IsDark(nX + 5, nY) and
                IsDark(nX + 6, nY) and
                not IsDark(nX + 7, nY) and
                not IsDark(nX + 8, nY) and
                not IsDark(nX + 9, nY) and
                not IsDark(nX + 10, nY);

            local b2 =
                not IsDark(nX + 0, nY) and
                not IsDark(nX + 1, nY) and
                not IsDark(nX + 2, nY) and
                not IsDark(nX + 3, nY) and
                IsDark(nX + 4, nY) and
                not IsDark(nX + 5, nY) and
                IsDark(nX + 6, nY) and
                IsDark(nX + 7, nY) and
                IsDark(nX + 8, nY) and
                not IsDark(nX + 9, nY) and
                IsDark(nX + 10, nY);

            if b1 or b2 then
                nPenalty = nPenalty + 40;
            end
        end
    end

    for nX = 0, nSize - 1 do
        for nY = 0, nSize - 11 do
            local b1 =
                IsDark(nX, nY + 0) and
                not IsDark(nX, nY + 1) and
                IsDark(nX, nY + 2) and
                IsDark(nX, nY + 3) and
                IsDark(nX, nY + 4) and
                not IsDark(nX, nY + 5) and
                IsDark(nX, nY + 6) and
                not IsDark(nX, nY + 7) and
                not IsDark(nX, nY + 8) and
                not IsDark(nX, nY + 9) and
                not IsDark(nX, nY + 10);

            local b2 =
                not IsDark(nX, nY + 0) and
                not IsDark(nX, nY + 1) and
                not IsDark(nX, nY + 2) and
                not IsDark(nX, nY + 3) and
                IsDark(nX, nY + 4) and
                not IsDark(nX, nY + 5) and
                IsDark(nX, nY + 6) and
                IsDark(nX, nY + 7) and
                IsDark(nX, nY + 8) and
                not IsDark(nX, nY + 9) and
                IsDark(nX, nY + 10);

            if b1 or b2 then
                nPenalty = nPenalty + 40;
            end
        end
    end

    local nDark = 0;
    for nY = 1, nSize do
        for nX = 1, nSize do
            if tModules[nY][nX] then
                nDark = nDark + 1;
            end
        end
    end

    local nTotal = nSize * nSize;
    local nK = math.floor(math.abs((nDark * 20) - (nTotal * 10)) / nTotal);
    nPenalty = nPenalty + nK * 10;

    return nPenalty;
end

local function BuildQR(sData, nVersion, sECL, nMask)
    local nMode = ChooseMode(sData);
    local nMinVersion = nVersion or 1;
    local nMaxVersion = nVersion or 40;
    local nChosenVersion = nil;
    local tDataBits = nil;

    for nVer = nMinVersion, nMaxVersion do
        local tBits = EncodeSegmentBits(sData, nMode, nVer);
        local nCapacityBits = GetDataCapacityBits(nVer, sECL);

        if #tBits <= nCapacityBits then
            nChosenVersion = nVer;
            tDataBits = tBits;
            break;
        end
    end

    Assert(nChosenVersion ~= nil, "Data does not fit in the requested version/ECL.");

    local nCapacityBits = GetDataCapacityBits(nChosenVersion, sECL);
    PadDataBits(tDataBits, nCapacityBits);

    local tDataBytes = BitsToBytes(tDataBits);
    local tCodewords = MakeCodewords(tDataBytes, nChosenVersion, sECL);

    local nSize = GetSizeFromVersion(nChosenVersion);
    local tModules = MakeMatrix(nSize, false);
    local tIsFunction = MakeMatrix(nSize, false);

    DrawFunctionPatterns(tModules, tIsFunction, nChosenVersion);
    DrawCodewords(tModules, tIsFunction, tCodewords);

    local nChosenMask = nMask;
    if nChosenMask == nil then
        local nBestMask = 0;
        local nBestPenalty = nil;

        for nTryMask = 0, 7 do
            local tTestModules = Copy2D(tModules);
            local tTestFunc = Copy2D(tIsFunction);

            ApplyMask(tTestModules, tTestFunc, nTryMask);
            DrawFormatBits(tTestModules, tTestFunc, sECL, nTryMask);

            local nPenalty = GetPenaltyScore(tTestModules);
            if (nBestPenalty == nil) or (nPenalty < nBestPenalty) then
                nBestPenalty = nPenalty;
                nBestMask = nTryMask;
            end
        end

        nChosenMask = nBestMask;
    end

    ApplyMask(tModules, tIsFunction, nChosenMask);
    DrawFormatBits(tModules, tIsFunction, sECL, nChosenMask);

    return tModules, {
        version = nChosenVersion,
        ecl = sECL,
        mask = nChosenMask,
        mode = nMode,
        size = nSize,
    };
end

local function ReadFormatBits(tMatrix)
    local nSize = #tMatrix;
    local tBits = {};

    for nI = 0, 5 do
        tBits[#tBits + 1] = tMatrix[nI + 1][9] and 1 or 0;
    end
    tBits[#tBits + 1] = tMatrix[8][9] and 1 or 0;
    tBits[#tBits + 1] = tMatrix[9][9] and 1 or 0;
    tBits[#tBits + 1] = tMatrix[9][8] and 1 or 0;
    for nI = 9, 14 do
        tBits[#tBits + 1] = tMatrix[9][15 - nI] and 1 or 0;
    end

    local nValue = 0;
    for nI = 1, #tBits do
        nValue = nValue | (tBits[nI] << (nI - 1));
    end

    for sECL, nFmt in pairs(ECL_FORMAT_BITS) do
        for nMask = 0, 7 do
            local nExpected = BCHTypeInfo((nFmt << 3) | nMask);
            if nExpected == nValue then
                return sECL, nMask;
            end
        end
    end

    error("Unable to decode format bits.", 3);
end

local function GetVersionFromMatrix(tMatrix)
    local nSize = #tMatrix;
    Assert(nSize >= 21 and nSize <= 177 and ((nSize - 21) % 4) == 0, "Invalid matrix size.");
    local nVersion = ((nSize - 21) // 4) + 1;
    Assert(nVersion >= 1 and nVersion <= 40, "Invalid matrix version.");
    return nVersion;
end

local function RebuildFunctionMap(nVersion)
    local nSize = GetSizeFromVersion(nVersion);
    local tModules = MakeMatrix(nSize, false);
    local tIsFunction = MakeMatrix(nSize, false);
    DrawFunctionPatterns(tModules, tIsFunction, nVersion);
    return tIsFunction;
end

local function ReadRawCodewords(tMatrix, nVersion, nMask)
    local tModules = Copy2D(tMatrix);
    local tIsFunction = RebuildFunctionMap(nVersion);
    local nSize = #tModules;

    ApplyMask(tModules, tIsFunction, nMask);

    local tBlocks = GetRSBlocks(nVersion, ReadFormatBits(tMatrix));
    local nTotalCodewords = 0;
    for nI = 1, #tBlocks do
        nTotalCodewords = nTotalCodewords + tBlocks[nI].total_count;
    end

    local tBytes = {};
    local nBitIndex = 0;
    local nCol = nSize - 1;
    local bUp = true;
    local nCurrent = 0;

    while nCol >= 1 and #tBytes < nTotalCodewords do
        if nCol == 6 then
            nCol = nCol - 1;
        end

        for nRowOffset = 0, nSize - 1 do
            local nY = bUp and (nSize - 1 - nRowOffset) or nRowOffset;

            for nDX = 0, 1 do
                local nX = nCol - nDX;

                if not tIsFunction[nY + 1][nX + 1] then
                    nCurrent = (nCurrent << 1) | (tModules[nY + 1][nX + 1] and 1 or 0);
                    nBitIndex = nBitIndex + 1;

                    if (nBitIndex % 8) == 0 then
                        tBytes[#tBytes + 1] = nCurrent;
                        nCurrent = 0;

                        if #tBytes >= nTotalCodewords then
                            return tBytes;
                        end
                    end
                end
            end
        end

        bUp = not bUp;
        nCol = nCol - 2;
    end

    return tBytes;
end

local function ExtractDataBytes(tCodewords, nVersion, sECL)
    local tBlocks = GetRSBlocks(nVersion, sECL);
    local tDataBlocks = {};
    local nMaxData = 0;
    local nMaxECC = 0;
    local nIndex = 1;

    for nI = 1, #tBlocks do
        tDataBlocks[nI] = {};
        if tBlocks[nI].data_count > nMaxData then
            nMaxData = tBlocks[nI].data_count;
        end

        local nECC = tBlocks[nI].total_count - tBlocks[nI].data_count;
        if nECC > nMaxECC then
            nMaxECC = nECC;
        end
    end

    for nByteIndex = 1, nMaxData do
        for nBlockIndex = 1, #tBlocks do
            if nByteIndex <= tBlocks[nBlockIndex].data_count then
                tDataBlocks[nBlockIndex][nByteIndex] = tCodewords[nIndex];
                nIndex = nIndex + 1;
            end
        end
    end

    for nByteIndex = 1, nMaxECC do
        for nBlockIndex = 1, #tBlocks do
            local nECC = tBlocks[nBlockIndex].total_count - tBlocks[nBlockIndex].data_count;
            if nByteIndex <= nECC then
                nIndex = nIndex + 1;
            end
        end
    end

    local tData = {};
    for nBlockIndex = 1, #tDataBlocks do
        for nByteIndex = 1, #tDataBlocks[nBlockIndex] do
            tData[#tData + 1] = tDataBlocks[nBlockIndex][nByteIndex];
        end
    end

    return tData;
end

local function MakeBitReader(tBytes)
    local tReader = {
        Bytes = tBytes,
        BitPos = 0,
    };

    tReader.Read = function(this, nCount)
        local nValue = 0;

        for _ = 1, nCount do
            local nByteIndex = (this.BitPos // 8) + 1;
            local nBitIndex = 7 - (this.BitPos % 8);

            Assert(nByteIndex <= #this.Bytes, "Unexpected end of data.");
            nValue = (nValue << 1) | ((this.Bytes[nByteIndex] >> nBitIndex) & 1);

            this.BitPos = this.BitPos + 1;
        end

        return nValue;
    end;

    return tReader;
end

local function DecodePayload(tDataBytes, nVersion)
    local oReader = MakeBitReader(tDataBytes);
    local tOut = {};
    local nMode = oReader:Read(4);

    if nMode == 0 then
        return "", {
            mode = 0,
        };
    end

    local nCharCountBits = GetCharCountBits(nMode, nVersion);
    local nCount = oReader:Read(nCharCountBits);

    if nMode == MODE_NUMERIC then
        while #tOut < nCount do
            local nRemain = nCount - #tOut;

            if nRemain >= 3 then
                local nValue = oReader:Read(10);
                tOut[#tOut + 1] = string.format("%03d", nValue);
            elseif nRemain == 2 then
                local nValue = oReader:Read(7);
                tOut[#tOut + 1] = string.format("%02d", nValue);
            else
                local nValue = oReader:Read(4);
                tOut[#tOut + 1] = tostring(nValue);
            end
        end

        return table.concat(tOut), {
            mode = MODE_NUMERIC,
            length = nCount,
        };
    end

    if nMode == MODE_ALPHANUMERIC then
        local nWritten = 0;

        while nWritten < nCount do
            local nRemain = nCount - nWritten;

            if nRemain >= 2 then
                local nValue = oReader:Read(11);
                local nA = (nValue // 45) + 1;
                local nB = (nValue % 45) + 1;
                tOut[#tOut + 1] = ALPHANUMERIC_MAP:sub(nA, nA);
                tOut[#tOut + 1] = ALPHANUMERIC_MAP:sub(nB, nB);
                nWritten = nWritten + 2;
            else
                local nValue = oReader:Read(6) + 1;
                tOut[#tOut + 1] = ALPHANUMERIC_MAP:sub(nValue, nValue);
                nWritten = nWritten + 1;
            end
        end

        return table.concat(tOut), {
            mode = MODE_ALPHANUMERIC,
            length = nCount,
        };
    end

    if nMode == MODE_BYTE then
        for nI = 1, nCount do
            tOut[nI] = string.char(oReader:Read(8));
        end

        return table.concat(tOut), {
            mode = MODE_BYTE,
            length = nCount,
        };
    end

    error("Unsupported decoded mode.", 3);
end

local function UInt32BE(nValue)
    return string.char(
        (nValue >> 24) & 0xFF,
        (nValue >> 16) & 0xFF,
        (nValue >> 8) & 0xFF,
        nValue & 0xFF
    );
end

local function CRC32Init()
    local tCRC = {};

    for nByte = 0, 255 do
        local nCRC = nByte;

        for _ = 1, 8 do
            if (nCRC & 1) ~= 0 then
                nCRC = 0xEDB88320 ~ (nCRC >> 1);
            else
                nCRC = nCRC >> 1;
            end
        end

        tCRC[nByte] = nCRC;
    end

    return tCRC;
end

local _tCRC32 = CRC32Init();

local function CRC32(sData)
    local nCRC = 0xFFFFFFFF;

    for nIndex = 1, #sData do
        local nByte = sData:byte(nIndex);
        nCRC = _tCRC32[(nCRC ~ nByte) & 0xFF] ~ (nCRC >> 8);
    end

    return (~nCRC) & 0xFFFFFFFF;
end

local function Adler32(sData)
    local nA = 1;
    local nB = 0;

    for nIndex = 1, #sData do
        nA = (nA + sData:byte(nIndex)) % 65521;
        nB = (nB + nA) % 65521;
    end

    return ((nB << 16) | nA) & 0xFFFFFFFF;
end

local function PNGChunk(sType, sData)
    local sChunkData = sType .. sData;
    return UInt32BE(#sData) .. sChunkData .. UInt32BE(CRC32(sChunkData));
end

local function ZlibStore(sData)
    local tOut = {
        string.char(0x78, 0x01), --zlib header
    };

    local nIndex = 1;
    local nLen = #sData;

    while nIndex <= nLen do
        local nBlockLen = math.min(65535, nLen - nIndex + 1);
        local bFinal = (nIndex + nBlockLen - 1) >= nLen;
        local nBFINAL = bFinal and 1 or 0;

        tOut[#tOut + 1] = string.char(nBFINAL);
        tOut[#tOut + 1] = string.char(nBlockLen & 0xFF, (nBlockLen >> 8) & 0xFF);

        local nNLen = (~nBlockLen) & 0xFFFF;
        tOut[#tOut + 1] = string.char(nNLen & 0xFF, (nNLen >> 8) & 0xFF);
        tOut[#tOut + 1] = sData:sub(nIndex, nIndex + nBlockLen - 1);

        nIndex = nIndex + nBlockLen;
    end

    tOut[#tOut + 1] = UInt32BE(Adler32(sData));

    return table.concat(tOut);
end

local function ValidateMatrix(tMatrix, sFuncName)
    local nSize;

    Assert(type(tMatrix) == "table", sFuncName .. ": Argument 1 must be a 2D table.");

    nSize = #tMatrix;
    Assert(nSize > 0, sFuncName .. ": Matrix cannot be empty.");

    for nY = 1, nSize do
        Assert(type(tMatrix[nY]) == "table" and #tMatrix[nY] == nSize, sFuncName .. ": Matrix must be square.");

        for nX = 1, nSize do
            Assert(type(tMatrix[nY][nX]) == "boolean", sFuncName .. ": Matrix entries must be booleans.");
        end
    end

    return nSize;
end

function qr.enc(sData, nVersion, sECL, nMask)
    Assert(type(sData) == "string", "qr.enc: Argument 1 must be a string.");

    if nVersion ~= nil then
        Assert(type(nVersion) == "number" and nVersion >= 1 and nVersion <= 40 and nVersion == math.floor(nVersion), "qr.enc: Argument 2 must be nil or an integer from 1 to 40.");
    end

    sECL = sECL or "M";
    Assert(ECL_FORMAT_BITS[sECL] ~= nil, "qr.enc: Argument 3 must be nil or one of 'L', 'M', 'Q', 'H'.");

    if nMask ~= nil then
        Assert(type(nMask) == "number" and nMask >= 0 and nMask <= 7 and nMask == math.floor(nMask), "qr.enc: Argument 4 must be nil or an integer from 0 to 7.");
    end

    local tMatrix = BuildQR(sData, nVersion, sECL, nMask);
    return tMatrix;
end

function qr.dec(tMatrix)
    Assert(type(tMatrix) == "table", "qr.dec: Argument 1 must be a 2D table.");

    local nSize = #tMatrix;
    Assert(nSize > 0, "qr.dec: Matrix cannot be empty.");

    for nY = 1, nSize do
        Assert(type(tMatrix[nY]) == "table" and #tMatrix[nY] == nSize, "qr.dec: Matrix must be square.");

        for nX = 1, nSize do
            Assert(type(tMatrix[nY][nX]) == "boolean", "qr.dec: Matrix entries must be booleans.");
        end
    end

    local nVersion = GetVersionFromMatrix(tMatrix);
    local sECL, nMask = ReadFormatBits(tMatrix);
    local tCodewords = ReadRawCodewords(tMatrix, nVersion, nMask);
    local tDataBytes = ExtractDataBytes(tCodewords, nVersion, sECL);
    local sData = DecodePayload(tDataBytes, nVersion);

    return sData;
end

function qr.ascii(tMatrix, sDark, sLight, nBorder)
    local nSize;

    if type(tMatrix) ~= "table" then
        error("qr.ascii: Argument 1 must be a 2D table.", 2);
    end

    nSize = #tMatrix;
    if nSize == 0 then
        error("qr.ascii: Matrix cannot be empty.", 2);
    end

    for nY = 1, nSize do
        if type(tMatrix[nY]) ~= "table" or #tMatrix[nY] ~= nSize then
            error("qr.ascii: Matrix must be square.", 2);
        end

        for nX = 1, nSize do
            if type(tMatrix[nY][nX]) ~= "boolean" then
                error("qr.ascii: Matrix entries must be booleans.", 2);
            end
        end
    end

    sDark   = sDark or "##";
    sLight  = sLight or "  ";
    nBorder = nBorder == nil and 4 or nBorder;

    if type(sDark) ~= "string" then
        error("qr.ascii: Argument 2 must be nil or a string.", 2);
    end

    if type(sLight) ~= "string" then
        error("qr.ascii: Argument 3 must be nil or a string.", 2);
    end

    if type(nBorder) ~= "number" or nBorder < 0 or nBorder ~= math.floor(nBorder) then
        error("qr.ascii: Argument 4 must be nil or a non-negative integer.", 2);
    end

    local tLines = {};
    local nFullSize = nSize + (nBorder * 2);
    local sBorderLine = sLight:rep(nFullSize);

    for _ = 1, nBorder do
        tLines[#tLines + 1] = sBorderLine;
    end

    for nY = 1, nSize do
        local tLine = {};

        for _ = 1, nBorder do
            tLine[#tLine + 1] = sLight;
        end

        for nX = 1, nSize do
            tLine[#tLine + 1] = tMatrix[nY][nX] and sDark or sLight;
        end

        for _ = 1, nBorder do
            tLine[#tLine + 1] = sLight;
        end

        tLines[#tLines + 1] = table.concat(tLine);
    end

    for _ = 1, nBorder do
        tLines[#tLines + 1] = sBorderLine;
    end

    return table.concat(tLines, "\n");
end

function qr.png(tMatrix, sFilePath, nScale, nBorder)
    local nMatrixSize;
    local nImageSize;
    local tRows;
    local sRaster;
    local sPNG;
    local hFile;

    nMatrixSize = ValidateMatrix(tMatrix, "qr.png");

    Assert(type(sFilePath) == "string" and sFilePath:match("%S") ~= nil, "qr.png: Argument 2 must be a non-blank string.");

    nScale = nScale or 8;
    nBorder = nBorder == nil and 4 or nBorder;

    Assert(type(nScale) == "number" and nScale == math.floor(nScale) and nScale > 0, "qr.png: Argument 3 must be nil or a positive integer.");
    Assert(type(nBorder) == "number" and nBorder == math.floor(nBorder) and nBorder >= 0, "qr.png: Argument 4 must be nil or a non-negative integer.");

    nImageSize = (nMatrixSize + (nBorder * 2)) * nScale;
    tRows = {};

    for nY = 1, nImageSize do
        local tRow = {string.char(0)}; --filter type 0
        local nModuleY = math.floor((nY - 1) / nScale) - nBorder + 1;

        for nX = 1, nImageSize do
            local nModuleX = math.floor((nX - 1) / nScale) - nBorder + 1;
            local bDark = false;

            if nModuleY >= 1 and nModuleY <= nMatrixSize and nModuleX >= 1 and nModuleX <= nMatrixSize then
                bDark = tMatrix[nModuleY][nModuleX];
            end

            tRow[#tRow + 1] = bDark and string.char(0) or string.char(255);
        end

        tRows[#tRows + 1] = table.concat(tRow);
    end

    sRaster = table.concat(tRows);

    sPNG =
        "\137PNG\r\n\26\n" ..
        PNGChunk("IHDR", UInt32BE(nImageSize) .. UInt32BE(nImageSize) .. string.char(8, 0, 0, 0, 0)) ..
        PNGChunk("IDAT", ZlibStore(sRaster)) ..
        PNGChunk("IEND", "");

    hFile = assert(io.open(sFilePath, "wb"));
    hFile:write(sPNG);
    hFile:close();

    return true;
end


local tQRDecoy  = {};
local tQRMeta   = {
    __index = qr,
};

setmetatable(tQRDecoy, tQRMeta);

return tQRDecoy;
