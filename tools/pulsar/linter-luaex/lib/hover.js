'use strict';
const {describe} = require('./symbols');

function wordAt(source, offset) {
    let start = offset, end = offset;
    while (start > 0 && /[\w.]/.test(source[start - 1])) start--;
    while (end < source.length && /[\w.]/.test(source[end])) end++;
    return source.slice(start, end);
}
function symbolAt(index, file, offset) {
    const parsed = index.files.find(item => item.file === file); if (!parsed) return '';
    if (parsed.comments.some(item => item.start <= offset && offset < item.end)) return '';
    const token = parsed.tokens.find(item => item.start <= offset && offset < item.end);
    if (token && /^(?:["']|\[=*\[)/.test(token.value)) return '';
    const declaration = parsed.symbols.find(item => {
        const name = parsed.tokens.find(t => t.start >= item.start && t.value === item.name);
        return name && name.start <= offset && offset <= name.end;
    });
    const found = declaration ? [declaration] : index.lookup(wordAt(parsed.source, offset), file, offset);
    return found.length === 1 ? found[0] : null;
}
function text(index, file, offset) {
    const symbol = symbolAt(index, file, offset);
    return symbol ? describe(symbol, index) : '';
}

// Keep source and documentation as text nodes; never interpret them as HTML.
function render(symbol, index) {
    const node = document.createElement('pre'); node.className = 'luaex-hover';
    const append = (value, part) => {
        const span = document.createElement('span');
        if (part) span.className = 'luaex-hover-' + part;
        span.textContent = value; node.appendChild(span);
    };
    const dot = symbol.fullName.lastIndexOf('.');
    if (dot >= 0) append(symbol.fullName.slice(0, dot + 1), 'namespace');
    append(symbol.fullName.slice(dot + 1), 'name');
    const doc = symbol.documentation;
    if (['method', 'extension'].includes(symbol.kind)) {
        append('(');
        symbol.parameters.forEach((name, i) => {
            if (i) append(', ');
            append(name, 'parameter');
            if (doc.parameters[name]) { append(': '); append(doc.parameters[name].type, 'type'); }
        });
        append(')');
    } else {
        append(' : ');
        append(['class', 'enum'].includes(symbol.kind) ? symbol.kind : index.typeOf(symbol), 'type');
    }
    if (doc.returns.length) {
        append('\nReturns: ', 'label');
        doc.returns.forEach((value, i) => {
            if (i) append('; ');
            const match = value.match(/^(\S+)([\s\S]*)$/);
            if (match) { append(match[1], 'return'); if (match[2]) append(match[2], 'description'); }
        });
    }
    if (doc.description) append('\n' + doc.description, 'description');
    return node;
}
function attach(editor, getIndex) {
    const element = atom.views.getView(editor);
    let timer, tooltip, generation = 0, disposed = false;
    const clear = () => { generation++; clearTimeout(timer); if (tooltip) tooltip.dispose(); tooltip = null; };
    const move = event => {
        clear(); const request = generation;
        timer = setTimeout(async () => {
            try {
                const lines = element.querySelector('.lines'); if (!lines) return;
                const rectangle = lines.getBoundingClientRect();
                const position = element.screenPositionForPixelPosition({top: event.clientY - rectangle.top, left: event.clientX - rectangle.left});
                const point = editor.bufferPositionForScreenPosition(position);
                const source = editor.getText();
                const offset = editor.getBuffer().characterIndexForPosition(point);
                const index = await getIndex(editor);
                if (disposed || request !== generation || editor.isDestroyed() || source !== editor.getText()) return;
                const symbol = symbolAt(index, editor.getPath(), offset); if (!symbol) return;
                const node = render(symbol, index);
                // Pulsar accepts DOM content through item, not title. Anchor to the
                // hovered token instead of positioning against the whole editor.
                if (!element.contains(event.target)) return;
                tooltip = atom.tooltips.add(event.target, {item: node, class: 'luaex-tooltip', trigger: 'manual', placement: 'auto top'});
            } catch (_) { /* Configuration failures are reported by the linter. */ }
        }, 400);
    };
    element.addEventListener('mousemove', move); element.addEventListener('mouseleave', clear);
    const changes = editor.onDidChange(clear);
    return {dispose() { disposed = true; clear(); changes.dispose(); element.removeEventListener('mousemove', move); element.removeEventListener('mouseleave', clear); }};
}
module.exports = {wordAt, text, render, attach};
