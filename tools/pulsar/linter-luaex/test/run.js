'use strict';
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const {Runner, request} = require('../lib/runner');
const project = require('../lib/project');
const main = require('../lib/main');
const root = process.env.LUAEX_ROOT || require('../installation.json').luaExRoot || path.resolve(__dirname, '../../../..');
const runner = new Runner();
let checks = 0;
function check(name, condition) { assert(condition, name); checks++; }
function editorChecks() {
    const {Index, tokenize} = require('../lib/symbols');
    const annotations = require('../lib/annotations');
    const hover = require('../lib/hover');
    const completion = require('../lib/autocomplete');
    const signatures = require('../lib/signatures');
    const source = `using Shared;
namespace App {
class Base {
    public Base() {}
    public visible = false;
    protected inherited = 0;
    private secret = "hidden";
    public static Count = 1;
    ---@type number
    public Amount { get; protected set; } = 0;
    --[[!
    @param number first First argument.
    @param string second Second argument.
    @ret boolean bResult Result.
    @desc Does something useful.
    !]]
    public run(first, second) { return true; }
}
class Child : Base {
    ---@type Base?
    protected Target = null;
    public override Amount { get; protected set; }
    public inspect() {
        local object = Base();
        object.run(1, "x");
        this.inherited;
        this.Target.run(1, "x");
    }
    public static inspectStatic() { this.visible; }
}
enum Color { Red = false; Nested = 42 { Inside; } }
extension Color.label(this, value) { return tostring(value); }
class Outside { public test() { local child = Child(); child.visible; } }
}`;
    const index = new Index([{file: 'editor.lxc', source}, {file: 'shared.lxc', source: 'namespace Shared { public class Imported {} }'}]);
    const find = name => index.symbols.find(item => item.fullName === name);
    const child = find('App.Child'), base = find('App.Base');
    check('editor indexes multiple declarations and namespaces', !!child && !!base && !!find('App.Color'));
    check('type directive attached to field', find('App.Child.Target').documentation.type === 'Base?');
    check('DOx parameter names and types retained', find('App.Base.run').documentation.parameters.first.type === 'number');
    check('DOx return metadata retained', find('App.Base.run').documentation.returns[0].includes('boolean'));
    check('current namespace resolves types', index.resolve('Base', child)[0] === base);
    check('using namespace resolves types', index.resolve('Imported', child)[0].fullName === 'Shared.Imported');
    check('public instance members offered externally', index.members(child, {}, true).some(item => item.name === 'visible'));
    check('protected members hidden externally', !index.members(child, {}, true).some(item => item.name === 'inherited'));
    check('private members hidden from derived class', !index.members(child, child, true).some(item => item.name === 'secret'));
    check('protected members available in derived class', index.members(child, child, true).some(item => item.name === 'inherited'));
    check('static members separated from instances', !index.members(child, child, true).some(item => item.name === 'Count'));
    check('static inherited members available on class', index.members(child, child, false).some(item => item.name === 'Count'));
    check('generated getter aliases indexed', index.members(child, {}, true).some(item => item.name === 'getAmount'));
    check('protected setter aliases hidden externally', !index.members(child, {}, true).some(item => item.name === 'setAmount'));
    check('boolean false inferred correctly', index.typeOf(find('App.Base.visible')) === 'boolean');
    check('zero inferred correctly', index.typeOf(find('App.Base.inherited')) === 'number');
    check('override inherits annotation metadata', index.typeOf(find('App.Child.Amount')) === 'number');
    check('nested enum payload block indexed', !!find('App.Color.Nested.Inside'));
    check('enum extension callable on immediate members', index.members(find('App.Color.Red'), {}, false).some(item => item.name === 'label'));
    check('enum extension absent from root enum', !index.members(find('App.Color'), {}, false).some(item => item.name === 'label'));
    check('enum extension not inherited by embedded members', !index.members(find('App.Color.Nested.Inside'), {}, false).some(item => item.name === 'label'));
    check('enum metadata included', index.members(find('App.Color.Nested'), {}, false).some(item => item.name === 'Ordinal'));
    check('valid annotations do not warn', index.diagnostics().length === 0);
    const call = source.indexOf('object.run(1, "x")');
    check('constructor-inferred receiver resolves method', index.lookup('object.run', 'editor.lxc', call)[0] === find('App.Base.run'));
    check('annotated member receiver resolves method', index.lookup('this.Target.run', 'editor.lxc', source.indexOf('this.Target.run'))[0] === find('App.Base.run'));
    const help = signatures.help(index, 'editor.lxc', call + 'object.run(1, '.length);
    check('signature resolves actual method', help && help.symbol === find('App.Base.run'));
    check('signature selects second argument', help && help.active === 1);
    check('hover contains parameter types', hover.text(index, 'editor.lxc', call + 9).includes('first: number'));
    check('static method has no this receiver', !index.receiver('this', find('App.Child.inspectStatic'), source.indexOf('this.visible')));
    check('nested calls protect outer argument count', signatures.callAt('a(1, b(2, 3), {x=1,y=2}, ', 25).argument === 3);
    check('strings protect commas', signatures.callAt('a("x,y", ', 9).argument === 1);
    check('comments suppress signature display', signatures.callAt('-- a(1,', 6) === null);
    const safe = new Index([{file:'safe.lxc',source:'-- class Fake {}\nnamespace P { class Real { public S = "class AlsoFake { }"; public X = error("DO NOT EXECUTE"); } }'}]);
    check('comments and strings do not create declarations', safe.symbols.filter(item => item.kind === 'class').length === 1);
    check('arbitrary initializer types stay unknown', safe.typeOf(safe.symbols.find(item => item.name === 'X')) === 'unknown');
    check('long comments opaque to tokenizer', tokenize('--[==[ class Nope {} ]==]\ntrue').tokens.length === 1);
    check('nullable annotation grammar', annotations.type('App.Base?'));
    check('union metadata grammar for parameter docs', annotations.type('number|string?', true));
    check('field union contracts remain deferred', !annotations.type('number|string'));
    const invalid = new Index([{file:'invalid.lxc', source:`namespace P { class Bad {
---@type Missing
public X = null;
---@type number
---@type string
public Y = 1;
---@unknown value
public Z = 0;
---@type number
public method() {}
} }`}]);
    const warnings = invalid.diagnostics();
    check('unknown annotation type diagnosed', warnings.some(item => /Unresolved/.test(item.message)));
    check('duplicate annotation diagnosed', warnings.some(item => /Duplicate/.test(item.message)));
    check('unknown structured directive diagnosed', warnings.some(item => /Unknown editor directive/.test(item.message)));
    check('unsupported annotation target diagnosed', warnings.some(item => /applies to/.test(item.message)));
    check('editor annotations identify their declaration phase', warnings.every(item => item.severity === 'warning' && /annotations/.test(item.phase)));
    const selected = new Index([
        {file:'default.lxc', source:'namespace Defaults { ---@default\nclass C { public Lost; public class Nested {} } ---@default\nenum E { A; } ---@default\nextension E.test(this) { return false; } }'},
        {file:'ordinary.lxc', source:'namespace Defaults { class C { public Kept; } enum E { B; } }'},
        {file:'extension.lxe', source:'extension Defaults.E.test(this) { return true; }'}
    ]);
    check('editor selects ordinary class before resolving names', selected.resolve('Defaults.C').length === 1 && selected.resolve('Defaults.C')[0].file === 'ordinary.lxc');
    check('editor drops discarded class contents', !selected.symbols.some(item => item.fullName === 'Defaults.C.Lost' || item.fullName === 'Defaults.C.Nested'));
    check('editor binds external selected extension', selected.members(selected.symbols.find(item => item.fullName === 'Defaults.E.B'), {}, false).some(item => item.kind === 'extension' && item.file === 'extension.lxe'));
    check('valid default annotations have no warnings', selected.diagnostics().length === 0);
    const docOnly = new Index([{file:'doc-only.lxc', source:'namespace DocOnly { --[[!\n@type Missing\n---@default\n!]]\nclass C {} }'}]);
    check('DOx annotations do not become runtime directives in editor index', docOnly.diagnostics().length === 0);
    const equivalent = new Index([{file:'equivalent.lxc', source:'namespace Equivalent { class Value {} class Base { ---@type Value?\npublic Item { get; set; } } class Child : Base { ---@type Equivalent.Value?\npublic override Item { get; set; } } }'}]);
    check('equivalent qualified annotation spellings do not conflict', equivalent.diagnostics().length === 0);
    const scoped = new Index([
        {file:'owner.lxc', source:'namespace Scoped { class Owner { private static Secret = 1; private enum Hidden within Scoped.Owner { A; } public enum E within Scoped.Owner { A; } extension Scoped.Owner.E.inside(this) { return 1; } } }'},
        {file:'outside.lxe', source:'extension Scoped.Owner.E.outside(this) { return 1; }'}
    ]);
    const scopedOwner = scoped.resolve('Scoped.Owner')[0];
    const inside = scoped.symbols.find(item => item.name === 'inside'), outside = scoped.symbols.find(item => item.name === 'outside');
    check('external extension target grants no declaring-class editor privileges', !scoped.members(scopedOwner, outside, false).some(item => item.name === 'Secret'));
    check('class-scoped extension gains no private class-member privileges', !scoped.members(scopedOwner, inside, false).some(item => item.name === 'Secret'));
    check('extension enum-name access retains its original lexical restriction', scoped.resolve('Scoped.Owner.Hidden', inside).length === 1 && scoped.resolve('Scoped.Owner.Hidden', outside).length === 0);
    const unfinished = new Index([{file:'partial.lxc',source:'namespace App { class Test { public work() { this.'}]);
    check('unfinished declarations indexed without executing', unfinished.symbols.some(item => item.fullName === 'App.Test.work'));
    const completionSource = source.replace('object.run(1, "x");', 'object.ru');
    const completions = new Index([{file:'editor.lxc',source:completionSource}]);
    const offset = completionSource.indexOf('object.ru') + 9;
    const editor = {getPath:()=> 'editor.lxc',getText:()=>completionSource,getBuffer:()=>({characterIndexForPosition:()=>offset})};
    const suggestions = completion.suggestions(completions, editor, [0,0]);
    check('autocomplete supplies method with replacement prefix', suggestions.some(item => item.text === 'run' && item.replacementPrefix === 'ru'));
    check('autocomplete supplies annotated argument details', suggestions.some(item => item.description.includes('first: number')));
    check('wrong configured root produces precise error', (() => { try { project.frameworkRoot('file.lxc', os.tmpdir()); } catch (error) { return /Invalid.*luaExRoot/.test(error.message); } })());
    check('sibling project root discovery finds framework', project.frameworkRoot(path.join(root, '../CoG/cog/AStar.lxc'), '') === path.resolve(root));
}
async function lint(sources, mode = 'lxc', options = {}) {
    const files = Object.entries(sources).map(([file, source]) => ({file, source}));
    return runner.lint({root, mode, files, ...options});
}

