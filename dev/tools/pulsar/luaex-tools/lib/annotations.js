'use strict';

// Editor metadata only. Nothing in this module changes a LuaEx runtime contract.
const primitives = new Set(['boolean', 'number', 'string', 'table', 'function', 'thread', 'userdata']);
function type(expression, rich = false) {
    const value = expression.trim();
    const parts = rich ? value.split('|') : [value];
    return parts.length > 0 && parts.every(part => /^(?:[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*|\.\.\.)\??$/.test(part));
}
function read(comment) {
    const result = {parameters: {}, returns: [], directives: [], description: ''};
    const descriptions = [];
    let longClose = '';
    for (const line of comment.split(/\r?\n/)) {
        const longStart = line.match(/^\s*--\[(=*)\[/);
        const blockLine = !!longClose || !!longStart;
        if (longStart && !longClose) longClose = ']' + longStart[1] + ']';
        if (longClose && line.includes(longClose)) longClose = '';
        const structured = !blockLine && /^\s*---\s*@/.test(line);
        const match = line.match(/(?:---\s*|^\s*)@([A-Za-z_]\w*)\s*(.*)/);
        if (!match) continue;
        const [, name, value] = match;
        if (name === 'type' || name === 'default') {
            if (structured) result.directives.push({name, value: value.trim()});
        }
        else if (name === 'param') {
            const field = value.match(/^(\S+)\s+([A-Za-z_]\w*|\.\.\.)\s*(.*)$/);
            if (field) result.parameters[field[2]] = {type: field[1], description: field[3]};
        } else if (name === 'return' || name === 'ret') result.returns.push(value.trim());
        else if (name === 'desc') descriptions.push(value.trim());
        else if (structured) result.directives.push({name, value: value.trim()});
    }
    result.type = result.directives.find(item => item.name === 'type');
    result.type = result.type && result.type.value;
    // DOx can contain HTML; tooltips display plain text rather than injecting it.
    result.description = descriptions.join(' ').replace(/<[^>]*>/g, '');
    return result;
}
function validate(symbol, resolve) {
    const diagnostics = [];
    const report = message => diagnostics.push({file: symbol.file, line: symbol.line,
        severity: 'warning', phase: 'Declaration annotations', message});
    const metadata = symbol.documentation;
    for (const directive of metadata.directives) {
        if (directive.name !== 'type' && directive.name !== 'default') report('Unknown editor directive: @' + directive.name);
        if (directive.name === 'default') {
            if (!['class', 'enum', 'extension'].includes(symbol.kind) && !(symbol.kind === 'enumMember' && symbol.members)) report('@default applies to classes, enums and extensions.');
            if (directive.value) report('@default takes no arguments.');
        }
    }
    if (metadata.directives.filter(item => item.name === 'type').length > 1) report('Duplicate @type annotation.');
    if (metadata.directives.filter(item => item.name === 'default').length > 1) report('Duplicate @default annotation.');
    if (metadata.type !== undefined) {
        if (!['field', 'property', 'local'].includes(symbol.kind)) report('@type applies to fields and properties; local types are editor metadata.');
        if (!type(metadata.type)) report('Invalid @type expression: ' + metadata.type);
        else {
            const name = metadata.type.replace(/\?$/, '');
            const found = resolve(name, symbol);
            if (!primitives.has(name) && (found.length !== 1 || found[0].kind !== 'class')) report('Unresolved or ambiguous annotation type: ' + name);
        }
    }
    return diagnostics;
}
module.exports = {read, validate, type, primitives};
