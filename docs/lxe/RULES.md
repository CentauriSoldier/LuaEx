# LXE implementation rules

1. Edit only explicitly authorized files. Executable work in the approved LXE, tests, LuaEx loader and necessary LXC integration scope has been authorized. HostStaged.lua was additionally approved for persistence access checks.
2. Prioritize correctness over speed. Inspect affected framework behavior before changes; state understanding gaps honestly.
3. Update DESIGN.md, KEYWORDS.md, and these rules when the user agrees to a change. Do not treat proposals as decisions.
4. Keep functions and modules focused, readable, and clearly documented. Prefer several clear functions or files to one overloaded implementation.
5. Follow the LuaEx README naming and whitespace conventions. File-scoped/module functions have no f prefix; functions nested inside other functions do. Keep opening braces on declaration lines.
6. Document code with DOx comments and meaningful local explanations. Explain responsibilities, inputs, outputs, errors, and non-obvious invariants.
7. Preserve encapsulation and canonical identity. Embedded enum membership is not inheritance. Do not weaken LXC's encapsulation, inheritance, or polymorphism.
8. Use portable Lua. Do not add native modules or thread representations to solve table access or operator concerns. Debug-library attacks are outside scope.
9. Keep LXE enum semantics separate from LXC class semantics. Necessary LXC parsing/loading integration for class-owned and inline enums is approved. Require within for explicit class ownership in either file form. Use existing generic persistence protocols; request approval before changes outside the approved scope.
10. Validate a complete batch before publication. Parsing and structural validation must not execute application bodies or payload expressions. Evaluate payload expressions during loading, validate results before publication, and do not claim their arbitrary external side effects can be rolled back.
11. Add no speculative features, implicit enum reparenting, compatibility formats, or extension inheritance. Extension declarations may use separate files in their target enum's complete loading batch; retain exact receiver membership and lexical access rules.
12. Keep load-time checks out of hot runtime paths where possible. Select @default declarations before semantic validation and initialization. Add no per-read/write/call directive checks or enum @type enforcement.
13. Test observable behavior: nesting and immediate-parent types, values/ordinals, duplicate/collision failures, extensions, dependencies/cycles, failed-batch isolation, incremental loading, operators, and clone/save/load identity.
14. Test loader integration and existing framework regressions after integration. Do not claim portable-host verification beyond hosts actually tested.
15. Keep tests and fixtures outside production modules. Remove only task-created temporary junk; never delete unrelated user files.
16. Give concise progress updates while working. Report results, limitations, and outstanding decisions accurately.




17. Enums initialize before classes. A class-owned enum must exist when its class initializes; never attach a new enum declaration to an already initialized class. Assigning an existing enum value to an eligible field later is allowed under normal LXC typing rules.
18. Static enum persistence uses the existing host serializer bridge and existing LXC visibility/type/lock checks. Validate all static-field updates before committing them. Do not introduce a separate enum-specific static format or weaken private/protected access.
