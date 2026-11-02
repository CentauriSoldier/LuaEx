--[[!
@fqxn LuaEx.SourceDiscovery
@desc Single authority for discovering declaration files. One scan combines
    package-path roots and optional framework roots, using native multi-root I/O
    with shared cycle/alias protection. Results are sorted snapshots, never a
    permanent cache: later calls see new or removed files. Parsing/loading remain
    owned by LXC and LXE. This module does not load or execute discovered files.
!]]
local _io       = io;
local _assert   = assert;
local _type     = rawget(_G, "rawtype") or type;
local _ipairs   = ipairs;
local _pairs    = pairs;
local _gmatch   = string.gmatch;
local _gsub     = string.gsub;
local _match    = string.match;
local _lower    = string.lower;
local _sub      = string.sub;
local _sort     = table.sort;
local _unpack   = table.unpack;
local SourceDiscovery = {};

-- Only this whitelist declares which source-file types discovery approves.
local _tApproved = {"lxc", "lxe"};

--[[!
@fqxn LuaEx.SourceDiscovery.scan
@desc Extracts roots from ? templates, adds explicit roots, then scans once for
    every approved extension. Optional missing roots are ignored by io.scanfiles;
    real traversal errors fail without returning a partial result. String helpers
    are captured so application string replacements do not alter discovery.
@param string|nil sPackagePath Templates; nil uses package.path.
@param table|nil tExtraRoots Additional directory roots in a dense array.
@ret table tSnapshot Files is the sorted union; ByExtension contains the sorted
    lxc/lxe arrays; Roots maps supplied paths to canonical directories. Directories
    is the number of distinct directories enumerated, including through links.
!]]
function SourceDiscovery.scan(sPackagePath, tExtraRoots)
    local tRoots, tSeen = {}, {};
    local tResult = {Files = {}, ByExtension = {}};
    sPackagePath = sPackagePath == nil and package.path or sPackagePath;
    _assert(_type(sPackagePath) == "string", "Discovery package path must be a string.");
    _assert(_type(_io.scanfiles) == "function", "Source discovery requires io.scanfiles.");
    for sTemplate in _gmatch(sPackagePath, "[^;]+") do
        local sPrefix = _match(sTemplate, "^(.-)%?");
        if (sPrefix) then
            local pRoot = _match(sPrefix, "^(.*)[/\\]") or ".";
            if (pRoot == "") then pRoot = _sub(sPrefix, 1, 1); end
            if (not tSeen[pRoot]) then tSeen[pRoot] = true; tRoots[#tRoots + 1] = pRoot; end
        end
    end
    if (tExtraRoots ~= nil) then
        _assert(_type(tExtraRoots) == "table" and getmetatable(tExtraRoots) == nil, "Extra discovery roots must be a plain array.");
        local nCount = 0;
        for nIndex, pRoot in _pairs(tExtraRoots) do
            _assert(_type(nIndex) == "number" and nIndex % 1 == 0 and nIndex >= 1 and nIndex <= #tExtraRoots and
                _type(pRoot) == "string" and pRoot ~= "", "Invalid extra discovery root.");
            nCount = nCount + 1;
        end
        _assert(nCount == #tExtraRoots, "Extra discovery roots must be dense.");
        for _, pRoot in _ipairs(tExtraRoots) do
            if (not tSeen[pRoot]) then tSeen[pRoot] = true; tRoots[#tRoots + 1] = pRoot; end
        end
    end
    local tFiles, sReason, tScan = _io.scanfiles(tRoots, _unpack(_tApproved));
    _assert(tFiles, sReason);
    local tFileKeys = {};
    for _, sType in _ipairs(_tApproved) do tResult.ByExtension[sType] = {}; end
    for _, pFile in _ipairs(tFiles) do
        local sType = _lower(_match(pFile, "%.([^./\\]+)$") or "");
        local tBucket = tResult.ByExtension[sType];
        local sKey = _gsub(pFile, "\\", "/");
        if (_sub(package.config, 1, 1) == "\\") then sKey = _lower(sKey); end
        if (tBucket and not tFileKeys[sKey]) then
            tFileKeys[sKey] = true;
            tResult.Files[#tResult.Files + 1] = pFile;
            tBucket[#tBucket + 1] = pFile;
        end
    end
    _sort(tResult.Files);
    for _, tBucket in _pairs(tResult.ByExtension) do _sort(tBucket); end
    tResult.Roots, tResult.Directories = tScan.Roots, tScan.Directories;
    return tResult;
end

return SourceDiscovery;
