'use strict';
const annotations = require('./annotations');
const modifiers = new Set('public protected private static const final abstract override'.split(' '));

// A tolerant editor index, separate from the authoritative compiler diagnostics.
// Tokens retain offsets, and strings/comments are opaque: example declarations
// inside documentation and braces inside Lua strings cannot become symbols.
function tokenize(source) {
    const tokens = [], comments = [];
    let i = 0, line = 1;
    const long = offset => source.slice(offset).match(/^\[(=*)\[/);
    while (i < source.length) {
        const start = i, row = line;
        if (/\s/.test(source[i])) { if (source[i++] === '\n') line++; continue; }
        let comment = false;
        if (source.startsWith('--', i)) { comment = true; i += 2; }
        const bracket = long(i);
        if (bracket) {
            const end = source.indexOf(']' + bracket[1] + ']', i + bracket[0].length);
            i = end < 0 ? source.length : end + bracket[0].length;
        } else if (comment) {
            const end = source.indexOf('\n', i); i = end < 0 ? source.length : end;
        } else if (source[i] === '"' || source[i] === "'") {
            const quote = source[i++];
            while (i < source.length) { if (source[i] === '\\') i += 2; else if (source[i++] === quote) break; }
        } else {
            const word = source.slice(i).match(/^(?:[A-Za-z_]\w*|\d+(?:\.\d+)?|\.\.\.)/);
            i += word ? word[0].length : 1;
        }
        const value = source.slice(start, i);
        const token = {value, start, end: i, line: row};
        (comment ? comments : tokens).push(token);
        line += (value.match(/\n/g) || []).length;
    }
    return {tokens, comments};
}
function parse(file, source) {
    const {tokens, comments} = tokenize(source), symbols = [], regions = [];
    const pairs = new Map(), stack = [];
    tokens.forEach((token, i) => {
        if (['{', '(', '['].includes(token.value)) stack.push(i);
        else if (['}', ')', ']'].includes(token.value)) {
            const open = stack[stack.length - 1];
            if (open !== undefined && '{(['.indexOf(tokens[open].value) === '})]'.indexOf(token.value)) {
                stack.pop(); pairs.set(open, i);
            }
        }
    });
    function doc(start) {
        const selected = [];
        let boundary = start;
        for (let i = comments.length - 1; i >= 0; i--) {
            const comment = comments[i];
            if (comment.end > boundary) continue;
            if (source.slice(comment.end, boundary).trim()) break;
            selected.unshift(comment.value); boundary = comment.start;
        }
        return annotations.read(selected.join('\n'));
    }
    function qualified(i) {
        let value = tokens[i] ? tokens[i++].value : '';
        while (tokens[i] && tokens[i].value === '.' && tokens[i + 1]) { value += '.' + tokens[i + 1].value; i += 2; }
        return {value, next: i};
    }
    function region(begin, end, namespace, owner, imports) {
        let i = begin;
        const uses = imports.slice();
        while (i < end) {
            const start = i, flags = [];
            while (tokens[i] && modifiers.has(tokens[i].value)) flags.push(tokens[i++].value);
            const token = tokens[i]; if (!token) break;
            if (token.value === 'using') {
                const name = qualified(i + 1); uses.push(name.value); i = name.next + 1; continue;
            }
            if (token.value === 'namespace') {
                const name = qualified(i + 1), close = pairs.get(name.next);
                if (tokens[name.next] && tokens[name.next].value === '{') {
                    region(name.next + 1, close === undefined ? end : close, name.value, null, uses);
                    i = close === undefined ? end : close + 1; continue;
                }
            }
            if (['class', 'enum', 'extension'].includes(token.value)) {
                const kind = token.value, name = qualified(i + 1);
                let open = name.next;
                while (open < end && tokens[open].value !== '{') open++;
                if (open >= end) break;
                const close = pairs.get(open), header = tokens.slice(name.next, open);
                const within = header.findIndex(item => item.value === 'within');
                const parent = header.findIndex(item => item.value === ':');
                const ownerName = within >= 0 ? qualified(name.next + within + 1).value : owner && owner.fullName;
                const symbol = {name: name.value, kind, fullName: [ownerName || namespace, name.value].filter(Boolean).join('.'),
                    namespace, owner, ownerName, imports: uses.slice(), flags, visibility: flags.find(x => ['public','private','protected'].includes(x)) || (owner ? 'private' : 'public'),
                    file, line: tokens[i + 1].line, start: tokens[start].start, end: close === undefined ? source.length : tokens[close].end,
                    bodyStart: tokens[open].end, parentName: parent < 0 ? '' : qualified(name.next + parent + 1).value,
                    documentation: doc(tokens[start].start), parameters: [], members: []};
                if (kind === 'extension') {
                    const split = name.value.lastIndexOf('.'); symbol.name = name.value.slice(split + 1);
                    symbol.target = name.value.slice(0, split);
                    const paren = tokens.findIndex((item, n) => n >= name.next && n < open && item.value === '(');
                    const stop = pairs.get(paren);
                    if (stop !== undefined) symbol.parameters = tokens.slice(paren + 1, stop).filter(item => item.value !== ',').map(item => item.value);
                }
                symbols.push(symbol); if (owner) owner.members.push(symbol);
                if (kind !== 'extension') region(open + 1, close === undefined ? end : close, namespace, symbol, uses);
                regions.push(symbol);
                i = close === undefined ? end : close + 1; continue;
            }
            if (owner && /^[A-Za-z_]\w*$/.test(token.value)) {
                const symbol = {name: token.value, fullName: owner.fullName + '.' + token.value,
                    kind: ['enum','enumMember'].includes(owner.kind) ? 'enumMember' : 'field', owner, namespace, imports: uses.slice(), flags,
                    visibility: flags.find(x => ['public','private','protected'].includes(x)) || (['enum','enumMember'].includes(owner.kind) ? 'public' : 'private'),
                    file, line: token.line, start: tokens[start].start, documentation: doc(tokens[start].start), parameters: []};
                i++;
                if (tokens[i] && tokens[i].value === '(') {
                    symbol.kind = 'method'; const stop = pairs.get(i);
                    if (stop === undefined) break;
                    symbol.parameters = tokens.slice(i + 1, stop).filter(item => item.value !== ',').map(item => item.value);
                    i = stop + 1;
                }
                if (tokens[i] && tokens[i].value === '{') {
                    if (symbol.kind !== 'method') symbol.kind = ['enum','enumMember'].includes(owner.kind) ? 'enumMember' : 'property';
                    const stop = pairs.get(i); symbol.bodyStart = tokens[i].end;
                    if (symbol.kind === 'enumMember') {
                        symbol.members = [];
                        region(i + 1, stop === undefined ? end : stop, namespace, symbol, uses);
                    }
                    if (symbol.kind === 'property') {
                        const accessors = tokens.slice(i + 1, stop === undefined ? end : stop);
                        symbol.accessors = [];
                        for (let n = 0; n < accessors.length; n++) {
                            const access = accessors[n];
                            if (access.value !== 'get' && access.value !== 'set') continue;
                            let prefix = access.value, next = n + 1;
                            if (accessors[next] && accessors[next].value === '(' && accessors[next + 1]) {
                                // Prefix literals are identifiers. Never evaluate a Lua literal.
                                const literal = accessors[next + 1].value.match(/^["']([A-Za-z_]\w*)["']$/);
                                if (!literal) continue;
                                prefix = literal[1]; next += 3;
                            }
                            const visibility = accessors[n - 1] && ['public','protected','private'].includes(accessors[n - 1].value) ? accessors[n - 1].value : symbol.visibility;
                            symbol.accessors.push({kind: access.value, prefix, visibility});
                            if (accessors[next] && accessors[next].value === '{') {
                                const global = tokens.indexOf(accessors[next]);
                                const close = pairs.get(global);
                                if (close !== undefined) n = accessors.indexOf(tokens[close]);
                            }
                        }
                    }
                    i = stop === undefined ? end : stop + 1;
                }
                if (symbol.kind !== 'method' && tokens[i] && tokens[i].value === '=') {
                    const valueStart = ++i;
                    const blocks = [];
                    while (i < end) {
                        const value = tokens[i].value;
                        if (!blocks.length && (value === ';' || (symbol.kind === 'enumMember' && value === '{' && i > valueStart))) break;
                        if (pairs.has(i)) { i = pairs.get(i) + 1; continue; }
                        if (['function','if','repeat','for','while'].includes(value)) blocks.push({awaitDo: value === 'for' || value === 'while'});
                        else if (value === 'do') {
                            if (blocks.length && blocks[blocks.length - 1].awaitDo) blocks[blocks.length - 1].awaitDo = false;
                            else blocks.push({});
                        } else if (value === 'end' || value === 'until') blocks.pop();
                        i++;
                    }
                    symbol.initializer = source.slice(tokens[valueStart] ? tokens[valueStart].start : source.length, tokens[i] ? tokens[i].start : source.length).trim();
                }
                if (symbol.kind === 'enumMember' && tokens[i] && tokens[i].value === '{') {
                    const stop = pairs.get(i); symbol.members = [];
                    region(i + 1, stop === undefined ? end : stop, namespace, symbol, uses);
                    i = stop === undefined ? end : stop + 1;
                }
                if (tokens[i] && tokens[i].value === ';') i++;
                symbol.end = tokens[Math.max(start, i - 1)].end;
                symbols.push(symbol); owner.members.push(symbol); regions.push(symbol);
                continue;
            }
            i = Math.max(start + 1, i + 1);
        }
    }
    region(0, tokens.length, '', null, []);
    return {file, source, tokens, comments, symbols, regions};
}

class Index {
    constructor(files) {
        this.files = files.map(item => parse(item.file, item.source));
        this.symbols = this.files.flatMap(item => item.symbols);
        this.selectionDiagnostics = [];
        const isCollection = item => ['class', 'enum'].includes(item.kind) || (item.kind === 'enumMember' && item.members);
        const choose = records => {
            const groups = new Map(), selected = new Set();
            for (const item of records) {
                const key = (item.kind === 'class' ? 'class:' : item.kind === 'extension' ? 'extension:' : 'enum:') + item.fullName;
                const group = groups.get(key) || [];
                group.push(item); groups.set(key, group);
            }
            for (const group of groups.values()) {
                const defaults = group.filter(item => item.documentation.directives.some(directive => directive.name === 'default'));
                const ordinary = group.filter(item => !defaults.includes(item));
                if (group.length > 2 || (group.length === 2 && (defaults.length !== 1 || ordinary.length !== 1))) {
                    const item = group[group.length - 1];
                    this.selectionDiagnostics.push({file: item.file, line: item.line, severity: 'warning',
                        phase: 'Declaration selection', message: 'Duplicate declaration: ' + item.fullName});
                }
                selected.add(ordinary[0] || defaults[0]);
            }
            return selected;
        };
        const live = new Set();
        let pending = this.symbols.filter(isCollection);
        while (pending.length) {
            const level = pending.filter(item => !item.owner || live.has(item.owner));
            if (!level.length) break;
            for (const item of choose(level)) live.add(item);
            const considered = new Set(level);
            pending = pending.filter(item => !considered.has(item));
        }
        this.symbols = this.symbols.filter(item => {
            if (isCollection(item) && !live.has(item)) return false;
            for (let owner = item.owner; owner; owner = owner.owner) if (isCollection(owner) && !live.has(owner)) return false;
            return true;
        });
        const retained = new Set(this.symbols);
        for (const item of this.symbols) if (item.members) item.members = item.members.filter(member => retained.has(member));
        for (const property of this.symbols.filter(item => item.kind === 'property')) {
            for (const access of property.accessors || []) {
                const alias = {...property, kind: 'method', name: access.prefix + property.name,
                    fullName: property.owner.fullName + '.' + access.prefix + property.name,
                    visibility: access.visibility, parameters: access.kind === 'set' ? ['value'] : [],
                    documentation: {...property.documentation, directives: [], type: undefined,
                        parameters: access.kind === 'set' ? {value: {type: property.documentation.type || this.typeOf(property)}} : {},
                        returns: access.kind === 'get' ? [property.documentation.type || this.typeOf(property)] : []}};
                property.owner.members.push(alias);
            }
        }
        const extensions = this.symbols.filter(item => item.kind === 'extension');
        for (const symbol of extensions) {
            symbol.lexicalOwner = symbol.owner;
            const enums = this.symbols.filter(item => ['enum', 'enumMember'].includes(item.kind) && item.members);
            const exact = name => enums.filter(item => item.fullName === name);
            let owners = exact(symbol.target);
            if (!owners.length) {
                owners = exact(symbol.namespace + '.' + symbol.target);
                for (const prefix of symbol.imports) owners.push(...exact(prefix + '.' + symbol.target));
                owners = Array.from(new Set(owners));
            }
            if (owners.length === 1) {
                symbol.owner = owners[0];
                symbol.fullName = owners[0].fullName + '.' + symbol.name;
            }
        }
        const selectedExtensions = choose(extensions);
        this.symbols = this.symbols.filter(item => item.kind !== 'extension' || selectedExtensions.has(item));
        for (const item of this.symbols) if (item.members) item.members = item.members.filter(member => member.kind !== 'extension');
        for (const symbol of selectedExtensions) if (symbol.owner && ['enum', 'enumMember'].includes(symbol.owner.kind)) symbol.owner.members.push(symbol);
        for (const symbol of this.symbols.filter(item => item.kind === 'enum' && item.ownerName && !item.owner)) {
            const owners = this.resolve(symbol.ownerName, symbol).filter(item => item.kind === 'class');
            if (owners.length === 1) { symbol.owner = owners[0]; owners[0].members.push(symbol); }
        }
    }
    context(file, offset) {
        const parsed = this.files.find(item => item.file === file);
        if (!parsed) return null;
        return parsed.regions.filter(item => item.start <= offset && item.end >= offset).sort((a,b) => (a.end-a.start)-(b.end-b.start))[0] ||
            {file, namespace: '', imports: [], start: 0, end: parsed.source.length};
    }
    resolve(name, context = {}) {
        const types = this.symbols.filter(item => ['class','enum'].includes(item.kind) || (item.kind === 'enumMember' && item.members));
        const exact = full => types.filter(item => item.fullName === full && this.visible(item, context));
        const direct = exact(name); if (direct.length) return direct;
        for (let owner = context.kind === 'extension' ? context.lexicalOwner : context.kind === 'class' ? context : context.owner; owner; owner = owner.owner) {
            const found = exact(owner.fullName + '.' + name); if (found.length) return found;
        }
        const local = exact(context.namespace + '.' + name); if (local.length) return local;
        const imported = (context.imports || []).flatMap(prefix => exact(prefix + '.' + name));
        return Array.from(new Set(imported));
    }
    derives(child, parent) {
        const seen = new Set();
        while (child && !seen.has(child)) {
            if (child === parent) return true; seen.add(child);
            child = this.resolve(child.parentName, child)[0];
        }
        return false;
    }
    visible(symbol, context = {}) {
        // LXE lexical class scope permits naming its private enum, but extension
        // functions are not LXC methods and gain no private class-member rights.
        if (context.kind === 'extension' && symbol.kind === 'enum' && symbol.owner && symbol.owner.kind === 'class' && symbol.visibility !== 'public') {
            return symbol.owner === context.lexicalOwner;
        }
        if (['class','enum','enumMember'].includes(symbol.kind) && symbol.owner && !this.visible(symbol.owner, context)) return false;
        if (symbol.visibility === 'public') return true;
        const declaring = symbol.owner;
        let caller = context.kind === 'extension' ? null : context.kind === 'class' ? context : context.owner;
        for (; caller; caller = caller.owner) {
            if (caller === declaring) return true;
            if (symbol.visibility === 'protected' && declaring && this.derives(caller, declaring)) return true;
        }
        return false;
    }
    members(owner, context, instance = false, seen = new Set(), receiver = owner) {
        if (!owner || seen.has(owner)) return []; seen.add(owner);
        const own = (owner.members || []).filter(item => this.visible(item, context) && item.kind !== 'extension' &&
            (['enum','enumMember'].includes(owner.kind) || (instance ? !item.flags.includes('static') && !['class','enum'].includes(item.kind) : item.flags.includes('static') || ['class','enum'].includes(item.kind))) && item.name !== owner.name);
        const parent = owner.kind === 'class' && this.resolve(owner.parentName, owner)[0];
        const inherited = this.members(parent, context, instance, seen, receiver).filter(item => !own.some(member => member.name === item.name));
        const metadata = ['enum','enumMember'].includes(owner.kind) ? ['Name','Parent'].concat(owner.kind === 'enumMember' ? ['Value','Ordinal'] : []).map(name => ({
            name, kind: 'field', fullName: owner.fullName + '.' + name, owner, file: owner.file, line: owner.line,
            flags: ['const'], parameters: [], visibility: 'public', documentation: {directives: [], parameters: {}, returns: [],
                type: name === 'Name' ? 'string' : name === 'Ordinal' ? 'number' : name === 'Value' ? this.typeOf(owner) : owner.owner ? owner.owner.fullName : 'null'}
        })) : [];
        const extensions = owner.kind === 'enumMember' && owner.owner ? owner.owner.members.filter(item => item.kind === 'extension') : [];
        return own.concat(inherited, metadata, extensions).filter(item => {
            if (!instance || item.visibility !== 'protected' || item.flags.includes('static')) return true;
            for (let caller = context.kind === 'extension' ? null : context.kind === 'class' ? context : context.owner; caller; caller = caller.owner) {
                if (caller === item.owner || (this.derives(caller, item.owner) && this.derives(receiver, caller))) return true;
            }
            return false;
        });
    }
    typeOf(symbol) {
        if (!symbol) return 'unknown';
        if (symbol.documentation.type) return symbol.documentation.type;
        if (symbol.kind === 'enumMember' && !symbol.initializer) return 'number';
        if (symbol.kind === 'property' && symbol.flags.includes('override')) {
            const parent = this.resolve(symbol.owner.parentName, symbol.owner)[0];
            const inherited = parent && this.members(parent, symbol.owner, !symbol.flags.includes('static')).find(item => item.name === symbol.name);
            if (inherited) return this.typeOf(inherited);
        }
        const value = symbol.initializer || '';
        if (/^(true|false)$/.test(value)) return 'boolean';
        if (/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$/.test(value)) return 'number';
        if (/^["']/.test(value) || /^\[(=*)\[/.test(value)) return 'string';
        if (/^\{/.test(value)) return 'table';
        if (/^function\b/.test(value)) return 'function';
        if (value === 'null' || value === 'nil') return value;
        const constructor = value.match(/^([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*\(/);
        const found = constructor && this.resolve(constructor[1], symbol);
        return found && found.length === 1 && found[0].kind === 'class' ? found[0].fullName : 'unknown';
    }
    receiver(expression, context, offset) {
        if (!expression || !context) return null;
        if (expression === 'this') {
            if (context.flags && context.flags.includes('static')) return null;
            if (context.kind === 'extension' && context.owner) return {owner: {kind: 'enumMember', owner: context.owner, members: [], fullName: context.owner.fullName + '.<member>', documentation: {parameters:{}, returns:[]}}, instance: false};
            return {owner: context.kind === 'class' ? context : context.owner, instance: true};
        }
        if (expression === 'base') {
            const owner = context.owner; return {owner: owner && this.resolve(owner.parentName, owner)[0], instance: true};
        }
        const types = this.resolve(expression, context);
        if (types.length === 1) return {owner: types[0], instance: false};
        const parsed = this.files.find(item => item.file === context.file);
        // Limit local inference to the current method and its simple top-level
        // bindings. Reassignments invalidate an inferred constructor type.
        let type = context.documentation && context.documentation.parameters[expression]; type = type && type.type;
        if (!type && parsed) {
            const text = parsed.source.slice(context.bodyStart || context.start, offset);
            const escaped = expression.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            if (/^[A-Za-z_]\w*$/.test(expression)) {
                const matches = Array.from(text.matchAll(new RegExp('(?:^|[;\\n])\\s*(?:local\\s+)?' + escaped + '\\s*=\\s*([^;\\n]*)', 'g')));
                if (matches.length) {
                    const value = matches[matches.length - 1][1].match(/^([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*\(/);
                    if (value) type = value[1];
                }
            }
        }
        if (type) { const found = this.resolve(type.replace(/\?$/, ''), context); if (found.length === 1) return {owner: found[0], instance: true}; }
        const dot = expression.lastIndexOf('.');
        if (dot > 0) {
            const root = this.receiver(expression.slice(0,dot), context, offset);
            const member = root && this.members(root.owner, context, root.instance).find(item => item.name === expression.slice(dot+1));
            if (member) {
                if (['class','enum','enumMember'].includes(member.kind)) return {owner: member, instance: false};
                const found = this.resolve(this.typeOf(member).replace(/\?$/, ''), member);
                if (found.length === 1) return {owner: found[0], instance: true};
            }
        }
        return null;
    }
    lookup(expression, file, offset) {
        const context = this.context(file, offset); if (!context) return [];
        const dot = expression.lastIndexOf('.');
        if (dot < 0) return this.resolve(expression, context);
        const receiver = this.receiver(expression.slice(0,dot), context, offset);
        return receiver ? this.members(receiver.owner, context, receiver.instance).filter(item => item.name === expression.slice(dot+1)) : this.resolve(expression, context);
    }
    diagnostics() {
        const result = this.selectionDiagnostics.concat(this.symbols.flatMap(symbol => annotations.validate(symbol, (name, context) => this.resolve(name, context))));
        for (const symbol of this.symbols.filter(item => item.kind === 'property' && item.flags.includes('override') && item.documentation.type)) {
            const parent = this.resolve(symbol.owner.parentName, symbol.owner)[0];
            const inherited = parent && this.members(parent, symbol.owner, !symbol.flags.includes('static')).find(item => item.name === symbol.name);
            if (inherited && inherited.documentation.type) {
                const ownType = symbol.documentation.type, baseType = inherited.documentation.type;
                const ownName = ownType.replace(/\?$/, ''), baseName = baseType.replace(/\?$/, '');
                const ownResolved = this.resolve(ownName, symbol), baseResolved = this.resolve(baseName, inherited);
                const sameType = ownResolved.length === 1 && baseResolved.length === 1 ? ownResolved[0] === baseResolved[0] : ownName === baseName;
                if (!sameType || ownType.endsWith('?') !== baseType.endsWith('?')) result.push({file: symbol.file, line: symbol.line,
                    severity: 'warning', phase: 'Declaration annotations', message: 'Property override annotation conflicts with ' + inherited.fullName});
            }
        }
        return result;
    }
}
function describe(symbol, index) {
    if (!symbol) return '';
    const doc = symbol.documentation;
    const parameters = symbol.parameters.map(name => name + (doc.parameters[name] ? ': ' + doc.parameters[name].type : ''));
    return symbol.fullName + (['method','extension'].includes(symbol.kind) ? '(' + parameters.join(', ') + ')' : ' : ' + (['class','enum'].includes(symbol.kind) ? symbol.kind : index.typeOf(symbol))) +
        (doc.returns.length ? '\nReturns: ' + doc.returns.join('; ') : '') + (doc.description ? '\n' + doc.description : '');
}
module.exports = {Index, parse, tokenize, describe};
