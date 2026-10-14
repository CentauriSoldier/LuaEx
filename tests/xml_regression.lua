local sSource = [=[<?xml version="1.0" encoding="UTF-8"?>
<!-- map metadata -->
<map version="1.10" tiledversion="1.12.2" width="2" height="1">
    <properties>
        <property name="health" type="int" value="100"/>
        <property name="message" type="string">A &amp; B &#x1F409;</property>
        <property name="body"><![CDATA[<tag>&literal]]></property>
    </properties>
    <layer><data encoding="csv">1,2</data></layer>
</map>]=];
local oXML = XML(sSource);
assert(class.of(oXML) == XML and oXML.getRoot().name == "map");
assert(oXML.getSource() == sSource and tostring(oXML) == sSource);
local tProperties = oXML.getElements("property");
assert(#tProperties == 3);
assert(tProperties[1].attributes.type == "int" and tProperties[1].attributes.value == "100");
assert(tProperties[2].content[1] == "A & B 🐉");
assert(tProperties[3].content[1] == "<tag>&literal");
assert(oXML.getDocument().declaration.encoding == "UTF-8");
tProperties[1].attributes.value = "changed";
assert(oXML.getElements("property")[1].attributes.value == "100");
local tRoot = oXML.getRoot();
tRoot.children[1].name = "changed";
assert(oXML.getRoot().children[1].name == "properties");
local oMixed = XML('<p>before<b q="x > y">bold</b>after<!-- note --><?test value?></p>');
local tMixed = oMixed.getRoot();
assert(tMixed.content[1] == "before" and tMixed.content[2].name == "b");
assert(tMixed.content[3] == "after" and tMixed.content[4].kind == "comment");
assert(tMixed.content[5].kind == "processingInstruction");
assert(tMixed.children[1] == tMixed.content[2]);
assert(XML('<é:root xmlns:é="urn:test" é:a="&#10;\t"/>').getRoot().attributes["é:a"] == "\n ");
assert(XML('\239\187\191<?xml version="1.0"?><root/>').getRoot().name == "root");
assert(XML('<root>a\r\nb\rc</root>').getRoot().content[1] == "a\nb\nc");

local tInvalid = {
    "", "plain text", "<a>", "<a></b>", "<a/><b/>", "<a>]]></a>",
    '<a x="1" x="2"/>', '<a x="unclosed/>', '<a x="<"/>', '<a x=1/>',
    '<a x="1"y="2"/>', "<1bad/>", "<a>&unknown;</a>", "<a>&amp</a>",
    "<a>&#0;</a>", "<a>&#xD800;</a>", "<a>&#x110000;</a>",
    "<a><!--bad--comment--></a>", "<a><![CDATA[unclosed</a>",
    "<!DOCTYPE a SYSTEM 'external.dtd'><a/>", "<a/>trailing", "<![CDATA[x]]><a/>",
    '<?xml encoding="UTF-8"?><a/>', '<?xml version="1.1"?><a/>',
    '<?xml version="1.0" encoding="UTF-16"?><a/>',
    '<?xml version="&#49;.0"?><a/>', ' <?xml version="1.0"?><a/>',
    '<a><?XML version="1.0"?></a>', "<a>\0</a>", "<a>\255</a>",
};

for _, sInvalid in ipairs(tInvalid) do
    local bOK, sReason = pcall(oXML.parse, sInvalid);
    assert(not bOK and sReason:find("XML at line", 1, true));
    assert(oXML.getSource() == sSource);
end

local oCopy = clone(oXML);
oCopy.parse("<changed/>");
assert(oXML.getRoot().name == "map");
local oRestored = deserialize(serialize(oXML));
assert(class.of(oRestored) == XML and oRestored.getSource() == sSource);
assert(oRestored.getElements("property")[1].attributes.type == "int");
assert(XML().getRoot() == nil);
assert(clone(XML()).getRoot() == nil);
assert(deserialize(serialize(XML())).getRoot() == nil);
local hFile = assert(io.open("/xml-test.tmx", "w"));
hFile:write(sSource);
hFile:close();
assert(XML().load("/xml-test.tmx").getRoot().name == "map");
assert(not pcall(oXML.load, "/does-not-exist.tmx"));
assert(oXML.getSource() == sSource);
print("PASS XML: TMX metadata, entities/Unicode, CDATA/mixed content, malformed input, atomic replacement, independent trees, files, cloning and serialization");
