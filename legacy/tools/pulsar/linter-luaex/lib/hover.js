'use strict';
const {describe} = require('./symbols');

function wordAt(source, offset) {
    let start = offset, end = offset;
    while (start > 0 && /[\w.]/.test(source[start - 1])) start--;
    while (end < source.length && /[\w.]/.test(source[end])) end++;
    return source.slice(start, end);
}
function text(index, file, offset) {
    const parsed = index.files.find(item => item.file === file); if (!parsed) return '';
    if (parsed.comments.some(item => item.start <= offset && offset < item.end)) return '';
    const token = parsed.tokens.find(item => item.start <= offset && offset < item.end);
    if (token && /^(?:["']|\[=*\[)/.test(token.value)) return '';
    const declaration = parsed.symbols.find(item => {
        const name = parsed.tokens.find(t => t.start >= item.start && t.value === item.name);
        return name && name.start <= offset && offset <= name.end;
    });
    const found = declaration ? [declaration] : index.lookup(wordAt(parsed.source, offset), file, offset);
    return found.length === 1 ? describe(found[0], index) : '';
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
                const content = text(index, editor.getPath(), offset); if (!content) return;
                const node = document.createElement('pre'); node.className = 'luaex-hover'; node.textContent = content;
                tooltip = atom.tooltips.add(element, {title: node, trigger: 'manual', placement: 'bottom'});
            } catch (_) { /* Configuration failures are reported by the linter. */ }
        }, 400);
    };
    element.addEventListener('mousemove', move); element.addEventListener('mouseleave', clear);
    const changes = editor.onDidChange(clear);
    return {dispose() { disposed = true; clear(); changes.dispose(); element.removeEventListener('mousemove', move); element.removeEventListener('mouseleave', clear); }};
}
module.exports = {wordAt, text, attach};
