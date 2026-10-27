// Exercise saved Eventrix graphs across independent Lua runtimes, without a shared registry cache.
const fs = require('node:fs');
const {generate} = require('./catalog.cjs');
const wasmoon = require('../wasmoon/package/dist/index.js');
const manifest = generate();
const wasm = new Uint8Array(fs.readFileSync('examples/api/wasmoon/package/dist/glue.wasm'));

async function open() {
    const factory = new wasmoon.LuaFactory('/embedded-lua.wasm', undefined, wasm);

    for (const file of manifest.files) {
        await factory.mountFile('/' + file, fs.readFileSync(file));
    }

    const engine = await factory.createEngine({injectObjects:false, enableProxy:false});
    engine.global.set('__files', Object.fromEntries(manifest.files.map(file => [file.toLowerCase(), '/' + file])));
    await engine.doString(`
        package.path = '/?.lua;/LuaEx/?.lua';
        local files = __files;
        table.insert(package.searchers, 2, function(name)
            local file = files[(name:gsub('%.', '/')..'.lua'):lower()];
            if file then return assert(loadfile(file)), file; end
            return '\\nNo mounted module '..name;
        end);
        require('LuaEx.load')(0);
        assert(CoG == nil and class == nil);
    `);

    return engine;
}

(async () => {
    let engine = await open();
    let saved;

    try {
        await engine.doFile('/tests/eventrix_regression.lua');
    } finally {
        engine.global.close();
    }

    engine = await open();

    try {
        saved = await engine.doString(`
            envrepo.EventrixColdEnvironment = {thread = coroutine.create(function() end), native = print};
            local eEvents = enum('EventrixColdEvents', {'ACTIVE', 'PAUSED'}, nil, true);
            local nCount = 2;
            local function hook()
                nCount = nCount + 1;
                return EventrixColdMarker..nCount;
            end
            local kBus = eventrix('EventrixColdEnvironment');
            kBus.addHook(eEvents.ACTIVE, hook);
            kBus.addHook(eEvents.PAUSED, hook);
            kBus.setEventActive(eEvents.PAUSED, false);
            return serialize({left = kBus, right = kBus, events = eEvents, hook = hook, factory = eventrix});
        `);
    } finally {
        engine.global.close();
    }

    engine = await open();

    try {
        engine.global.set('EventrixSavedGraph', saved);
        await engine.doString(`
            -- Missing external bindings reject clearly; registering them allows a clean retry.
            local bOK, sReason = pcall(deserialize, EventrixSavedGraph);
            assert(not bOK and tostring(sReason):find('EventrixColdEnvironment', 1, true));
            envrepo.EventrixColdEnvironment = {readerOnly = true};
            EventrixColdMarker = 'reader';
            local tFirst = deserialize(EventrixSavedGraph);
            local tSecond = deserialize(EventrixSavedGraph);
            assert(rawequal(tFirst.left, tFirst.right));
            assert(not rawequal(tFirst.left, tSecond.left));
            assert(rawequal(tFirst.factory, eventrix));
            assert(tFirst.left.getHookOrdinal(tFirst.events.ACTIVE, tFirst.hook) == 1);
            assert(not tFirst.left.isEventActive(tFirst.events.PAUSED));
            assert(tFirst.left.fire(tFirst.events.ACTIVE)[1] == 'reader3');
            assert(tFirst.left.fire(tFirst.events.ACTIVE)[1] == 'reader4');
            assert(tSecond.left.fire(tSecond.events.ACTIVE)[1] == 'reader3');
            assert(envrepo.EventrixColdEnvironment.readerOnly);
            assert(envrepo.EventrixColdEnvironment.thread == nil);
            local kResaved = deserialize(serialize(tFirst.left));
            assert(type(kResaved) == 'eventrix');
        `);
    } finally {
        engine.global.close();
    }

    console.log('PASS Eventrix cold restore: private event enums, factory/shared callback identity, external environment reconnection, missing bindings, global rebinding and independent captured state');
})().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
