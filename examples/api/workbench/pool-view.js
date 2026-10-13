(() => {
 'use strict';let send,running=false,timer,resources=[];
 const $=id=>document.getElementById(id),fmt=n=>Number(n).toLocaleString(undefined,{maximumFractionDigits:2});
 const fields=[['maximum','Base maximum',1,10000],['current','Current',0,100000000],['flat','Reserved points',0,10000],['percent','Reserved %',0,100],['regen','Regen / cycle',-10000,10000],['regenPercent','Regen % of max',-10000,10000],['bonus','Capacity bonus',0,10000],['multiplier','Capacity bonus %',0,10000],['low','Low marker %',0,100],['high','High marker %',0,100]];
 const panel=document.createElement('section');panel.id='pool-panel';panel.className='pool-panel';panel.hidden=true;
 panel.innerHTML='<div class="pool-intro"><div><h2>Vital resources</h2><p>Spend, reserve and regenerate. All calculations run in LuaEx.</p></div><button id="pool-reset" class="button subtle">Reset resources</button></div><div id="pool-cards" class="pool-cards"></div><div class="pool-cycle"><button id="pool-cycle" class="button primary">Advance cycle</button><label>Cycles <input id="pool-cycle-count" type="number" min="0" max="100" step="any" value="1" required></label><button id="pool-auto" class="button subtle">Start auto regen</button><span id="pool-tick">Cycle 0</span></div><p id="pool-message" aria-live="polite"></p><div class="pool-explanation"><strong>How to read the meters</strong><p>Color is current resource. The striped area is reserved capacity. Dark space is available but empty. Full fills available capacity, so a reserved globe never fills its entire circle.</p><p>Maximum = (base + bonus) × (1 + bonus %). Reserved = flat + maximum × reserved %. Regen = flat + maximum × regen %. Percentages always use total maximum.</p></div><details class="pool-event-box"><summary>Pool event log</summary><pre id="pool-events"></pre></details>';
 document.getElementById('visual-panel').after(panel);
 function stop(){running=false;clearTimeout(timer);$('pool-auto').textContent='Start auto regen';}
 async function act(name,data={}){if(send)return send(name,data);}
 async function cycle(){const input=$('pool-cycle-count');if(!input.reportValidity())return;return act('cycle',{multiplier:Number(input.value)});}
 async function automatic(){if(!running)return;await act('cycle',{multiplier:1});if(running)timer=setTimeout(automatic,1000);}
 $('pool-reset').onclick=()=>{stop();for(const card of $('pool-cards').children){delete card.dataset.dirty;delete card.dataset.editVersion;}act('reset');};$('pool-cycle').onclick=cycle;
 $('pool-auto').onclick=()=>{if(!send)return;if(running)stop();else{running=true;$('pool-auto').textContent='Pause auto regen';automatic();}};
 document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
 function card(resource){
  const key=resource.key;const element=document.createElement('article');element.className='resource-card '+key;element.dataset.resource=key;
  element.innerHTML='<h3>'+resource.name+'</h3><div class="resource-display '+(key==='stamina'?'stamina-meter':'resource-globe')+'" role="meter" aria-label="'+resource.name+' resource"><div class="resource-liquid"></div><div class="resource-reserved"></div><div class="resource-shine"></div><div class="resource-readout"></div></div><p class="resource-status"></p><div class="resource-stats"></div><label class="resource-range-label">Current <input class="resource-range" type="range" min="0" step="any" aria-label="'+resource.name+' current slider"></label><div class="resource-actions"><label>Amount <input class="resource-amount" type="number" min="0" max="10000" step="any" value="10" required aria-label="'+resource.name+' action amount"></label><button data-pool-action="spend">Spend</button><button data-pool-action="restore">Restore</button><button data-pool-action="empty">Empty</button><button data-pool-action="fill">Full</button></div><details class="resource-settings"><summary>'+resource.name+' settings</summary><form class="resource-config"><div class="resource-fields"></div><button class="button subtle" type="submit">Apply '+resource.name+' settings</button></form></details>';
  const form=element.querySelector('form'),container=element.querySelector('.resource-fields');
  for(const [name,label,min,max]of fields){const wrapper=document.createElement('label');wrapper.textContent=label;const input=document.createElement('input');input.name=name;input.type='number';input.min=min;input.max=max;input.step='any';input.required=true;input.setAttribute('aria-label',resource.name+' '+label);wrapper.append(input);container.append(wrapper);}
  const feedback=document.createElement('p');feedback.setAttribute('aria-live','polite');feedback.className='pool-settings-feedback';form.append(feedback);
  form.oninput=()=>{stop();element.dataset.dirty='true';element.dataset.editVersion=String(Number(element.dataset.editVersion||0)+1);feedback.textContent='Unsaved settings';};
  form.onsubmit=async event=>{
   event.preventDefault();stop();if(!form.reportValidity())return;
   const config=Object.fromEntries(fields.map(([name])=>[name,Number(form.elements.namedItem(name).value)])),version=element.dataset.editVersion;
   feedback.textContent='Applying settings…';
   const result=await act('configure',{key,config});if(!result)return;
   if(result.message.startsWith('Rejected:')){feedback.textContent=result.message;return;}
   if(element.dataset.editVersion===version){
    const updated=(Array.isArray(result.resources)?result.resources:Object.values(result.resources)).find(r=>r.key===key);
    for(const [name]of fields)form.elements.namedItem(name).value=updated.config[name];
    delete element.dataset.dirty;feedback.textContent='Settings applied';
   }else feedback.textContent='Settings applied; newer edits are still unsaved';
  };
  element.querySelector('.resource-range').oninput=event=>{stop();act('current',{key,value:Number(event.target.value)});};
  for(const button of element.querySelectorAll('[data-pool-action]'))button.onclick=()=>{const input=element.querySelector('.resource-amount');if(!input.reportValidity())return;act(button.dataset.poolAction,{key,amount:Number(input.value)});};
  return element;
 }
 window.PoolView={stop,dispose(){stop();send=null;},render(state,action){
  send=action;resources=Array.isArray(state.resources)?state.resources:Object.values(state.resources||{});
  const cards=$('pool-cards');
  if(!cards.children.length)for(const resource of resources)cards.append(card(resource));
  for(const r of resources){
   const element=cards.querySelector('[data-resource="'+r.key+'"]'),display=element.querySelector('.resource-display');
   display.style.setProperty('--filled',(r.maximum>0?r.current/r.maximum*100:0)+'%');display.style.setProperty('--reserved',(r.maximum>0?r.reserved/r.maximum*100:0)+'%');
   display.setAttribute('aria-valuemin','0');display.setAttribute('aria-valuemax',r.maximum);display.setAttribute('aria-valuenow',r.current);display.setAttribute('aria-valuetext',fmt(r.current)+' current, '+fmt(r.reserved)+' reserved, '+fmt(r.maximum)+' maximum');
   element.querySelector('.resource-readout').textContent=fmt(r.current)+' / '+fmt(r.maximum);
   element.querySelector('.resource-status').textContent=r.empty?'Empty':r.full?'Full (available capacity)':r.low?'Low':r.high?'High':'In balance';
   element.querySelector('.resource-stats').textContent='Available '+fmt(r.available)+' · Reserved '+fmt(r.reserved)+' · Regen '+fmt(r.cycle)+'/cycle';
   const slider=element.querySelector('.resource-range');slider.max=r.available;if(document.activeElement!==slider)slider.value=r.current;
   const form=element.querySelector('form');
   if(element.dataset.dirty!=='true')for(const [name]of fields)form.elements.namedItem(name).value=r.config[name];
  }
  $('pool-message').textContent=state.message;$('pool-tick').textContent='Cycle '+fmt(state.tick);
  $('pool-events').textContent=(Array.isArray(state.events)?state.events:Object.values(state.events||{})).slice().reverse().join('\n');
 }};
})();
