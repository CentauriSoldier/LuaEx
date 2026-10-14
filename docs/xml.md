# XML

`XML` is a generic class loaded by `LuaEx.init` from `LuaEx/inc/classes/XML.lua`.
It has no map, tileset, custom-property or other application-specific semantics.

```lua
local document = XML('<catalog><entry name="example">Some text</entry></catalog>')
local root = document.getRoot()
local entries = document.getElements("entry")
print(entries[1].attributes.name, entries[1].content[1])

document.load("data/catalog.xml")
local copy = clone(document)
local restored = deserialize(serialize(document))
```

Public methods use dot calls and are alphabetically ordered. `XML()` creates an
unloaded object; supplying text parses immediately. `parse(source)` and `load(path)`
replace state only after complete success. They return the object for chaining.
Invalid input raises a line/column diagnostic and leaves prior state intact.

`getRoot()` returns a copied element or nil before parsing. `getElements(name)`
returns matching elements in depth-first document order, including the root if
it matches; nil selects all elements. `getDocument()` includes top-level ordered
content and declaration metadata. Query results are independent copies, retaining
shared references within a returned graph. Editing them does not edit the document.

Element records contain `kind="element"`, `name`, `attributes`, `children` and
`content`. Attributes are strings. Children contain only element records; content
preserves text and markup order. Adjacent text and CDATA are coalesced into strings.
Comments contain `kind="comment"` and `text`; processing instructions contain
`kind="processingInstruction"`, `name` and `text`.

Supported input is the UTF-8 XML 1.0 subset with Unicode names, quoted attributes,
empty elements, nested elements, comments, processing instructions, CDATA,
predefined entities and decimal/hexadecimal character references. Physical CR/CRLF
line endings normalize to LF in parsed content. Attribute literal whitespace
normalizes to spaces; character references preserve their referenced characters.

Qualified names remain literal. Namespace resolution, DTD processing, custom or
external entities, alternate encodings and schema validation are not implemented.
Unsupported declarations/encodings fail explicitly. This is a documented subset,
not a claim of full validating XML-processor conformance.

`getSource()` and `tostring(document)` return the original source, retaining its
formatting and optional BOM. Native LuaEx serialization stores source and rebuilds
the parsed cache during restoration. No serializer is provided to generate changed
XML from edited query results.

The grammar and character rules follow the
[XML 1.0 specification](https://www.w3.org/TR/xml/).
Run `examples/api/node/node.exe examples/api/workbench/verify-xml.cjs` from the
repository root to exercise parsing, invalid-input handling, copying and persistence.
