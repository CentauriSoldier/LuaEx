# LXC maintenance rules

1. Obtain explicit user permission and edit only authorized files.
2. Inspect affected framework services before changes; state understanding gaps.
3. Preserve encapsulation, inheritance and polymorphism. Debug attacks are outside
   scope; do not introduce native dependencies or thread proxies.
4. Use focused modules/functions, meaningful DOx documentation and local comments.
   Follow README naming/spacing; only nested local functions receive an f prefix.
   Keep opening braces on declaration lines.
5. Enums initialize before classes. Require within for class-owned declarations;
   do not add enum declarations to an already initialized class.
6. Reuse existing serializer, canonical enum registry, lexical access checks and
   graph validation. Validate static restore plans before committing assignments.
7. Preserve the boundary between compile-time checking and runtime work. The
   deferred directive design adds no per-read/write/call directive checks.
8. Update design, keywords and rules when changes are agreed. Do not treat
   proposals, planned editor features, or unverified tests as implemented.
9. Ignore lxc-prototype and deprecated checkouts. Do not overwrite legacy archives.
10. See CoG/HANDOFF.md and ../HANDOFF.md for current migration progress.

## Permission and scope

- Obtain explicit permission before edits; work only within the permitted scope.
- Historical repair permissions do not grant edit permission for new work.
  Obtain explicit, file-specific permission before changes.
- Preserve unrelated user work. A difference from Git history is not permission
  to overwrite it. Cleanup means identified obsolete/generated project files,
  never broad deletion of unknown files.
- Read framework context before LuaEx-related changes. Do not claim complete
  understanding of the entire framework without evidence. Disclose relevant gaps
  and resolve necessary questions before dependent changes.

## Design authority

- Follow the consolidated agreed contracts in DESIGN.md. Historical implementation
  authorization is not permission for new changes.
- Resolve new material semantic questions with the owner before implementing the
  dependent behavior. Continue independent work when possible.
- Automatically update DESIGN.md and these rules whenever an agreed change makes
  an update necessary. Keep KEYWORDS.md, README.md and examples consistent too.
- Record only agreed decisions as requirements. Distinguish proposals and technical
  findings; silence, prototype behavior and C# conventions do not establish agreement.
- Use C# as a guide and POLA for consistency. Do not introduce speculative features
  or silently reinterpret a requirement to fit implementation convenience.

## OOP and access

- Enforce encapsulation, inheritance and polymorphism correctly WITHOUT EXCEPTION.
- The debug library is the sole agreed intrusion exception. Raw operations,
  metatables, environments, helpers, serialization and escaped references remain
  in scope. Do not create undocumented exceptions for deliberate bypass attempts.
- Preserve declaring-class rights, cross-instance access, nested access direction,
  use-site class visibility and all inheritance/override/storage contracts.
- External callbacks must not borrow privileges, including after tail calls.
  Compiled closures retain legitimate lexical context. Coroutines and errors must
  not leak scope. Retained Lua 5.4 frames in the runtime are intentional protection.
- Never expose internal registries, lexical views, backing-storage handles or
  compiler environments through a public helper or ordinary returned value.
- Use empty Lua table decoys with hidden storage. Do not add native allocators,
  thread handles, compiler dependencies or speculative raw-operation guards.
  Raw entries can shadow public lookup; test and disclose the actual consequences
  while preserving hidden state. Do not describe decoys as rejecting raw writes.
- Internal identity checks must not invoke user equality. Recognize registered
  decoys before generic-table traversal, including subsequent runtime bootstrap.
- Treat persistence as explicitly granted host authority; it is not an ambient
  script global. Document private-data export and test hidden-reference denial.
- Do not trade an OOP pillar for performance. Disclose obstacles honestly and
  resolve them; never claim exhaustive protection from a finite test suite.

## Organization and style

- Prefer five clear files over one unclear file, and three focused functions over
  one function doing three jobs. Each boundary must improve understanding.
- Keep scanning, parsing, resolution, validation, runtime mutation, persistence
  and diagnostics separate. Keep dependencies explicit and documented.
- Follow the authoritative README's naming conventions. Nested local functions
  use an f prefix; file-scoped functions, module functions and class methods do not.
  Exported module tables use PascalCase. Variables use meaningful type prefixes;
  file-scoped private variables also use the documented underscore prefix.
- Maintain readable spacing, indentation, statement terminators and breathing room.
  Avoid compressed multi-purpose logic and mechanical splitting without purpose.
- Use DOx documentation at module/function boundaries and meaningful local comments
  for invariants, ordering and unusual decisions. Readers should understand each
  function's purpose before reading its body.
- Do not add legacy cdat/super parameters to LXC just to imitate old implementation.
  Use this, base, other and property bindings for their defined roles.

## Verification and delivery

- Test meaningful positive/negative contracts, including non-debug intrusion paths.
  Successful examples alone do not establish correctness.
- Keep fixtures and generated artifacts within the explicitly authorized test scope.
  Tests must not modify unrelated framework files or projects.
- Run relevant standalone and real LuaEx discovery checks using a verified Lua 5.4
  host. Run benchmarks when relevant; report actual results and limitations.
  Prototype runner paths require repair before those historical commands can be used.
- Validate before publication/restoration. Reject unsupported forms explicitly and
  provide useful source/declaration diagnostics.
- Avoid automatic call-time method argument/return checks; validate override signatures
  at compilation and enforce field typing on storage operations.
- Keep table.lock separate from this build. Interfaces remain excluded; do not add
  new keywords, operator syntax or abstract property contracts without agreement.
- Delete obsolete checkpoint artifacts only with explicit permission after their
  useful contracts are covered by maintained tests/docs. Keep the design, rules,
  keyword reference, architecture, examples, test runner and reproducible benchmarks.
