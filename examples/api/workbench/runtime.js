(function (scope) {
  'use strict';
  class LuaSession {
    constructor(wasmoon, wasm, emit) { this.wasmoon = wasmoon; this.wasm = wasm; this.emit = emit; }
    async boot(files) {
      this.factory = this.wasm instanceof Uint8Array
        ? new this.wasmoon.LuaFactory('/embedded-lua.wasm', undefined, this.wasm)
        : new this.wasmoon.LuaFactory(this.wasm);
      for (const [name, bytes] of Object.entries(files)) await this.factory.mountFile('/' + name, bytes);
      this.originalFiles = files;
      this.lua = await this.factory.createEngine({injectObjects:false,enableProxy:false});
      const index = Object.fromEntries(Object.keys(files).map(name => [name.toLowerCase(), '/' + name]));
      this.lua.global.set('__workbench_files', index);
      this.lua.global.set('__workbench_emit', this.emit);
      await this.lua.doString(`
        package.path = '/?.lua;/LuaEx/?.lua'
        local files = __workbench_files
        table.insert(package.searchers, 2, function(name)
          local file = files[(name:gsub('%.','/') .. '.lua'):lower()]
          if file then return assert(loadfile(file)), file end
          return '\\n\\tNo mounted LuaEx module: ' .. name
        end)
        local nativeToString = tostring
        print = function(...)
          local values = {}
          for index = 1, select('#', ...) do values[index] = nativeToString(select(index,...)) end
          __workbench_emit(table.concat(values, '\\t'))
        end
        require('LuaEx.load')()
        -- The virtual filesystem uses forward slashes on every host.
        local open = io.open
        io.open = function(file, ...) return open(file:gsub('\\\\','/'), ...) end
      `);
      return this.lua.doString('return _VERSION');
    }
    async run(file, source, inputs = {}) {
      this.lua.global.set('EXAMPLE_INPUT',inputs);
      await this.factory.mountFile('/' + file, source);
      return this.lua.doFile('/' + file);
    }
    async visual(inputs = {}) { this.lua.global.set('EXAMPLE_INPUT',inputs);return this.lua.doFile('/examples/visual/AStar/browser.lua'); }
    async action(action, payload = {}) {
      this.lua.global.set('__workbench_action', action);
      this.lua.global.set('__workbench_payload', payload);
      return this.lua.doString('return workbench_action(__workbench_action, __workbench_payload)');
    }
    async outputs() {
      const fs = (await this.factory.getLuaModule()).module.FS;
      const result = [];
      const visit = directory => {
        for (const name of fs.readdir(directory)) {
          if (name === '.' || name === '..') continue;
          const file = directory + '/' + name;
          if ((fs.stat(file).mode & 0o170000) === 0o040000) { visit(file); continue; }
          if (!/\.(png|csv|html|json|zip|luaex)$/i.test(file)) continue;
          const bytes = fs.readFile(file), original = this.originalFiles[file.slice(1)];
          if (!original || original.length !== bytes.length || bytes.some((value,index)=>value !== original[index])) result.push({name:file.slice(1),bytes});
        }
      };
      visit('/examples');
      return result;
    }
    close() { if (this.lua) { this.lua.global.close(); this.lua = null; } }
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = {LuaSession};
  else scope.LuaSession = LuaSession;
})(globalThis);
