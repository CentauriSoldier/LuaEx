--[[!
    @fqxn CoG.Config
    @pulsarlua table luaex.cog.config
    @desc <p>These settings (assembled by <strong><em>LuaEx/inc/cog/config.lua</em></strong>) are for the user to edit in the adjacent config folder (pre-runtime).
    <br>It is available at runtime by accessing the global variable: <strong><em>luaex.cog.config</strong></em>
    <br><br>It (and any subtables it contains) are read-only at runtime, preventing potential issues of unexpected data changes.
    <br>It's designed to allow configurability in CoG classes and user classes that may need different data from one project to the next.
    <br><strong>Note</strong>: existing subtables should not be removed or renamed but the values can be changed before runtime.
    <br>More sections may be added by creating a file in the config folder and adding its require entry below.
    </p>
!]]
-- require supplies this module name, so child modules share its package path.
local _sConfigModule = ...; -- LuaEx.inc.cog.config

-- List every configuration section explicitly; no filesystem scan is needed.
local tConfig = {--TODO basic things like units of measurement
    app           = require(_sConfigModule..".app"),
    AStar         = require(_sConfigModule..".AStar"),
    Pool          = require(_sConfigModule..".Pool"),
    BaseObject    = require(_sConfigModule..".BaseObject"),
    BaseVehicle   = require(_sConfigModule..".BaseVehicle"),
    BaseMod       = require(_sConfigModule..".BaseMod"),
    Rarity        = require(_sConfigModule..".Rarity"),
    StatusSystem  = require(_sConfigModule..".StatusSystem"),
};

-- Lock the assembled settings once, including every nested table.
return table.readonly(tConfig);
