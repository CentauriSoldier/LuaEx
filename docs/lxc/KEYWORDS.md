# LXC keywords: current embedded system

- Structure: namespace, class.
- Name resolution and dependencies: using, requires.
- Inheritance restrictions: permits, excludes.
- Visibility: public, protected, private.
- Member/class modifiers: static, const, final, abstract, override.
- Class body context: this, base, operator.
- Property accessors: get, set; custom accessor bodies use field and value.
- Null sentinel: null.
- Enum integration: enum, extension, within.

requires uses parenthesized fully qualified dependency names. within names the
owning class explicitly; it is not inheritance. extension targets Enum.method,
with explicit this as its first parameter. It may appear before or after its
enum at file, namespace or class declaration scope. A separate file in the same
batch may declare an extension using its target enum's FQN. No extension within
clause is needed.

Structured comment directives are not keywords: `---@type T` / `T?` annotate
fields/properties; `---@default` marks a replaceable class, enum or extension.
See ../directives.md for completion boundaries and duplicate selection rules.

Value, Ordinal, Name and Parent are enum metadata names, not Lua keywords.
Lua control-flow keywords keep ordinary Lua meanings in executable bodies.

Keyword spelling does not imply every modifier applies to every declaration:
Validation and the LXE parser enforce the actual permitted combinations.