(async () => {
    editorChecks();
    check('length protocol uses UTF-8 byte counts', request([{file:'é.lxc',source:'é'}]).includes(Buffer.from('6\né.lxc2\né')));
    check('valid three-file inheritance', (await lint({
        'Creature.lxc': 'namespace P { class Creature { public describe() { return "creature"; } } }',
        'Human.lxc': 'namespace P { class Human : Creature { public override describe() { return base.describe(); } } }',
        'Soldier.lxc': 'namespace P { class Soldier : Human {} }'
    })).length === 0);
    check('standalone LXE enum declarations', (await lint({
        'Enums.lxe': 'namespace P { enum E { A = 2; B = 3; } extension E.test(this) { return this == E.A; } }'
    })).length === 0);
    check('backend selects default class before validating discarded members', (await lint({
        'default.lxc': 'namespace BackendDefault { ---@default\nclass C : Missing {} }',
        'ordinary.lxc': 'namespace BackendDefault { class C {} }'
    })).length === 0);
    check('backend supports external default extension selection', (await lint({
        'enum.lxe': 'namespace BackendExtension { enum E { A; } ---@default\nextension E.test(this) { return false; } }',
        'external.lxe': 'extension BackendExtension.E.test(this) { return true; }'
    })).length === 0);
    check('backend resolves field annotations without running initializers', (await lint({
        'typed.lxc': 'namespace BackendType { class C { ---@type number\npublic X = error("must not run"); } }'
    })).length === 0);
    check('backend rejects unknown annotation names', (await lint({
        'typed.lxc': 'namespace BackendUnknownType { class C { ---@type Missing\npublic X; } }'
    })).some(item => /@type/.test(item.message)));
    check('inline enum with explicit owner', (await lint({
        'Owner.lxc': 'namespace P { class Owner { public enum E within P.Owner { A; B; } } }'
    })).length === 0);
    check('mixed enum dependencies and classes', (await lint({
        'Enums.lxe': 'namespace P { enum E { A; } }',
        'Owner.lxc': 'namespace P { class Owner requires(P.E) { public static Selected = E.A; } }'
    })).length === 0);
    check('missing LXE dependency diagnosed', (await lint({
        'Bad.lxe': 'namespace P { enum E requires(P.Missing) { A; } }'
    })).some(item => /Missing required enum/.test(item.message)));
    check('enum payload code is never executed', (await lint({
        'Safe.lxe': 'namespace P { enum E { A = error("must not run"); } }'
    })).length === 0);
    check('extension collisions diagnosed', (await lint({
        'Bad.lxe': 'namespace P { enum E { A; } extension E.A(this) { return true; } }'
    })).some(item => /collision/.test(item.message)));
    let result = await lint({'bad.lxc':'namespace P {\n class X { public public value = 1; }\n}'});
    check('declaration syntax line', result.length === 1 && result[0].file === 'bad.lxc' && result[0].line === 2);
    result = await lint({'a.lxc':'namespace P { final class A {} }','b.lxc':'namespace P { class B : A {} }'});
    check('real final inheritance rule', result.length === 1 && result[0].file === 'b.lxc' && /final class/.test(result[0].message));
    result = await lint({'a.lxc':'namespace P { class A {} }','b.lxc':'namespace P { class A {} }'});
    check('duplicate definitions', result.length === 1 && /Duplicate class/.test(result[0].message));
    result = await lint({'a.lxc':'namespace P { class A : Missing {} }'});
    check('missing dependencies are visible', result.length === 1 && /Missing parent/.test(result[0].message));
    result = await lint({'body.lxc':'namespace P {\n class A {\n public run() {\n local value = ;\n }\n }\n}'});
    check('Lua body diagnostic line maps back to source', result.length === 1 && result[0].line === 4);
    result = await lint({'static.lxc':'namespace P { class A { public static f() { return this; } } }'});
    check('compiler semantic rule reused', result.some(item => /Static members cannot use this/.test(item.message)));
    result = await lint({'override.lxc':'namespace P { class A { public f(a) {} } class B : A { public override f(a,b) {} } }'});
    check('override signature contract', result.some(item => /parameter contract/.test(item.message)));
    result = await lint({'unicode λ.lxc':'namespace P {\r\n class A { public value = 1;\r\n public value = 2; }\r\n}'});
    check('Unicode path and CRLF protocol', result.length === 1 && result[0].file === 'unicode λ.lxc' && result[0].line === 3);
    check('Lua 5.4 close syntax', (await lint({'ok.lua':'local value <close> = nil; return value;'},'lua')).length === 0);
    result = await lint({'bad.lua':'local x = 1\nlocal y = ;'}, 'lua');
    check('ordinary Lua syntax line', result.length === 1 && result[0].line === 2);
    check('Lua file BOM and shebang', (await lint({'ok.lua':'\uFEFF#!/usr/bin/lua\nreturn 1'},'lua')).length === 0);

    const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'linter-luaex-test-'));
    try {
        const sentinel = path.join(temporary, 'must-not-exist.txt').replace(/\\/g, '/');
        const action = `io.open(${JSON.stringify(sentinel)}, 'w'):write('executed')`;
        result = await lint({'safe.lxc': `namespace P { class A {
            public static field = (function() ${action}; return 1; end)();
            public instance = (function() ${action}; return 1; end)();
            static A() { ${action}; }
            public A() { ${action}; }
            public run() { ${action}; }
        } }`});
        check('all LXC code compiles without executing application code', result.length === 0 && !fs.existsSync(sentinel));
        result = await lint({'safe.lua':action}, 'lua');
        check('ordinary Lua top level never executes', result.length === 0 && !fs.existsSync(sentinel));
        const active = path.join(temporary, 'active.lxc');
        fs.writeFileSync(active, 'namespace P { class Broken : Missing {} }');
        const batch = project.collect(active, 'namespace P { class A {} }', root, temporary);
        check('active unsaved source overrides saved file', batch.find(item => project.key(item.file) === project.key(active)).source.includes('class A'));
        check('framework dependency sources are included', batch.some(item => /classes.*[\\/]Queue.lxc$/.test(item.file)));
        const repositoryBatch = project.collect(path.join(root,'LuaEx/Creature.lxc'), fs.readFileSync(path.join(root,'LuaEx/Creature.lxc'),'utf8'), root, root);
        result = await runner.lint({root,mode:'lxc',files:repositoryBatch});
        check('all current framework and playground classes lint', result.length === 0);
    } finally {
        assert(path.dirname(temporary) === os.tmpdir());
        assert(path.basename(temporary).startsWith('linter-luaex-test-'));
        fs.rmSync(temporary, {recursive:true,force:true});
    }

    const config = {'linter-luaex.delegateLua':true};
    const editor = {getPath:()=>path.join(root,'example.lua'),getText:()=> 'return 1',isDestroyed:()=>false};
    global.atom = {
        config:{get:name=>config[name]},packages:{isPackageActive:name=>name==='linter-lua'},
        workspace:{getTextEditors:()=>[editor]},project:{relativizePath:()=>[root,'example.lua']}
    };
    main.activate();
    const provider = main.provideLinter();
    check('v2 provider schema and LXC association', provider.scope === 'file' && provider.lintsOnChange && provider.grammarScopes.includes('source.lxc'));
    check('active ordinary Lua linter is not duplicated', (await provider.lint(editor)).length === 0);
    config['linter-luaex.delegateLua']=false;
    check('ordinary Lua fallback works', (await provider.lint(editor)).length === 0);
    const range = main.position('é😀\r\n  broken syntax',2);
    check('editor ranges use zero-based UTF-16 columns', range[0][0]===1 && range[0][1]===2 && range[1][1]===15);
    check('empty editor range is safe', main.position('',100)[0][0]===0);
    const previous = main.runner.lint;
    main.runner.lint = async () => { editor.getText=()=> 'changed'; return []; };
    check('stale editor diagnostics are discarded', await provider.lint(editor) === null);
    main.runner.lint=previous;
    main.deactivate();
    check('deactivation disposes runner', main.active === false && main.runner.disposed);
    let rejected = false;
    try { await runner.executable(path.join(os.homedir(),'Sync/Portable Apps/Libraries/Lua/5.3/lua.exe')); }
    catch (error) { rejected = /Lua 5.4/.test(error.message); }
    check('wrong Lua runtime is rejected clearly', rejected);
    console.log('PASS linter-luaex: ' + checks + ' checks; real Lua 5.4 backend and mocked Pulsar lifecycle.');
})().catch(error => { console.error(error); process.exitCode=1; }).finally(() => {runner.dispose(); if(main.active)main.deactivate();});

