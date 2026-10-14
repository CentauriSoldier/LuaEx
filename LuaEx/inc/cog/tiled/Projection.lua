--[[!
    @fqxn CoG.Tiled.Helpers.Projection
    @desc Converts native, zero-based Tiled cell coordinates to displayed pixels.
    Covers orthogonal, isometric, staggered, hexagonal and oblique map grids.
    Pixel coordinates here are displayed map coordinates, not TMX object coordinates.
!]]
local Projection = {};


--[[!
    @fqxn CoG.Tiled.Helpers.Projection.geometry
    @desc Mirrors Tiled's integer side-offset calculation. Odd tile dimensions can lose
    one pixel in the staggered grid footprint; image dimensions remain unchanged.
    @ret number nWidth Grid footprint width.
    @ret number nHeight Grid footprint height.
    @ret number nSide Hex side length, or zero for staggered diamonds.
!]]
local function geometry(tMap)

    local nSide = tMap.orientation == "hexagonal" and tMap.hexsidelength or 0;
    local nSideX = tMap.staggeraxis == "x" and nSide or 0;
    local nSideY = tMap.staggeraxis == "y" and nSide or 0;
    local nWidth = 2 * math.floor((tMap.tilewidth - nSideX) / 2) + nSideX;
    local nHeight = 2 * math.floor((tMap.tileheight - nSideY) / 2) + nSideY;
    assert(nWidth > 0 and nHeight > 0, "Tiled staggered grid has no pixel area.");
    return nWidth, nHeight, nSide;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Projection.origin
    @desc Gets the top-left bounding-box corner of a staggered cell.
    @param table tMap Parsed map attributes.
    @param number nX Native column, including negative columns.
    @param number nY Native row, including negative rows.
    @ret number nPixelX Horizontal pixel position.
    @ret number nPixelY Vertical pixel position.
!]]
local function origin(tMap, nX, nY)

    local nWidth, nHeight, nSide = geometry(tMap);
    local nParity = tMap.staggerindex == "odd" and 1 or 0;

    -- Stagger parity is based on native coordinates, never array offsets.
    if (tMap.staggeraxis == "x") then
        local nShift = nX % 2 == nParity and nHeight / 2 or 0;
        return nX * (nWidth + nSide) / 2, nY * nHeight + nShift;
    end

    local nShift = nY % 2 == nParity and nWidth / 2 or 0;
    return nX * nWidth + nShift, nY * (nHeight + nSide) / 2;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Projection.tileToPixel
    @desc Gets a cell's displayed center. This common anchor works for all orientations.
    @param table tMap Parsed map attributes.
    @param number nX Native column.
    @param number nY Native row.
    @ret number nPixelX Cell center x.
    @ret number nPixelY Cell center y.
!]]
function Projection.tileToPixel(tMap, nX, nY)

    local nWidth = tMap.tilewidth;
    local nHeight = tMap.tileheight;

    if (tMap.orientation == "isometric") then
        -- Tiled anchors the first diamond's top vertex at height * width / 2.
        return (nX - nY) * nWidth / 2 + tMap.height * nWidth / 2,
               (nX + nY + 1) * nHeight / 2;
    end

    if (tMap.orientation == "hexagonal" or tMap.orientation == "staggered") then
        local nLeft, nTop = origin(tMap, nX, nY);
        nWidth, nHeight = geometry(tMap);
        return nLeft + nWidth / 2, nTop + nHeight / 2;
    end

    -- Oblique maps shear the rectangular grid without changing its topology.
    local nSkewX = tMap.orientation == "oblique" and tMap.skewx or 0;
    local nSkewY = tMap.orientation == "oblique" and tMap.skewy or 0;
    return (nX + 0.5) * nWidth + (nY + 0.5) * nSkewX,
           (nY + 0.5) * nHeight + (nX + 0.5) * nSkewY;
end


--[[!
    @fqxn CoG.Tiled.Helpers.Projection.pixelToTile
    @desc Locates the cell containing a displayed pixel, including outside finite bounds.
    Shared polygon edges use deterministic column/row iteration order.
    @param table tMap Parsed map attributes.
    @param number nPixelX Displayed x.
    @param number nPixelY Displayed y.
    @ret number nX Native column.
    @ret number nY Native row.
!]]
function Projection.pixelToTile(tMap, nPixelX, nPixelY)

    local nWidth = tMap.tilewidth;
    local nHeight = tMap.tileheight;

    if (tMap.orientation == "isometric") then
        local nX = (nPixelX - tMap.height * nWidth / 2) / nWidth;
        local nY = nPixelY / nHeight;
        return math.floor(nY + nX), math.floor(nY - nX);
    end

    if (tMap.orientation ~= "hexagonal" and tMap.orientation ~= "staggered") then
        local nSkewX = tMap.orientation == "oblique" and tMap.skewx or 0;
        local nSkewY = tMap.orientation == "oblique" and tMap.skewy or 0;
        local nDeterminant = nWidth * nHeight - nSkewX * nSkewY;
        assert(nDeterminant ~= 0, "Tiled oblique projection is singular.");

        -- Invert the grid basis before selecting the containing rectangle.
        return math.floor((nPixelX * nHeight - nPixelY * nSkewX) / nDeterminant),
               math.floor((nPixelY * nWidth - nPixelX * nSkewY) / nDeterminant);
    end

    local nSide;
    nWidth, nHeight, nSide = geometry(tMap);
    local bAxisX = tMap.staggeraxis == "x";
    local nStepX = bAxisX and (nWidth + nSide) / 2 or nWidth;
    local nStepY = bAxisX and nHeight or (nHeight + nSide) / 2;
    local nGuessX = math.floor(nPixelX / nStepX);
    local nGuessY = math.floor(nPixelY / nStepY);

    -- Test nearby polygon footprints. Bounding-box tests alone select the wrong
    -- cell at clipped hex corners and staggered diamond corners.
    for nX = nGuessX - 2, nGuessX + 2 do
        for nY = nGuessY - 2, nGuessY + 2 do
            local nLeft, nTop = origin(tMap, nX, nY);
            local nDX = math.abs(nPixelX - nLeft - nWidth / 2);
            local nDY = math.abs(nPixelY - nTop - nHeight / 2);
            local bInside = nDX <= nWidth / 2 and nDY <= nHeight / 2;

            if (bInside and bAxisX) then
                local nCorner = (nWidth - nSide) / 2;
                bInside = nCorner == 0 or nDX <= nSide / 2 + nCorner * (1 - 2 * nDY / nHeight);
            elseif (bInside) then
                local nCorner = (nHeight - nSide) / 2;
                bInside = nCorner == 0 or nDY <= nSide / 2 + nCorner * (1 - 2 * nDX / nWidth);
            end

            if (bInside) then
                return nX, nY;
            end
        end
    end

    error("Unable to locate a cell in the Tiled grid.");
end

return Projection;
