(() => {
 'use strict';
 const list=v=>Array.isArray(v)?v:Object.values(v||{}),$=id=>document.getElementById(id);
 const panel=document.createElement('section');panel.id='items-panel';panel.className='items-panel';panel.hidden=true;
 panel.innerHTML=`
 <header class="items-heading"><div><span class="items-eyebrow">COG · ITEM SYSTEM</span><h2>The quartermaster's table</h2><p>Four inventories. Twenty starter items. Every move checked by LuaEx.</p><small>Click to inspect · Drag to move for testing · Buy/Sell for actual trades</small></div><button id="items-reset" class="button subtle">Reset laboratory</button></header>
 <div class="items-actor-bar"><label>Act as <select id="items-actor" aria-label="Active item-system actor"></select></label><span id="items-actor-stats"></span><span id="items-total"></span><button id="items-validate" class="button subtle">Check consistency</button><button id="items-inspect" class="button subtle">Edit selected item ↓</button></div>
 <section class="items-persistence" aria-label="Save and load the laboratory"><div><strong>Save &amp; load</strong><p>Save all inventories, item edits and coins. Make changes, then load the snapshot. The caller reconnects container owners.</p><small id="items-save-status" role="status" aria-live="polite">No snapshot saved in this session.</small></div><div class="items-actions"><button id="items-save" class="button subtle">Save laboratory</button><button id="items-load" class="button subtle">Load saved laboratory</button></div></section>
 <p id="items-message" class="items-feedback" role="status" aria-live="polite"></p>
 <div class="items-layout"><div><div id="items-boards" class="items-boards"></div><section class="items-loose"><h3>Unplaced & attached items <span id="items-loose-count"></span></h3><p>Copies, rejected insertions and items taken out of storage stay here. Attached gems follow their host relationship.</p><div id="items-loose" class="items-card-list"></div></section></div>
 <aside class="items-inspector"><div class="items-inspector-head"><h3 id="items-selected-name">Select an item</h3><button id="items-new" class="button primary">New item</button></div><button id="items-back" class="text-button">↑ Back to inventories</button><p id="items-selected-location"></p><p id="items-selected-requirements"></p><small id="items-permission-actor"></small><div id="items-permissions" class="items-permissions"></div>
 <section id="items-action-area"><label>Destination <select id="items-destination"><option value="character">Character inventory</option><option value="stash">Selected stash tab</option><option value="ground">Ground</option><option value="shop">Shop</option><option value="unplaced">Unplaced / take out</option></select></label><label>Stash tab <select id="items-target-tab"></select></label><label>Character slot / anchor <select id="items-target-slot"></select></label><label class="items-check"><input id="items-replace" type="checkbox"> Replace first item if full</label>
 <div class="items-actions"><button data-item-action="move" class="button primary">Move (lab)</button><button data-item-action="equip" class="button subtle">Try equip</button><button data-item-action="unequip" class="button subtle">Try unequip</button><button data-item-action="swap" class="button subtle">Swap slots</button><button data-item-action="buy" class="button subtle">Buy</button><button data-item-action="sell" class="button subtle">Sell</button><button data-item-action="consume" class="button subtle">Consume</button><button data-item-action="unplace" class="button subtle">Take out</button></div>
 <label>Damage / repair amount <input id="items-amount" type="number" min="0" max="10000" value="10" step="any"></label><div class="items-actions"><button data-item-action="damage" class="button subtle">Damage</button><button data-item-action="repair" class="button subtle">Repair</button><button data-item-action="upgrade" class="button subtle">Upgrade</button><button data-item-action="downgrade" class="button subtle">Downgrade</button></div>
 <label>Attachment host <select id="items-host"></select></label><div class="items-actions"><button data-item-action="attach" class="button subtle">Attach gem</button><button data-item-action="detach" class="button subtle">Detach</button><button data-item-action="clone" class="button subtle">Copy item</button><button data-item-action="delete" class="button danger">Delete item</button></div><label class="items-check"><input id="items-override" type="checkbox"> Lab override for Inimitable copying</label>
 </section>
 <form id="items-editor"><div id="items-fields"></div><button id="items-apply" class="button primary">Apply item properties</button><span id="items-draft" class="items-draft"></span></form>
 </aside></div>
 <details class="items-guide" open><summary>How this lab uses the item system</summary><div class="items-guide-grid"><p><strong>Containment vs ownership.</strong> Location identifies the actual slot or stash tab. Container owner and the item's legal owner are shown separately. Move (lab), creation, editing and deletion are administrative test tools; Buy/Sell enforce actor permissions, affordability and the example's wallet policy.</p><p><strong>Whole-stash exclusivity.</strong> The two kites share the group <code>kite</code> and Exclusive_In points to this stash. Changing tabs cannot bypass the rule. Move the shop kite into any stash tab to see rejection; moving it to the character inventory is allowed.</p><p><strong>Grid or stacks.</strong> In grid mode, each footprint reserves relative cells from its anchor, so overlap and boundaries reject placement. Switch to stacks to hold separate instances per slot. Consuming one item leaves the others. An empty pattern uses one anchor cell.</p><p><strong>Permissions and effects.</strong> Try all buttons to read actual rejection reasons. Gems attach only to weapons and must first be taken out of storage. Zero durability never deletes an item. Upgrade effects, wallets, legal ownership and the decision to honor Inimitable are example policies.</p></div></details>
 <details class="items-history"><summary>Operation history</summary><pre id="items-events"></pre></details>`;
 $('visual-panel').after(panel);
 let send,state,busy=false,dirty=false,creating=false,lastID=null;
 const capacityDrafts=new Map();
 const icons={Weapon:'⚔',Armor:'◈',Potion:'⚗',Gem:'◆',Material:'▰',Relic:'✦',Quest:'⌘',Tool:'⚒'};
 const fmt=n=>Number(n).toLocaleString(undefined,{maximumFractionDigits:2});
 const el=(tag,cls,text)=>{const n=document.createElement(tag);if(cls)n.className=cls;if(text!==undefined)n.textContent=text;return n;};
 function button(text,fn,cls='button subtle'){const b=el('button',cls,text);b.type='button';b.onclick=fn;return b;}
 function options(select,values,key=v=>v,label=v=>v,selected=select.value){select.replaceChildren();for(const v of values){const o=el('option','',label(v));o.value=key(v);select.append(o);}if(values.some(v=>String(key(v))===String(selected)))select.value=selected;}
 function selected(){return state?.selected&&state.selected.id?state.selected:null;}
 async function act(name,data={}){
  if(!send||busy)return;
  busy=true;availability();
  try{return await send(name,data);}finally{busy=false;availability();}
 }
 function availability(){for(const b of panel.querySelectorAll('button'))b.disabled=!send||!state||busy||(b.id==='items-load'&&!state?.persistence?.saved)||((b.hasAttribute('data-item-action')||b.id==='items-apply')&&!creating&&!selected());}
 function card(item,compact=false){
  const b=button('',async()=>{creating=false;dirty=false;await act('select',{id:item.id});if(window.matchMedia('(max-width:1150px)').matches)panel.querySelector('.items-inspector').scrollIntoView({block:'start'});},'items-card '+(item.id===state.selectedID?'selected ':'')+item.kind.toLowerCase());b.title=`#${item.id} ${item.name}\n${item.location}\nLegal owner: ${item.ownerName}\n${item.config.description}`;
  const symbol=el('span','items-icon',icons[item.kind]);symbol.setAttribute('aria-hidden','true');
  b.draggable=true;b.ondragstart=e=>{e.dataTransfer.setData('text/plain',String(item.id));e.dataTransfer.effectAllowed='move';};
  const body=el('span','items-card-body');body.append(el('strong','',item.name));
  if(!compact){body.append(el('small','',`${item.kind} · ${item.ownerName}`));body.append(el('small','',`${fmt(item.value)} coins · ${fmt(item.weight)} weight · ${fmt(item.health)}/${fmt(item.maximum)} durability`));if(item.where==='attached')body.append(el('small','',item.location));}
  const marker=el('span','items-card-id','#'+item.id);b.append(symbol,body,marker);
  if(item.config.group||item.config.inimitable){const flag=el('span','items-card-rule',item.config.inimitable?'Bound':item.config.group);b.append(flag);}
  return b;
 }
 function dropTarget(node,key,slot){
  node.ondragover=e=>{if(!busy){e.preventDefault();e.dataTransfer.dropEffect='move';node.classList.add('drop-target');}};
  node.ondragleave=e=>{if(!node.contains(e.relatedTarget))node.classList.remove('drop-target');};
  node.ondrop=e=>{e.preventDefault();e.stopPropagation();node.classList.remove('drop-target');const id=Number(e.dataTransfer.getData('text/plain'));if(!list(state.items).some(i=>i.id===id))return;act('move',{id,destination:key,slot:slot||Number($('items-target-slot').value),replace:$('items-replace').checked});};
 }
 function flags(box,key,current){
  const controls=el('div','items-container-flags');
  for(const [field,label] of [['enabled','Enabled'],['locked','Locked']]){
   const l=el('label','items-check'),input=el('input');input.type='checkbox';input.checked=current[field];input.setAttribute('aria-label',key+' '+label);
   input.onchange=()=>act('container',{key,enabled:field==='enabled'?input.checked:current.enabled,locked:field==='locked'?input.checked:current.locked});l.append(input,document.createTextNode(label));controls.append(l);
  }box.append(controls);
 }
 function capacity(box,key,value,slot){
  const draftKey=key+':'+(slot||state.tab||0),form=el('form','items-capacity'),label=el('label','',key==='character'?'Slot '+slot+' capacity':'Capacity');
  const input=el('input');input.type='number';input.min='1';input.max='80';input.step='1';input.required=true;input.value=capacityDrafts.get(draftKey)??value;input.setAttribute('aria-label',key+' capacity');input.oninput=()=>capacityDrafts.set(draftKey,input.value);
  const apply=el('button','button subtle','Apply');label.append(input);form.append(label,apply);
  form.onsubmit=async e=>{e.preventDefault();if(!form.reportValidity())return;const result=await act('capacity',{key,capacity:Number(input.value),slot});if(result?.ok){capacityDrafts.delete(draftKey);renderBoards();availability();}};box.append(form);
 }
 function renderBoards(){
  const boards=$('items-boards');boards.replaceChildren();const items=list(state.items),byID=new Map(items.map(v=>[v.id,v]));
  for(const [key,title,owner] of [['character','Character inventory','Adventurer'],['stash','Tabbed stash','Adventurer'],['ground','Ground inventory','No container owner'],['shop','Shop inventory','Merchant']]){
   const box=el('section','items-board '+key),heading=el('div','items-board-heading');heading.append(el('h3','',title),el('span','items-count',String(state.totals[key])));box.append(heading,el('p','items-owner','Container owner: '+owner));flags(box,key,state.containers[key]);
   if(key!=='character')dropTarget(box,key);
   if(key==='character'){
    const mode=el('label','items-check'),toggle=el('input');toggle.type='checkbox';toggle.checked=state.grid;toggle.onchange=()=>act('grid',{enabled:toggle.checked});mode.append(toggle,document.createTextNode('Grid footprints · 4 × 4'));box.append(mode);
    const grid=el('div','items-inventory-grid');grid.setAttribute('aria-label','Character inventory slots');
    for(const slot of list(state.slots)){
     const cell=el('div','items-cell'+(slot.locked?' locked':'')+(!slot.enabled?' disabled':''));cell.append(el('small','items-cell-number',String(slot.index)));
     dropTarget(cell,key,slot.index);
     const ids=list(slot.ids);
     for(const id of ids){const item=byID.get(id);if(item)cell.append(card(item,true));}
     if(!ids.length){const empty=button('+',()=>{$('items-target-slot').value=slot.index;renderBoards();availability();},'items-empty-slot');empty.title='Use slot '+slot.index+' as destination';empty.setAttribute('aria-label','Choose empty destination slot '+slot.index);cell.append(empty);}
     if(!state.grid)cell.append(el('small','items-slot-count',slot.count+'/'+slot.capacity));grid.append(cell);
    }box.append(grid);
    const settings=el('details','items-board-settings');settings.append(el('summary','','Target slot settings'));
    const slot=list(state.slots).find(s=>s.index===Number($('items-target-slot').value))||list(state.slots)[0];capacity(settings,key,slot.capacity,slot.index);
    const lock=el('label','items-check'),lockInput=el('input');lockInput.type='checkbox';lockInput.checked=slot.locked;lockInput.onchange=()=>act('slotState',{slot:slot.index,enabled:slot.enabled,locked:lockInput.checked});lock.append(lockInput,document.createTextNode('Lock target slot '+slot.index));
    const enabled=el('label','items-check'),enabledInput=el('input');enabledInput.type='checkbox';enabledInput.checked=slot.enabled;enabledInput.onchange=()=>act('slotState',{slot:slot.index,enabled:enabledInput.checked,locked:slot.locked});enabled.append(enabledInput,document.createTextNode('Enable target slot'));settings.append(lock,enabled,el('small','','In grid mode each cell permits one footprint, regardless of its stack capacity.'));box.append(settings);
   }else{
    if(key==='stash'){
     const tabs=el('div','items-stash-tabs');tabs.setAttribute('aria-label','Stash tabs');
     for(const tab of list(state.tabs)){const b=button('Tab '+tab.index+' · '+tab.count+'/'+tab.capacity,()=>act('tab',{tab:tab.index}),'items-tab'+(tab.index===state.tab?' active':''));b.setAttribute('aria-pressed',String(tab.index===state.tab));tabs.append(b);}box.append(tabs);
     const nav=el('div','items-actions');nav.append(button('+ Tab',()=>act('addTab')),button('Remove empty tab',()=>act('removeTab')));box.append(nav);
     const tab=list(state.tabs).find(t=>t.index===state.tab);capacity(box,key,tab.capacity);
    }else capacity(box,key,state.capacities[key]);
    const cards=el('div','items-card-list');for(const item of items.filter(i=>i.where===key&&(key!=='stash'||i.index===state.tab)))cards.append(card(item));if(!cards.children.length)cards.append(el('p','items-empty','Empty — move or create an item here.'));box.append(cards);
   }
   box.append(button('Clear → unplaced',()=>act('clear',{key}),'items-clear'));boards.append(box);
  }
  const loose=items.filter(i=>i.where==='unplaced'||i.where==='attached');$('items-loose-count').textContent=loose.length;$('items-loose').replaceChildren(...loose.map(i=>card(i)));if(!loose.length)$('items-loose').append(el('p','items-empty','None. New items and copies can be created here.'));
 }
 const fieldDefs=[
  ['Identity & ownership',[['name','Name','text'],['kind','Kind','select','kinds'],['owner','Legal owner','select','owners'],['rarity','Rarity index','select','rarities'],['description','Description','text']]],
  ['Pools & prerequisites',[['durabilityMax','Maximum durability','number',1,10000],['durability','Current durability','number',0,10000],['value','Value / shop price','number',0,10000],['weight','Weight','number',0,1000],['size','Size value','number',0,1000],['level','Required level','number',1,100],['strength','Required strength','number',0,100],['race','Allowed race','select','races']]],
  ['Storage, exclusivity & coordinates',[['storage','Storable_In','select','storage'],['exclusive','Exclusive_In','select','scopes'],['group','Exclusive_With group key','text'],['pattern','Relative coordinates: x,y; x,y','text']]],
  ['Action registries & metadata',[['consumable','Consumable_By','checkbox'],['equipable','Equipable_By / Unequippable_By','checkbox'],['damageable','Damageable_By','checkbox'],['repairable','Repairable_By','checkbox'],['removable','Removable_By','checkbox'],['tradableBy','Tradable_By','checkbox'],['tradableTo','Tradable_To','checkbox'],['upgradeable','Upgradeable_By','checkbox'],['downgradable','Downgradable_By','checkbox'],['detachable','Detachable_By','checkbox'],['inimitable','Inimitable (caller metadata)','checkbox']]]
 ];
 for(const [title,fields] of fieldDefs){
  const details=el('details','items-editor-section');details.open=title==='Identity & ownership';details.append(el('summary','',title));const group=el('div','items-field-grid');
  for(const [key,label,type,min,max] of fields){const l=el('label',type==='checkbox'?'items-check':''),input=el(type==='select'?'select':'input');input.id='item-field-'+key;input.name=key;
   if(type!=='select')input.type=type;if(type==='number'){input.min=min;input.max=max;input.step=key==='level'?'1':'any';input.required=true;}if(type==='text'){input.maxLength=key==='description'?300:key==='pattern'?300:key==='group'?40:80;if(key==='name')input.required=true;}
   if(type==='checkbox')l.append(input,document.createTextNode(label));else l.append(document.createTextNode(label),input);group.append(l);
  }details.append(group);$('items-fields').append(details);
 }
 function populateChoices(){
  for(const [,fields] of fieldDefs)for(const [key,,type,source] of fields)if(type==='select'){
   const values=source==='owners'?['none',...list(state.actors).map(a=>a.key)]:source==='rarities'?Array.from({length:state.choices.rarities},(_,i)=>i+1):list(state.choices[source]);
   options($('item-field-'+key),values,v=>v,v=>source==='owners'?(v==='none'?'Unowned':list(state.actors).find(a=>a.key===v).name):source==='rarities'?v+' · '+list(state.choices.rarityNames)[v-1]:v);
  }
 }
 function fill(config){for(const [,fields] of fieldDefs)for(const [key,,type] of fields){const input=$('item-field-'+key);if(type==='checkbox')input.checked=Boolean(config[key]);else input.value=config[key];}}
 function collect(){const config={};for(const [,fields] of fieldDefs)for(const [key,,type] of fields){const input=$('item-field-'+key);config[key]=type==='checkbox'?input.checked:type==='number'||key==='rarity'?Number(input.value):input.value;}return config;}
 function inspector(){
  const item=selected();
  if(!creating&&item?.id!==lastID){dirty=false;lastID=item?.id??null;if(item){populateChoices();fill(item.config);}}
  if(!creating&&item&&!dirty)fill(item.config);
  $('items-selected-name').textContent=creating?'Create an item':item?item.name:'Select an item';
  $('items-selected-location').textContent=creating?'Set properties, choose a destination, then Create.':item?`#${item.id} · ${item.location} · Legal owner: ${item.ownerName}`:'Click an item in any inventory or create a new one.';
  $('items-selected-requirements').textContent=item&&!creating?`Requires level ${item.config.level}, strength ${item.config.strength}, race ${item.config.race}. Pattern: ${item.footprint} coordinates. ${item.config.group?'Exclusive group '+item.config.group+' in '+item.config.exclusive+'. ':''}${list(item.attachments).length?'Attachments: '+list(item.attachments).join(', ')+'. ':''}${item.config.description}`:'';
  $('items-permission-actor').textContent=item&&!creating?'CoGRegistry eligibility for '+list(state.actors).find(a=>a.key===state.actor).name:'';
  $('items-editor').hidden=!creating&&!item;$('items-action-area').hidden=creating||!item;
  $('items-apply').textContent=creating?'Create item':'Apply item properties';$('items-draft').textContent=dirty?'Unsaved changes':'';
  const permissions=$('items-permissions');permissions.replaceChildren();
  if(item&&!creating){for(const [key,label] of [['canEquip','Equip'],['canConsume','Consume'],['canRemove','Remove'],['canTradeBy','Trade by'],['canTradeTo','Trade to'],['canDamage','Damage'],['canRepair','Repair'],['canUpgrade','Upgrade'],['canDetach','Detach']])permissions.append(el('span',item[key]?'pass':'fail',label+': '+(item[key]?'yes':'no')));}
  const host=$('items-host'),old=host.value;options(host,list(state.items).filter(i=>i.id!==item?.id&&i.kind==='Weapon'),i=>i.id,i=>i.name,old);
 }
 $('items-editor').oninput=()=>{dirty=true;$('items-draft').textContent='Unsaved changes';};
 $('items-editor').onsubmit=async e=>{e.preventDefault();const form=$('items-editor');if(!form.reportValidity())return;const config=collect();const result=await act(creating?'create':'edit',{id:selected()?.id,config,destination:$('items-destination').value,slot:Number($('items-target-slot').value)});if(result?.ok){creating=false;dirty=false;lastID=null;inspector();availability();}};
 $('items-new').onclick=()=>{if(!state||!send)return;creating=true;dirty=false;populateChoices();fill(state.defaults);inspector();availability();$('item-field-name').focus();};
 $('items-reset').onclick=()=>{dirty=false;creating=false;lastID=null;capacityDrafts.clear();act('reset');};
 $('items-save').onclick=()=>act('save');
 $('items-load').onclick=async()=>{const result=await act('load');if(result?.ok){dirty=false;creating=false;lastID=null;capacityDrafts.clear();inspector();renderBoards();availability();}};
 $('items-validate').onclick=()=>act('validate');$('items-actor').onchange=()=>act('actor',{key:$('items-actor').value});
 $('items-target-tab').onchange=()=>act('tab',{tab:Number($('items-target-tab').value)});
 $('items-inspect').onclick=()=>panel.querySelector('.items-inspector').scrollIntoView({block:'start'});
 $('items-back').onclick=()=>$('items-boards').scrollIntoView({block:'start'});
 $('items-target-slot').onchange=()=>{if(state)renderBoards();availability();};
 for(let i=1;i<=16;i++){const o=el('option','',`Slot ${i} · (${(i-1)%4}, ${Math.floor((i-1)/4)})`);o.value=i;$('items-target-slot').append(o);}$('items-target-slot').value='13';
 for(const b of panel.querySelectorAll('[data-item-action]'))b.onclick=()=>{
  if(!selected())return;let name=b.dataset.itemAction;const destination=$('items-destination').value;if(name==='move'&&destination==='unplaced')name='unplace';
  if(['damage','repair'].includes(name)&&!$('items-amount').reportValidity())return;
  act(name,{id:selected().id,destination,slot:Number($('items-target-slot').value),replace:$('items-replace').checked,amount:Number($('items-amount').value),host:Number($('items-host').value),override:$('items-override').checked});
 };
 window.ItemView={dispose(){send=null;dirty=false;creating=false;lastID=null;state=null;busy=false;capacityDrafts.clear();availability();},render(value,action){
  state=value;send=action;options($('items-actor'),list(state.actors),a=>a.key,a=>a.name,state.actor);options($('items-target-tab'),list(state.tabs),t=>t.index,t=>'Tab '+t.index+' · '+t.count+'/'+t.capacity,state.tab);const actor=list(state.actors).find(a=>a.key===state.actor);
  $('items-actor-stats').textContent=`${actor.race} · Level ${actor.level} · Strength ${actor.strength} · ${fmt(actor.coins)} coins`;$('items-total').textContent=`${state.totals.live} live · ${state.totals.retired} consumed/deleted`;
  const snapshot=state.persistence;$('items-save-status').textContent=snapshot?.saved?`Saved in this session · ${fmt(snapshot.bytes/1024)} KiB${snapshot.ownersReconnected?' · Loaded owners reconnected by the caller':''}`:'No snapshot saved in this session.';
  $('items-message').textContent=state.message;$('items-message').classList.toggle('rejected',!state.ok);renderBoards();inspector();availability();$('items-events').textContent=list(state.events).slice().reverse().join('\n');
 }};
 availability();
})();
