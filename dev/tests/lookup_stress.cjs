// Launch the Lua workload in a fresh native process. --baseline restores only
// the previous namespace/member resolver in memory; checkout files never change.
// Compiler and execution fast paths remain current in both modes.
const fs = require('node:fs');
const path = require('node:path');
const {spawn} = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const baseline = process.argv.includes('--baseline');
const astar = process.argv.includes('--astar');
const noDirect = process.argv.includes('--no-direct');

function replace(source, before, after) {
  if (!source.includes(before)) throw Error('Baseline source boundary changed: '+before.slice(0, 70));
  return source.replace(before, after);
}
function removeUntil(source, from, until) {
  const start = source.indexOf(from), end = source.indexOf(until, start);
  if (start < 0 || end < 0) throw Error('Baseline source range changed.');
  return source.slice(0, start) + source.slice(end);
}

let script = '';
if (noDirect) {
  let compiler = fs.readFileSync(path.join(root, 'LuaEx/lib/lxc/Compiler.lua'), 'utf8');
  compiler = replace(compiler, 'local bDirect = not bExpression', 'local bDirect = false and not bExpression');
  compiler = replace(compiler, "if (tMember.Kind == 'method' and tMember.Visibility == 'public' and not tMember.Flags.static) then",
    "if (false and tMember.Kind == 'method' and tMember.Visibility == 'public' and not tMember.Flags.static) then");
  compiler = replace(compiler, "local sHelpers = 'local __lxc_view = __lxc_view; local __lxc_read = __lxc_read; ';", "local sHelpers = ''; ");
  let runtime = fs.readFileSync(path.join(root, 'LuaEx/lib/lxc/Runtime.lua'), 'utf8');
  runtime = replace(runtime, 'local fKnown = tPublicMethods[sName];', 'local fKnown = nil;');
  runtime = replace(runtime, 'if (not tClass.PrivateNames[sName]) then', 'if (false and not tClass.PrivateNames[sName]) then');
  script += `local fLoadCompiler = loadfile;
local tCompilerControl = {
    ['Compiler.lua'] = [====[${compiler}]====],
    ['Runtime.lua'] = [====[${runtime}]====],
};
loadfile = function(pFile, sMode, tEnvironment)
    local sName = pFile:gsub('\\\\','/'):match('/lxc/([^/]+)$');
    if tCompilerControl[sName] then
        return load(tCompilerControl[sName], '@'..pFile, sMode or 't', tEnvironment);
    end
    if tEnvironment then return fLoadCompiler(pFile,sMode,tEnvironment); end
    return fLoadCompiler(pFile,sMode);
end;
`;
}
if (baseline) {
  const directory = path.join(root, 'LuaEx/lib/lxc');
  let environment = fs.readFileSync(path.join(directory, 'Environment.lua'), 'utf8');
  environment = removeUntil(environment, '    local tNamespaceIndexes =', '    --[[!\n    @fqxn LuaEx.LXC.Environment.create\n');
  environment = removeUntil(environment, '        local tBatchNamespaces =', '        --[[!\n        @fqxn LuaEx.LXC.Environment.enum\n');
  environment = replace(environment, 'local _gmatch, _find, _sub = string.gmatch, string.find, string.sub;', 'local _gmatch, _match, _sub = string.gmatch, string.match, string.sub;');
  environment = replace(environment, 'local tFound = fResolveClass(sKey);', 'local tFound = Model.resolve(sKey, tClass, tBatch);');
  environment = replace(environment, 'if (tBatchNamespaces[sFull] or Model.NamespacePaths[sFull]) then return fNamespace(sFull); end', `for sName in pairs(tBatch) do
                        if (_sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end
                    for sName in pairs(Model.Classes) do
                        if (_sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end`);
  environment = replace(environment, 'if (tEnumNamespaces[sFull]) then return fNamespace(sFull); end', `for sName in pairs(tEnums) do
                        if (_sub(sName, 1, #sFull + 1) == sFull..'.') then return fNamespace(sFull); end
                    end`);
  environment = replace(environment, 'if (tBatchNamespaces[sKey] or Model.NamespacePaths[sKey]) then return fNamespace(sKey); end', `for sName in pairs(tBatch) do
                    if (_match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end
                for sName in pairs(Model.Classes) do
                    if (_match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end`);
  environment = replace(environment, 'if (tEnumNamespaces[sKey]) then return fNamespace(sKey); end', `for sName in pairs(tEnums) do
                    if (_match(sName, '^([^.]+)') == sKey) then return fNamespace(sKey); end
                end`);

  let model = fs.readFileSync(path.join(directory, 'Model.lua'), 'utf8');
  const start = model.indexOf('    function Model.member(tClass, tCaller, sName)');
  const end = model.indexOf('    --[[!\n    @fqxn LuaEx.LXC.Model.resolve\n', start);
  if (start < 0 || end < 0) throw Error('Baseline member boundary changed.');
  model = model.slice(0, start) + `    function Model.member(tClass, tCaller, sName)
        local tScope = tCaller;
        while (tScope) do
            local tOwn = tScope.ByName[sName];
            if (Model.descends(tClass, tScope) and tOwn and tOwn.Visibility == 'private') then return tOwn; end
            tScope = tScope.Outer;
        end
        while (tClass) do
            if (tClass.ByName[sName]) then return tClass.ByName[sName]; end
            tClass = tClass.Parent;
        end
    end

` + model.slice(end);
  model = removeUntil(model, '        -- Member maps are immutable', '        return tOrder;');
  const loader = replace(fs.readFileSync(path.join(directory, 'Loader.lua'), 'utf8'), 'Model.publish(tClass);', 'Model.Classes[tClass.FullName] = tClass;');
  const sources = {'Environment.lua':environment, 'Model.lua':model, 'Loader.lua':loader};
  script += 'local tSources = {\n'+Object.entries(sources).map(([file, source]) => '['+JSON.stringify(file)+'] = [====['+source+']====],').join('\n')+'\n};\n';
  script += `local fOriginalLoad = loadfile;
loadfile = function(pFile, sMode, tEnvironment)
    local sName = pFile:gsub('\\\\', '/'):match('/lxc/([^/]+)$');
    local sSource = sName and tSources[sName];
    if (sSource) then
        if (tEnvironment) then return load(sSource, '@'..pFile, sMode or 't', tEnvironment); end
        return load(sSource, '@'..pFile, sMode or 't');
    end
    if (tEnvironment) then return fOriginalLoad(pFile, sMode, tEnvironment); end
    return fOriginalLoad(pFile, sMode);
end;
`;
}
script += 'dofile('+JSON.stringify(path.join(__dirname, 'lookup_stress.lua').replaceAll('\\', '/'))+');\n';
console.log('MODE', baseline ? 'previous lookup implementation' : noDirect ? 'direct compiler paths disabled in memory' : 'optimized lookup implementation', astar ? 'AStar' : 'native Lua stress');
const child = spawn(process.env.LUA || 'lua', ['-', ...(astar ? ['--astar'] : [])], {cwd:root, stdio:['pipe','inherit','inherit']});
child.on('error', error => { console.error(error); process.exitCode = 1; });
child.on('exit', code => { process.exitCode = code ?? 1; });
child.stdin.end(script);
