'use strict';
const {describe} = require('./symbols');

function suggestions(index, editor, point) {
    const file = editor.getPath(), offset = editor.getBuffer().characterIndexForPosition(point);
    const source = editor.getText(), context = index.context(file, offset);
    if (!context) return [];
    const parsed = index.files.find(item => item.file === file);
    if (parsed.comments.some(item => item.start <= offset && offset < item.end)) return [];
    const token = parsed.tokens.find(item => item.start < offset && offset < item.end);
    if (token && /^(?:["']|\[=*\[)/.test(token.value)) return [];
    const match = source.slice(0, offset).match(/([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)?\.([A-Za-z_]\w*|)$/);
    let candidates, prefix;
    if (match && match[1]) {
        const receiver = index.receiver(match[1], context, offset);
        candidates = receiver ? index.members(receiver.owner, context, receiver.instance) :
            index.symbols.filter(item => ['class','enum'].includes(item.kind) && item.fullName.startsWith(match[1] + '.') && index.visible(item, context));
        prefix = match[2];
    } else {
        prefix = (source.slice(0,offset).match(/[A-Za-z_]\w*$/) || [''])[0];
        candidates = index.symbols.filter(item => ['class','enum'].includes(item.kind) && index.resolve(item.name, context).includes(item));
    }
    return candidates.filter(item => item.name.startsWith(prefix)).map(item => ({
        text: item.name, replacementPrefix: prefix,
        type: ['method','extension'].includes(item.kind) ? 'method' : item.kind === 'class' ? 'class' : item.kind === 'enum' ? 'type' : 'property',
        leftLabel: ['class','enum'].includes(item.kind) ? item.kind : index.typeOf(item),
        rightLabel: item.owner ? item.owner.fullName : item.namespace,
        description: describe(item, index)
    }));
}
function provider(getIndex) {
    return {selector: '.source.lxc, .source.lxe', disableForSelector: '.comment, .string',
        inclusionPriority: 2, suggestionPriority: 2, excludeLowerPriority: false,
        getSuggestions: async ({editor, bufferPosition}) => {
            try { return suggestions(await getIndex(editor), editor, bufferPosition); }
            catch (_) { return []; } // The linter reports configuration errors.
        }};
}
module.exports = {provider, suggestions};
