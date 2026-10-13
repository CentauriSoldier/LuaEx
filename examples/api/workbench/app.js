(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  let provider, manifest, verification = [], entry, originalSource = '', worker, state, playing = false;
  let requestId = 0, generation = 0, playTimer, nextPaint, paintKey, selecting = 0;
  let outputLines = 0, outputBytes = 0, objectURLs = [], savedMap;
  let mode='code',visualSource='',savedVisual=null;
  const codeDrafts=new Map();
  const pending = new Map();
  const palette = ['#e1eace','#637075','#b6c7aa','#b7b2bb','#ecd69e','#8eb092','#b9a188'];
  const terrainIcons=['ground','wall','marsh','rock','sand','forest','cave'];
  function icon(name) {
    const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.setAttribute('viewBox','0 0 24 24');svg.setAttribute('aria-hidden','true');
    const path=document.createElementNS(svg.namespaceURI,'path');path.setAttribute('d',window.FantasyIcons[name]||window.FantasyIcons.ground);path.setAttribute('fill','none');path.setAttribute('stroke','currentColor');path.setAttribute('stroke-width','1.7');path.setAttribute('stroke-linecap','round');path.setAttribute('stroke-linejoin','round');svg.append(path);return svg;
  }
  function canvasIcon(ctx,name,x,y,size,color) {
    ctx.save();ctx.translate(x-size/2,y-size/2);ctx.scale(size/24,size/24);ctx.strokeStyle=color;ctx.lineWidth=1.7;ctx.lineCap=ctx.lineJoin='round';ctx.stroke(new Path2D(window.FantasyIcons[name]||window.FantasyIcons.ground));ctx.restore();
  }
  const array = value => Array.isArray(value) ? value : Object.values(value || {});
  function append(text) {
    if (outputLines >= 2000 || outputBytes >= 200000) return;
    const line = String(text); outputLines++; outputBytes += line.length;
    $('output').textContent += line + '\n';
    if (outputLines === 2000 || outputBytes >= 200000) $('output').textContent += '[Output limit reached]\n';
    $('output').scrollTop = $('output').scrollHeight;
  }
  function clearOutput() { $('output').textContent = ''; outputLines = outputBytes = 0; $('generated-files').replaceChildren(); $('generated-files').hidden = true; }
  function setStatus(text) { $('run-status').textContent = text; }
  function pause() { playing = false; clearTimeout(playTimer); $('play').textContent = '▶ Play'; }
  function dispose(message = 'Stopped') {
    window.PoolView.dispose();
    window.PotView.dispose();
    window.ProteanView.dispose();
    window.StackView.dispose();
    window.EnumView.dispose();
    window.ItemView.dispose();
    window.CardView.dispose();
    generation++; pause(); if (worker) worker.terminate(); worker = null;
    for (const request of pending.values()) { clearTimeout(request.timer); request.reject(Error(message)); }
    pending.clear(); for (const url of objectURLs) URL.revokeObjectURL(url); objectURLs = [];
    $('stop').disabled = true; $('run').disabled = !provider; state = null;
    $('visual-tab').disabled=$('code-tab').disabled=false;
  }
  function request(type, payload) {
    if (!worker) return Promise.reject(Error('Run the example first.'));
    const id = ++requestId;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => { dispose('Execution timed out'); setStatus('Timed out'); append('Execution timed out. Adjust the code and run again.'); }, 30000);
      pending.set(id,{resolve,reject,timer}); worker.postMessage({id,type,payload});
    });
  }
  function bytes(base64) { return Uint8Array.from(atob(base64),character=>character.charCodeAt(0)); }
  function makeProvider() {
    const bundle = window.LuaExExampleBundle;
    if (!bundle) throw Error('The local example bundle is missing.');
    return {
      read:async file => {
        if(file==='examples/manifest.json')return new TextEncoder().encode(JSON.stringify(bundle.manifest));
        if(file==='examples/verification.json')return new TextEncoder().encode(JSON.stringify(bundle.verification));
        if(!bundle.files[file])throw Error('Missing bundled file: '+file);
        return bytes(bundle.files[file]);
      },
    };
  }
  const decode = bytes => new TextDecoder().decode(bytes);
  async function initialize(nextProvider) {
    dispose(); provider = nextProvider; $('run').disabled = false;
    $('runtime-status').innerHTML = '<i></i>Reading repository…';
    try {
      manifest = JSON.parse(decode(await provider.read('examples/manifest.json')));
      if (!Array.isArray(manifest.entries) || !manifest.files.includes('LuaEx/init.lua')) throw Error('Invalid example catalog');
      try { verification = JSON.parse(decode(await provider.read('examples/verification.json'))); } catch { verification = []; }
      $('runtime-status').innerHTML = '<i></i>Lua 5.4 · local runtime'; $('runtime-status').classList.add('ready');
      $('example-count').textContent = manifest.entries.length;
      renderList(); await select(manifest.entries[0].id); await run();
    } catch (error) {
      $('welcome').hidden = false; $('workbench').hidden = true;
      $('welcome-note').textContent = error.message;
      $('runtime-status').innerHTML = '<i></i>Could not load examples'; provider = null;
    }
  }
  function renderList() {
    const nav = $('example-list'); nav.replaceChildren();
    const query = $('search').value.toLowerCase();
    for (const group of ['Fundamentals','Collections','CoG','Components','Classes & factories','Geometry','Pathfinding','Utilities','Legacy experiments']) {
      const entries = manifest.entries.filter(item => item.group === group && (item.title + ' ' + item.description + ' ' + item.path).toLowerCase().includes(query));
      if (!entries.length) continue;
      const heading = document.createElement('h2'); heading.className = 'category'; heading.textContent = group; nav.append(heading);
      for (const item of entries) {
        const button = document.createElement('button'); button.className = 'example-link' + (item.id === entry?.id ? ' active' : '');
        button.setAttribute('aria-current',item.id === entry?.id ? 'true' : 'false');
        const name = document.createElement('span'); name.textContent = item.title.replace(' (legacy)',''); button.append(name);
        const result = verification.find(test => test.id === item.id);
        if (result?.result === 'error') {
          const badge = document.createElement('span'); badge.className = 'badge'; badge.textContent = 'ISSUE'; button.append(badge);
        }
        button.addEventListener('click',() => select(item.id).catch(error=>append(error.message))); nav.append(button);
      }
    }
    if (!nav.children.length) { const empty = document.createElement('p'); empty.className = 'sidebar-empty'; empty.textContent = 'No matching examples.'; nav.append(empty); }
  }
  function tab(visual) {
    if(!visual&&mode==='visual'&&worker&&state){pause();window.PoolView.stop();window.PotView.stop();generation++;for(const task of pending.values()){clearTimeout(task.timer);task.reject(Error('Tab changed'));}pending.clear();savedVisual={worker,state,urls:objectURLs};worker=null;state=null;objectURLs=[];}
    if(visual&&mode==='code'&&savedVisual){dispose();worker=savedVisual.worker;state=savedVisual.state;objectURLs=savedVisual.urls;savedVisual=null;update();action('view');}
    mode=visual?'visual':'code';const showVisual=visual;
    $('visual-panel').hidden = !showVisual || entry?.visualType!=='astar';
    $('pool-panel').hidden = !showVisual || entry?.visualType!=='pool'; $('code-panel').hidden = showVisual;
    $('pot-panel').hidden=!showVisual||entry?.visualType!=='pot';
    $('protean-panel').hidden=!showVisual||entry?.visualType!=='protean';
    $('stack-panel').hidden=!showVisual||entry?.visualType!=='stack';
    $('enum-panel').hidden=!showVisual||entry?.visualType!=='enum';
    $('items-panel').hidden=!showVisual||entry?.visualType!=='items';
    $('cards-panel').hidden=!showVisual||entry?.visualType!=='cards';
    $('visual-empty').hidden=!showVisual||Boolean(entry?.visualPath);
    $('example-inputs').hidden=!showVisual||!entry?.inputs?.length;
    $('run').textContent=visual?'▶ Run visual':'▶ Run code';$('run').disabled=visual&&!entry?.visualPath;
    setStatus(visual?(entry?.visualPath?(worker?'Running · Lua 5.4':'Ready to run visual'):'No visual yet'):'Ready to run code');
    $('visual-tab').setAttribute('aria-selected',String(showVisual)); $('code-tab').setAttribute('aria-selected',String(!showVisual));
  }
  async function select(id) {
    if(entry)codeDrafts.set(entry.id,$('editor').value);
    if(savedVisual){savedVisual.worker.terminate();for(const url of savedVisual.urls)URL.revokeObjectURL(url);savedVisual=null;}
    const token = ++selecting; dispose(); entry = manifest.entries.find(item=>item.id===id);
    if (!entry) throw Error('Unknown example');
    clearOutput(); renderInputs(); $('welcome').hidden = true; $('workbench').hidden = false;
    $('example-title').textContent = entry.title; $('example-group').textContent = entry.group.toUpperCase();
    $('example-description').textContent = entry.description; $('example-kind').textContent = 'LUA EXAMPLES';
    const result = verification.find(test=>test.id===entry.id);
    const notes = [entry.note, result?.result === 'error' ? 'Last verification reported an existing example/API error: ' + result.message.split('\n')[0] : ''].filter(Boolean);
    $('example-note').textContent = notes.join(' '); $('example-note').hidden = !notes.length;
    mode='code';$('visual-tab').hidden = false; tab(Boolean(entry.visualPath));
    $('source-path').textContent = entry.codePath; renderList(); setStatus('Loading source…'); $('run').disabled = true;
    const bytes = await provider.read(entry.codePath);
    if (token !== selecting) return;
    originalSource = decode(bytes); $('editor').value = codeDrafts.get(entry.id)||originalSource;
    visualSource=entry.visualPath?decode(await provider.read(entry.visualPath)):'';
    if(token!==selecting)return;
    $('output-footer').textContent = 'Each run starts with a fresh Lua environment.';
    $('run').disabled = false; setStatus('Ready to run'); draw();
  }
  async function run() {
    if (!provider || !entry) return;
    const visual=mode==='visual';if(visual&&!entry.visualPath)return;
    if(visual&&!$('example-inputs').reportValidity())return;
    const inputs=visual?collectInputs():{};
    dispose(); const token = generation; clearOutput(); setStatus('Loading LuaEx…'); $('run').disabled = true; $('stop').disabled = false;
    $('visual-tab').disabled=$('code-tab').disabled=true;
    const selected = entry, source = visual?visualSource:$('editor').value, started = performance.now();
    const file=visual?entry.visualPath:entry.codePath;
    try {
      const files = {}; let cursor = 0;
      await Promise.all(Array.from({length:12},async()=>{
        while (cursor < manifest.files.length) { const file = manifest.files[cursor++]; files[file] = await provider.read(file); }
      }));
      if (token !== generation) return;
      const bundle = window.LuaExExampleBundle;
      // One worker contains all its JavaScript. A file:// page has an opaque
      // origin, so nested blob importScripts/fetch calls are not reliable.
      const workerURL = URL.createObjectURL(new Blob([
        bundle.scripts.wasmoon, '\n;\n', bundle.scripts.runtime, '\n;\n', bundle.scripts.worker,
      ], {type:'text/javascript'}));
      objectURLs.push(workerURL);
      if (token !== generation) return;
      worker = new Worker(workerURL);
      worker.onmessage = event => {
        const message = event.data;
        if (message.type === 'output') { append(message.text); return; }
        const task = pending.get(message.id); if (!task) return;
        clearTimeout(task.timer); pending.delete(message.id);
        if (message.type === 'error') task.reject(Error(message.message)); else task.resolve(message.value);
      };
      worker.onerror = event => { append('Worker error: ' + event.message); dispose(); setStatus('Error'); };
      await request('boot',{files,wasmBytes:bytes(bundle.wasm)});
      if (token !== generation) return;
      setStatus('Executing…');
      if (visual) {
        state = await request('visual',{path:file,source,inputs}); update();
        append('LuaEx loaded. '+selected.title+' is running in Lua 5.4.');
      } else {
        const result = await request('run',{path:file,source,inputs});
        for (const file of result.files || []) {
          const label = document.createElement('span');
          label.textContent = 'Generated in memory: ' + file.name.split('/').pop();
          $('generated-files').append(label); $('generated-files').hidden = false;
        }
      }
      if (token !== generation) return;
      const elapsed = ((performance.now()-started)/1000).toFixed(2);
      setStatus(visual ? 'Running · Lua 5.4' : 'Completed · ' + elapsed + 's');
      $('output-footer').textContent = 'Lua 5.4 · fresh environment · completed in ' + elapsed + 's';
      if (!outputLines) append('Completed successfully. This example does not print output.');
    } catch(error) {
      if (token !== generation) return;
      append('ERROR\n' + error.message); setStatus('Example error'); pause();
      if (visual) { $(selected.visualType==='pool'?'pool-message':'map-message').textContent = error.message; tab(false); }
    } finally { if (token === generation){$('run').disabled = false;$('visual-tab').disabled=$('code-tab').disabled=false;} }
  }
  async function action(name,data = {}) {
    if (!state || !worker) return;
    const token=generation;
    try {
      const value = await request('action',{action:name,data});
      if(token!==generation)return;
      if (name === 'save') return value;
      state = value; update(); return state;
    } catch(error) { if(token!==generation)return;pause();window.PoolView.stop();append('ERROR\n' + error.message);$(entry?.visualType==='pool'?'pool-message':'map-message').textContent = error.message; }
  }
  function update() {
    if (!state) return;
    if(state.visual==='pool'){window.PoolView.render(state,action);return;}
    if(state.visual==='potentiometer'){window.PotView.render(state,action);return;}
    if(state.visual==='protean'){window.ProteanView.render(state,action);return;}
    if(state.visual==='stack'){window.StackView.render(state,action);return;}
    if(state.visual==='enum'){window.EnumView.render(state,action);return;}
    if(state.visual==='items'){window.ItemView.render(state,action);return;}
    if(state.visual==='cards'){window.CardView.render(state,action);return;}
    for (const name of ['turn','moves','nodes','turns']) $(name).textContent = state[name] ?? '—';
    $('speed').value = state.speed; $('speed-value').textContent = state.speed + ' / sec';
    $('map-message').textContent = state.status;
    $('auto-path').checked=state.autoPath;
    renderParty();
    document.querySelectorAll('[data-tool]').forEach(button => button.classList.toggle('selected',button.dataset.tool === state.tool));
    draw();
  }
  function renderParty() {
    const select=$('party-select');select.replaceChildren();
    for(const group of array(state.groups)){const option=document.createElement('option');option.value=group.id;option.textContent=group.name+' · '+group.count+' creatures';option.selected=group.id===state.activeGroup;select.append(option);}
    $('delete-party').disabled=array(state.groups).length<=1;$('new-party').disabled=array(state.groups).length>=6;
    const buttons=$('creature-buttons');buttons.replaceChildren();
    const profiles=array(state.profiles).sort((a,b)=>a.name.localeCompare(b.name));
    for(const profile of profiles){const button=document.createElement('button');button.append(icon(profile.icon),document.createTextNode('+ '+profile.name));button.disabled=array(state.members).length>=8;button.onclick=()=>{pause();action('addCreature',{kind:profile.kind});};buttons.append(button);}
    const members=$('party-members');members.replaceChildren();
    for(const member of array(state.members)) {
      const profile=profiles.find(item=>item.kind===member.kind);const card=document.createElement('div');card.className='creature-card';
      const title=document.createElement('div');title.className='creature-title';title.style.color=member.color;title.append(icon(member.icon));
      const name=document.createElement('strong');name.textContent=member.name+' #'+member.id;title.append(name);
      const remove=document.createElement('button');remove.textContent='×';remove.setAttribute('aria-label','Remove '+member.name+' #'+member.id);remove.onclick=()=>{pause();action('removeCreature',{id:member.id});};title.append(remove);card.append(title);
      const progress=document.createElement('progress');progress.max=member.capacity;progress.value=member.points;card.append(progress);
      const values=document.createElement('small');values.textContent=member.points+' / '+member.capacity+' MP · Route cost '+member.cost;card.append(values);
      const preferences=[];for(const [aspect,amount]of Object.entries(profile.affinities||{}))preferences.push(aspect.replace('rock','mountain')+' affinity '+Math.round(amount*100)+'%');
      for(const [aspect,amount]of Object.entries(profile.aversions||{}))preferences.push(aspect.replace('rock','mountain')+' aversion '+Math.round(amount*100)+'%');
      for(const aspect of Object.keys(profile.abhors||{}))preferences.push('Refuses '+aspect.replace('rock','mountain'));
      const traits=document.createElement('small');traits.textContent=preferences.join(' · ');card.append(traits);
      const regen=document.createElement('small');regen.textContent='+20 MP/turn · '+(profile.retain?'keeps unused points':'discards unused points')+(member.kind==='GOBLIN'?' · Can use caves':' · Cannot use cave ports');card.append(regen);members.append(card);
    }
    if(!array(state.members).length){const note=document.createElement('p');note.className='empty-party';note.textContent='Empty party. Add creatures above to plan a route.';members.append(note);}
    $('cave-status').textContent=array(state.caves).map(link=>'Cave '+link.pair+': ('+link.from.x+','+link.from.y+') ↔ ('+link.to.x+','+link.to.y+') · '+(link.allowed?'party allowed':'party cannot use')).join(' | ')||'Paint two cave entrances to create a passage.';
  }
  function draw() {
    const canvas = $('grid'), ctx = canvas.getContext('2d');
    ctx.fillStyle = '#e8ece1'; ctx.fillRect(0,0,canvas.width,canvas.height);
    if (!state) { ctx.fillStyle = '#81916b'; ctx.font = '18px Segoe UI'; ctx.textAlign = 'center'; ctx.fillText('Run the example to load the map',450,315); return; }
    const w = canvas.width / state.width, h = canvas.height / state.height;
    const cells = array(state.cells), routes = new Map(array(state.route).map(node=>[node.x+':'+node.y,node]));
    const trail = new Set(array(state.trail).map(node=>node.x+':'+node.y));
    for (let y=1;y<=state.height;y++) for(let x=1;x<=state.width;x++) {
      const px=(x-1)*w,py=(y-1)*h,route=routes.get(x+':'+y);
      ctx.fillStyle = palette[array(cells[y-1])[x-1]-1]; ctx.fillRect(px+1,py+1,w-2,h-2);
      canvasIcon(ctx,terrainIcons[array(cells[y-1])[x-1]-1],px+w/2,py+h/2,Math.min(w,h)*.55,'#526348');
      if (trail.has(x+':'+y)) {ctx.fillStyle='#abb8ac99';ctx.fillRect(px+6,py+6,w-12,h-12);}
      if(route && route.cycle !== undefined) {
        ctx.fillStyle = route.cycle===0?'#86b66b99':'#d8bb7699';ctx.fillRect(px+4,py+4,w-8,h-8);
        if(!(x===state.goal.x&&y===state.goal.y)&&!(x===state.rover.x&&y===state.rover.y)) {
          ctx.fillStyle='#4e5a37';ctx.font='12px Segoe UI';ctx.textAlign='center';ctx.fillText(String(route.cycle),px+w/2,py+h/2+4);
        }
      }
      if(x===state.goal.x&&y===state.goal.y)canvasIcon(ctx,'goal',px+w*.72,py+h*.35,24,'#3b5732');
    }
    ctx.save();ctx.setLineDash([6,5]);ctx.strokeStyle='#466e8b';ctx.lineWidth=2;
    for(const link of array(state.caves)){ctx.beginPath();ctx.moveTo((link.from.x-.5)*w,(link.from.y-.5)*h);ctx.lineTo((link.to.x-.5)*w,(link.to.y-.5)*h);ctx.stroke();}ctx.restore();
    for(const group of array(state.groups)){
      const active=group.id===state.activeGroup;const members=active?array(state.members):[];const x=(group.x-.5)*w,y=(group.y-.5)*h;
      ctx.beginPath();ctx.fillStyle=active?'#fffef3':'#dfe7e9';ctx.arc(x,y,Math.min(w,h)*.42,0,Math.PI*2);ctx.fill();ctx.strokeStyle=active?'#4b683b':'#819097';ctx.lineWidth=2;ctx.stroke();
      if(members.length){const member=members[0];canvasIcon(ctx,member.icon,x,y,25,member.color);ctx.font='bold 10px Segoe UI';ctx.fillStyle='#243721';ctx.textAlign='right';ctx.fillText(String(members.length),x+w*.4,y+h*.35);}
      else {ctx.fillStyle='#46563d';ctx.textAlign='center';ctx.font='bold 10px Segoe UI';ctx.fillText(active?'empty':String(group.count),x,y+3);}
    }
  }
  async function tick() {
    if (!playing || !state) return;
    const before = state.moves; await action('step');
    if (!state || state.moves === before || state.complete) { pause(); return; }
    playTimer = setTimeout(tick,1000/state.speed);
  }
  function togglePlay() { if (playing) pause(); else if (state && !state.complete) { playing=true; $('play').textContent='Ⅱ Pause'; tick(); } }
  function renderInputs() {
    const fields=$('input-fields');fields.replaceChildren();$('example-inputs').hidden=!entry.inputs?.length;
    for(const field of entry.inputs || []) {
      const label=document.createElement('label');label.textContent=field.label;
      const input=document.createElement(field.options?'select':'input');input.name=field.name;
      if(field.options)for(const option of field.options){const item=document.createElement('option');item.value=item.textContent=option;input.append(item);}
      else input.type=field.type==='boolean'?'checkbox':field.type==='number'?'number':'text';
      if(field.type==='boolean')input.checked=field.default;else input.value=String(field.default);
      for(const key of ['min','max','step','maxLength','pattern','required'])if(field[key]!==undefined)input[key]=field[key];
      input.dataset.valueType=field.type;label.append(input);fields.append(label);
    }
  }
  function collectInputs() {
    const result={};
    for(const input of $('input-fields').querySelectorAll('input,select')) {
      result[input.name]=input.dataset.valueType==='boolean'?input.checked:input.dataset.valueType==='number'?Number(input.value):input.value;
      if(input.dataset.valueType==='number'&&!Number.isFinite(result[input.name]))throw Error('Enter a finite number for '+input.name);
    }
    return result;
  }
  $('reset-inputs').onclick=renderInputs;
  $('example-inputs').onsubmit=event=>{event.preventDefault();run();};
  $('search').oninput = ()=>{if(manifest)renderList();};
  $('run').onclick = run; $('stop').onclick = ()=>{dispose();setStatus('Stopped');append('Stopped. Run again to start a fresh environment.');};
  $('visual-tab').onclick = ()=>tab(true); $('code-tab').onclick = ()=>tab(false);
  $('restore-source').onclick = ()=>$('editor').value=originalSource;
  $('clear-output').onclick = clearOutput; $('play').onclick = togglePlay;
  document.querySelectorAll('[data-action]').forEach(button=>button.onclick=()=>{pause();action(button.dataset.action);});
  document.querySelectorAll('[data-tool]').forEach(button=>button.onclick=()=>{pause();action('tool',{tool:button.dataset.tool});});
  $('speed').oninput = ()=>action('speed',{speed:Number($('speed').value)});
  $('party-select').onchange=()=>{pause();action('selectGroup',{id:Number($('party-select').value)});};
  $('new-party').onclick=()=>{pause();action('newGroup');};
  $('delete-party').onclick=()=>{pause();action('deleteGroup');};
  $('clear-party').onclick=()=>{pause();action('clearGroup');};
  $('auto-path').onchange=()=>{pause();action('autoPath',{enabled:$('auto-path').checked});};
  $('replan').onclick=()=>{pause();action('replan');};
  for(const button of document.querySelectorAll('[data-tool]'))button.prepend(icon(button.dataset.tool.toLowerCase()));
  $('save-map').onclick = async()=>{const saved=await action('save');if(saved){savedMap=saved.snapshot;$('load-map').disabled=false;$('map-message').textContent='Map saved in this page.';}};
  $('load-map').onclick = async()=>{if(savedMap){pause();await action('load',{snapshot:savedMap});}};
  // Coalesce drag events while a Lua request is pending; never queue unbounded paints.
  async function flushPaint() {
    while(nextPaint) {const paint=nextPaint;nextPaint=null;await action('paint',paint);}
    paintKey=null;
  }
  const canvas=$('grid');let dragging=false,nextTarget,targetPending=false,lastTarget='';
  function cell(event) {
    const bounds=canvas.getBoundingClientRect();return {x:Math.floor((event.clientX-bounds.left)/bounds.width*state.width)+1,y:Math.floor((event.clientY-bounds.top)/bounds.height*state.height)+1};
  }
  async function hoverGoal(event) {
    if(!state||!$('cursor-goal').checked)return;
    const point=cell(event);if(point.x<1||point.x>state.width||point.y<1||point.y>state.height)return;
    const key=point.x+':'+point.y;if(key===lastTarget)return;lastTarget=key;nextTarget=point;pause();
    if(targetPending)return;targetPending=true;const token=generation;
    try{while(nextTarget&&token===generation){const target=nextTarget;nextTarget=null;await action('target',target);}}
    finally{targetPending=false;nextTarget=null;}
  }
  $('cursor-goal').onchange=()=>{lastTarget='';if($('cursor-goal').checked)pause();};
  function paint(event) {
    if(!state)return;const bounds=canvas.getBoundingClientRect();
    const x=Math.floor((event.clientX-bounds.left)/bounds.width*state.width)+1;
    const y=Math.floor((event.clientY-bounds.top)/bounds.height*state.height)+1;
    if(x<1||x>state.width||y<1||y>state.height)return;
    const key=x+':'+y+':'+event.buttons;if(paintKey===key)return;
    nextPaint={x,y,erase:(event.buttons&2)!==0};pause();
    if(!paintKey){paintKey=key;flushPaint();}else paintKey=key;
  }
  canvas.oncontextmenu=event=>event.preventDefault();
  canvas.onpointerdown=event=>{event.preventDefault();canvas.focus();if($('cursor-goal').checked){hoverGoal(event);$('cursor-goal').checked=false;return;}dragging=true;canvas.setPointerCapture(event.pointerId);paint(event);};
  canvas.onpointermove=event=>{if($('cursor-goal').checked)hoverGoal(event);else if(dragging)paint(event);};
  canvas.onpointerup=canvas.onpointercancel=()=>{dragging=false;};
  document.addEventListener('keydown',event=>{
    if(event.ctrlKey&&event.key==='Enter'){event.preventDefault();run();return;}
    if(['TEXTAREA','INPUT'].includes(event.target.tagName)||mode!=='visual'||entry?.visualType!=='astar')return;
    if(event.code==='Space'){event.preventDefault();togglePlay();}
    if(event.code==='KeyN'){pause();action('step');}
    if(event.code==='KeyT'){pause();action('turn');}
  });
  document.addEventListener('visibilitychange',()=>{if(document.hidden)pause();});
  $('run').disabled=true;draw();
  initialize(makeProvider());
})();
