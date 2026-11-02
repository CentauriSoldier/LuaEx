# LXE keywords and reserved names

This inventory describes the initial LXE declaration implementation.

## Declaration keywords

| Keyword | Purpose |
| --- | --- |
| namespace | Groups declarations under qualified names, following LXC. |
| using | Makes names available for resolution under LXC-consistent rules; does not execute an import. |
| requires | Declaration-level dependency clause: requires(Fully.Qualified.Name). Dependencies precede dependents. |
| enum | Declares a root enum. Nested member blocks declare embedded enums. |
| within | Explicitly names the owning class in standalone or inline enum declarations; replaces the proposed for clause. |
| public, protected, private | Control class-owned enum accessibility through LXC rules. |
| extension | Declares EnumName.customMethodName in the same file as its target enum, at file, namespace, or class declaration scope; may precede or follow the target. |
| this | Explicit extension receiver parameter, representing a member of the named enum. |

Lua keywords retain their ordinary meanings inside extension bodies. Other LXC keywords do not automatically become valid enum modifiers.

## Reserved member metadata

| Name | Meaning |
| --- | --- |
| Value | Explicit payload, otherwise the one-based declaration ordinal. |
| Ordinal | One-based declaration position within the immediate parent. |
| Name | Declaration name. |
| Parent | Immediate owning enum for a member; LuaEx null for a root enum. |

Value, Ordinal, Name, and Parent cannot be used as member or extension names. Shared helpers are lxe.getByName, lxe.getByValue, lxe.isMember, and lxe.isEnum; they are API names rather than declaration keywords.

## Declaration punctuation

- A member may end with a semicolon.
- = introduces an explicit value.
- A member's brace-delimited block contains its embedded enum members.
- A dotted extension name identifies the target enum followed by the custom method name.
- Parenthesized requires lists use fully qualified names, following LXC.

Explicit payload expressions may produce any Lua value except nil. False is valid; omission uses the ordinal default. The expression environment and evaluation order are specified in DESIGN.md. The complete expression grammar and additional punctuation rules still require precise implementation documentation.






