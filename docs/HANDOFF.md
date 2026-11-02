# Current framework and migration handoff — 2026-10-29

Read C:/Users/james.jones/Sync/Projects/CoG/HANDOFF.md first. It records the
authoritative paths, user rules, completed CoG enum changes, tests, remaining
disabled modules and exact next steps.

Current class docs are docs/lxc/DESIGN.md, KEYWORDS.md and RULES.md.
Current enum docs are docs/lxe/DESIGN.md, KEYWORDS.md and RULES.md.
Ignore lxc-prototype and the deprecated Documents/GitHub checkout.

The latest completed step migrated enabled CoG enums to LXE and updated the
Pulsar source/installed package/ZIP. Rarity uses I–VI with configured NAME labels.
Next work is the unfinished CoG module migration, particularly StatusTracker's
old class and late-config category builder, before Dox.

Enums initialize before classes; no late class attachment. Canonical enum field
typing and host static persistence are implemented. Directives, hover and
signature help remain deferred. See the CoG handoff for tested and unverified
paths; do not claim the full Pulsar subprocess suite or live editor was verified.
