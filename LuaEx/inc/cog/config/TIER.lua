--[[!
@fqxn CoG.Config.TIER
@pulsarlua enum luaex.cog.config.TIER
@desc Default tier enum: twenty Roman-numeral members with numeric ordinal values.
      This private enum is stored in CoG configuration rather than the global
      environment. A project's config table may replace TIER with its own enum.
      Access members through luaex.cog.config.TIER.I; id is their one-based ordinal.
      Member payloads may be numbers, tables or nested enums. Framework tier
      ordering uses member ids and does not depend on numeric payloads.
!]]
return enum("TIER", {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
    "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"}, nil, true);
