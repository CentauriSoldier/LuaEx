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
async function lint(sources, mode = 'lxc', options = {}) {
    const files = Object.entries(sources).map(([file, source]) => ({file, source}));
    return runner.lint({root, mode, files, ...options});
}

(async () => {
    check('length protocol uses UTF-8 byte counts', request([{file:'é.lxc',source:'é'}]).includes(Buffer.from('6\né.lxc2\né')));
    check('valid three-file inheritance', (await lint({
        'Creature.lxc': 'namespace P { class Creature { public describe() { return "creature"; } } }',
        'Human.lxc': 'namespace P { class Human : Creature { public override describe() { return base.describe(); } } }',
        'Soldier.lxc': 'namespace P { class Soldier : Human {} }'
    })).length === 0);
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

    const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'linter-lxc-test-'));
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
        check('framework dependency sources are included', batch.some(item => /classes[\\/]Queue.lxc$/.test(item.file)));
        const repositoryBatch = project.collect(path.join(root,'LuaEx/Creature.lxc'), fs.readFileSync(path.join(root,'LuaEx/Creature.lxc'),'utf8'), root, root);
        result = await runner.lint({root,mode:'lxc',files:repositoryBatch});
        check('all current framework and playground classes lint', result.length === 0);
    } finally {
        assert(path.dirname(temporary) === os.tmpdir());
        assert(path.basename(temporary).startsWith('linter-lxc-test-'));
        fs.rmSync(temporary, {recursive:true,force:true});
    }

    const config = {'linter-lxc.delegateLua':true};
    const editor = {getPath:()=>path.join(root,'example.lua'),getText:()=> 'return 1',isDestroyed:()=>false};
    global.atom = {
        config:{get:name=>config[name]},packages:{isPackageActive:name=>name==='linter-lua'},
        workspace:{getTextEditors:()=>[editor]},project:{relativizePath:()=>[root,'example.lua']}
    };
    main.activate();
    const provider = main.provideLinter();
    check('v2 provider schema and LXC association', provider.scope === 'file' && provider.lintsOnChange && provider.grammarScopes.includes('source.lxc'));
    check('active ordinary Lua linter is not duplicated', (await provider.lint(editor)).length === 0);
    config['linter-lxc.delegateLua']=false;
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
    console.log('PASS linter-lxc: ' + checks + ' checks; real Lua 5.4 backend and mocked Pulsar lifecycle.');
})().catch(error => { console.error(error); process.exitCode=1; }).finally(() => {runner.dispose(); if(main.active)main.deactivate();});
