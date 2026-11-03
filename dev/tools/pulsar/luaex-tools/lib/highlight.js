'use strict';
const fs = require('fs');
const path = require('path');
const raw = JSON.parse(fs.readFileSync(path.join(__dirname, '../grammars/lxc.cson'), 'utf8'));
const signatures = new WeakMap();

// TextMate cannot refer to a class-header capture from arbitrary member rules.
// Specialize class contexts using names returned by the actual LXC parser.
// Only the enclosing class's exact name receives the constructor scope.
function grammar(names) {
    const result = JSON.parse(JSON.stringify(raw));
    const generic = result.repository.classes.patterns[0];
    const methods = result.repository.members.patterns.find(item => item.begin && item.begin.startsWith('\\b(') && item.begin.includes('(?='));
    const patterns = [];
    for (const name of Array.from(new Set(names)).sort()) {
        if (!/^[A-Za-z_]\w*$/.test(name)) continue;
        const rule = JSON.parse(JSON.stringify(generic));
        rule.begin = '\\b(class)\\s+(' + name + ')\\b';
        const constructor = JSON.parse(JSON.stringify(methods));
        constructor.begin = '\\b(' + name + ')(?=\\s*\\()';
        constructor.beginCaptures[1].name = 'entity.name.function.constructor.lxc';
        rule.patterns[0].patterns.unshift(constructor);
        patterns.push(rule);
    }
    result.repository.classes.patterns = patterns.concat(generic);
    return result;
}

function apply(editor, names) {
    if (!Array.isArray(names) || !atom.grammars.createGrammar) return;
    const signature = Array.from(new Set(names)).sort().join('|');
    if (signatures.get(editor) === signature) return;
    const updated = atom.grammars.createGrammar(path.join(__dirname, '../grammars/lxc.cson'), grammar(names));
    signatures.set(editor, signature);
    editor.setGrammar(updated);
}
module.exports = {grammar, apply};
