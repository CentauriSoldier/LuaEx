# Class helper availability during initialization

User direction — November 1, 2026:

Do not make helper functions available before their supporting runtime state is ready for them to be used correctly. Review and define helper availability during declaration discovery, static initialization and publication. Preserve encapsulation, inheritance, polymorphism and scope enforcement.

Verified issue:

- During static construction in a coordinated loading batch, class.is, class.exists and class.ischild accepted a class reference and confirmed its CoGBase ancestry.
- class.getparentname returned CoG.CoGBase, but class.getbyname could not resolve that name before the batch was published.
- The same name-based traversal succeeded after discovery/publication completed.
- Factorium used that traversal while registering Spell from its static constructor, so registration failed despite valid inheritance.

Pending LuaEx work: review which helpers depend on publication and prevent them from being exposed as usable before their prerequisite state is ready. Do not introduce an unverified parent-reference helper or weaken access checks to bypass the lifecycle issue.

This is a recorded requirement and reproduction, not an implemented LuaEx change. Factorium registration timing is being addressed separately.