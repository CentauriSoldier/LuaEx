'use strict';
const {tokenize} = require('./symbols');

// Delimiter nesting makes commas in calls/tables/strings independent of the
// current call's argument number. Comments and strings are opaque tokens.
function callAt(source, offset) {
    const {tokens, comments} = tokenize(source);
    if (comments.some(item => item.start <= offset && offset < item.end)) return null;
    const stack = [];
    for (let i = 0; i < tokens.length && tokens[i].start < offset; i++) {
        const token = tokens[i], value = token.value;
        if (['(', '{', '['].includes(value)) {
            let name = '', n = i - 1;
            if (value === '(' && n >= 0 && /^[A-Za-z_]\w*$/.test(tokens[n].value)) {
                name = tokens[n--].value;
                while (n >= 1 && tokens[n].value === '.' && /^[A-Za-z_]\w*$/.test(tokens[n - 1].value)) { name = tokens[n - 1].value + '.' + name; n -= 2; }
            }
            stack.push({delimiter: value, name, argument: 0, start: token.start});
        } else if ([')', '}', ']'].includes(value)) stack.pop();
        else if (value === ',' && stack.length) stack[stack.length - 1].argument++;
    }
    return stack.slice().reverse().find(item => item.delimiter === '(' && item.name) || null;
}
function help(index, file, offset) {
    const parsed = index.files.find(item => item.file === file); if (!parsed) return null;
    const call = callAt(parsed.source, offset); if (!call) return null;
    let found = index.lookup(call.name, file, call.start);
    if (found.length !== 1) return null;
    let symbol = found[0];
    if (symbol.kind === 'class') symbol = symbol.members.find(item => item.kind === 'method' && item.name === symbol.name && !item.flags.includes('static'));
    if (!symbol || !['method', 'extension'].includes(symbol.kind)) return null;
    // LXE extensions declare their receiver explicitly. Bound dot calls omit it.
    const parameters = symbol.parameters.filter((item, i) => !(symbol.kind === 'extension' && i === 0 && item === 'this'));
    const active = Math.min(call.argument, Math.max(0, parameters.length - 1));
    return {symbol, parameters, active, argument: call.argument};
}
function attach(editor, getIndex) {
    let marker, decoration, generation = 0, disposed = false;
    const clear = () => { if (decoration) decoration.destroy(); if (marker) marker.destroy(); decoration = marker = null; };
    const update = async () => {
        const request = ++generation; clear(); const source = editor.getText();
        const point = editor.getCursorBufferPosition(), offset = editor.getBuffer().characterIndexForPosition(point);
        try {
            const index = await getIndex(editor);
            if (disposed || generation !== request || editor.isDestroyed() || source !== editor.getText()) return;
            const info = help(index, editor.getPath(), offset); if (!info) return;
            const node = document.createElement('div'); node.className = 'luaex-signature';
            node.appendChild(document.createTextNode(info.symbol.name + '('));
            info.parameters.forEach((name, i) => {
                if (i) node.appendChild(document.createTextNode(', '));
                const part = document.createElement(i === info.active ? 'strong' : 'span');
                const annotation = info.symbol.documentation.parameters[name];
                part.textContent = name + (annotation ? ': ' + annotation.type : ''); node.appendChild(part);
            });
            node.appendChild(document.createTextNode(')'));
            const returns = info.symbol.documentation.returns;
            if (returns.length) node.appendChild(document.createTextNode(' → ' + returns.join('; ')));
            marker = editor.markBufferPosition(point, {invalidate: 'touch'});
            decoration = editor.decorateMarker(marker, {type: 'overlay', item: node, position: 'tail'});
        } catch (_) { /* The linter owns configuration diagnostics. */ }
    };
    const cursor = editor.onDidChangeCursorPosition(update), changes = editor.onDidStopChanging(update);
    const command = atom.commands.add(atom.views.getView(editor), 'luaex-tools:signature-help', update);
    return {dispose() { disposed = true; generation++; clear(); cursor.dispose(); changes.dispose(); command.dispose(); }};
}
module.exports = {callAt, help, attach};
