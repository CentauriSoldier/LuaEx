/* Vehicle rendering reads plain snapshots; every state change runs in Lua. */
(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const list = value => Array.isArray(value) ? value : Object.values(value || {});
  const flags = ['unmanned', 'tradeable', 'quest', 'exclusive', 'inimitable'];
  const panel = document.createElement('section');
  panel.id = 'vehicles-panel';
  panel.hidden = true;
  panel.innerHTML = `
    <header class="vehicles-heading"><div><small>THE EXPEDITION COLLECTION</small><h2>The vehicle garage</h2><p>Land, sky and water. Inspect the objects behind the adventure.</p></div><button class="button subtle" data-vehicle-action="reset">Reset garage</button></header>
    <div id="vehicles-fleet" class="vehicles-fleet"></div>
    <p id="vehicles-message" class="vehicles-message" role="status" aria-live="polite"></p>
    <div class="vehicles-layout"><section class="vehicles-card">
      <small>LIVE TELEMETRY</small><h3 id="vehicles-title"></h3><p id="vehicles-description"></p>
      <div id="vehicles-stats" class="vehicles-stats"></div>
      <label for="vehicles-fuel">Fuel remaining</label><meter id="vehicles-fuel" min="0" max="100"></meter><p id="vehicles-range"></p>
      <div class="vehicles-controls"><label>Fuel units <input id="vehicles-amount" type="number" value="10" step="any"></label><button class="button subtle" data-vehicle-action="refuel">Add / spend fuel</button><button class="button subtle" data-vehicle-action="reserve">Set reserved capacity</button></div>
      <div class="vehicles-controls"><label>Trip distance (km) <input id="vehicles-distance" type="number" min="0" value="40" step="any"></label><button class="button primary" data-vehicle-action="drive">Take a trip</button></div>
      <p class="vehicles-note">Trips consume distance ÷ efficiency. Speed estimates minimum travel time. This is example policy; BaseVehicle itself does not move. Reservation removes usable tank capacity.</p>
      <h3>Component workshop</h3><p>Configured slots contain actual objects. Here, each component is a Pool representing condition.</p><div id="vehicles-components"></div>
      <p class="vehicles-note">Share installs the first other vehicle’s component reference. Damage then appears in both inspectors. Install new creates a fresh object. Empty slots contain null.</p>
      <h3>Identity & inherited features</h3><p id="vehicles-identity"></p>
      <div class="vehicles-controls"><label>Tag <input id="vehicles-tag" value="expedition" maxlength="80"></label><button class="button subtle" data-vehicle-action="tag">Add tag</button><button class="button subtle" data-vehicle-action="untag">Remove tag</button></div><p id="vehicles-tags"></p>
      <button class="button subtle" data-vehicle-action="event">Dispatch inspection event</button>
    </section><section class="vehicles-card">
      <small>CONSTRUCTOR LAB</small><h3>Build your specification</h3><p>Base fields have getters. Apply constructs a replacement while retaining fuel, components and owner references.</p>
      <form id="vehicles-form" class="vehicles-form"><label>Name <input name="name" required maxlength="80"></label><label>Description <textarea name="description" required maxlength="500"></textarea></label><div class="vehicles-fields"><label>Efficiency (km/unit) <input name="efficiency" type="number" min="0" step="any" required></label><label>Max speed (km/h) <input name="speed" type="number" min="0" step="any" required></label><label>Value <input name="value" type="number" min="0" step="any" required></label><label>Rarity <select name="rarity" id="vehicles-rarity"></select></label></div><label>Event environment <select name="environment"><option value="_ENV">Framework default</option><option value="ExampleGarageWorkshop">Workshop environment</option></select></label><div id="vehicles-flags" class="vehicles-flags"></div><label><input name="unowned" type="checkbox"> Clear owner</label><button class="button primary">Apply specification</button></form>
      <p class="vehicles-note">Tradeable includes selling. Quest, exclusive, unmanned and inimitable are metadata; applications enforce their rules. Owner is an optional class instance. No Sellable field exists.</p>
      <h3>Copy & contract probes</h3><div class="vehicles-probes"><button class="button primary" data-vehicle-action="clone">Clone concrete vehicle</button><button class="button subtle" data-vehicle-action="baseclone">Try base-class clone</button><button class="button subtle" data-vehicle-action="snapshot">Test component snapshot</button><button class="button subtle" data-vehicle-action="serialize">Test native serialization</button></div>
      <p class="vehicles-note">Concrete copies own independent fuel, components and tags, retain the same owner, and start a fresh trip counter. Inspection callbacks are freshly installed with a zero count. Affixes and other event hooks are outside this example’s clone policy. Native serialization currently encounters inherited Eventrix state; the probe reports the actual result.</p>
      <label>Invalid input <select id="vehicles-invalid"><option value="speed">Negative speed</option><option value="flag">String instead of boolean</option><option value="fuel">Table instead of Pool</option><option value="slot">Unknown component slot</option><option value="component">Table instead of component object</option></select></label><button class="button subtle" data-vehicle-action="invalid">Run validation probe</button>
      <details><summary>What belongs to BaseVehicle?</summary><p>Validated constructor inputs, inherited BaseObject identity and rarity, owner and fuel references, five flags, value, speed, efficiency, configured component accessors and independent binding snapshots. Concrete subclasses must implement __clone. Vehicle movement, condition, trading restrictions and display art are application choices.</p><p>The event environment is the optional final constructor argument. Choose the default or a registered workshop environment, apply, then dispatch an inspection to observe the callback environment. Inherited affix support is unfinished in BaseObject and is not presented as a working vehicle feature.</p></details>
    </section></div><details class="vehicles-history" open><summary>Operation journal</summary><pre id="vehicles-history"></pre></details>`;
  $('visual-panel').after(panel);
  let state, send, busy = false, dirty = false, selectedID;
  const form = $('vehicles-form');
  const node = (tag, text, className) => {
    const element = document.createElement(tag);
    if (text !== undefined) element.textContent = text;
    if (className) element.className = className;
    return element;
  };
  for (const flag of flags) {
    const label = node('label');
    const input = document.createElement('input');
    input.type = 'checkbox'; input.name = flag;
    label.append(input, document.createTextNode(' ' + flag[0].toUpperCase() + flag.slice(1)));
    $('vehicles-flags').append(label);
  }
  function availability() {
    for (const element of panel.querySelectorAll('button, input, textarea, select')) element.disabled = busy || !send;
  }
  async function act(action, payload = {}) {
    if (!send || busy) return;
    busy = true; availability();
    try { return await send(action, payload); }
    finally { busy = false; availability(); }
  }
  for (const button of panel.querySelectorAll('[data-vehicle-action]')) {
    button.onclick = () => {
      let action = button.dataset.vehicleAction;
      const payload = {};
      if (action === 'refuel' || action === 'reserve') {
        if (!$('vehicles-amount').reportValidity()) return;
        payload.amount = Number($('vehicles-amount').value);
        if (action === 'refuel') action = 'fuel';
      }
      if (action === 'drive') {
        if (!$('vehicles-distance').reportValidity()) return;
        payload.distance = Number($('vehicles-distance').value);
      }
      if (action === 'tag' || action === 'untag') {
        payload.tag = $('vehicles-tag').value; payload.remove = action === 'untag'; action = 'tag';
      }
      if (action === 'invalid') payload.test = $('vehicles-invalid').value;
      if (action === 'reset' || action === 'clone') dirty = false;
      act(action, payload);
    };
  }
  form.oninput = () => { dirty = true; };
  form.onsubmit = async event => {
    event.preventDefault();
    if (!form.reportValidity()) return;
    const payload = {};
    for (const key of ['name', 'description', 'rarity', 'environment']) payload[key] = form.elements[key].value;
    for (const key of ['efficiency', 'speed', 'value']) payload[key] = Number(form.elements[key].value);
    for (const key of [...flags, 'unowned']) payload[key] = form.elements[key].checked;
    const result = await act('rebuild', payload);
    if (result && !result.message.startsWith('Rejected:')) { dirty = false; fill(result.selected); }
  };
  function fill(vehicle) {
    for (const key of ['name', 'description', 'efficiency', 'speed', 'value', 'rarity', 'environment']) form.elements[key].value = vehicle[key];
    for (const key of flags) form.elements[key].checked = vehicle[key];
    form.elements.unowned.checked = vehicle.owner === 'Unowned';
  }
  window.VehicleView = {
    dispose() { state = send = undefined; busy = dirty = false; selectedID = undefined; availability(); },
    render(value, action) {
      state = value; send = action;
      const vehicle = state.selected;
      const fleet = $('vehicles-fleet'); fleet.replaceChildren();
      for (const item of list(state.fleet)) {
        const button = node('button', undefined, 'vehicles-tile' + (item.id === vehicle.id ? ' selected' : ''));
        button.type = 'button'; button.setAttribute('aria-pressed', String(item.id === vehicle.id));
        const image = document.createElement('img');
        image.src = 'data:image/png;base64,' + window.LuaExExampleBundle.files['examples/resources/vehicles/' + item.image + '.png'];
        image.alt = ({rover:'Amber expedition rover in the mountains', airship:'Teal cargo airship over a mountain valley', skiff:'Indigo survey skiff on a turquoise lake'})[item.image];
        button.append(image, node('strong', item.name), node('span', `${item.image.toUpperCase()} · ${Number(item.fuel).toFixed(1)} / ${item.capacity} fuel`));
        button.onclick = () => { dirty = false; act('select', {id:item.id}); };
        fleet.append(button);
      }
      $('vehicles-message').textContent = state.message;
      $('vehicles-message').classList.toggle('rejected', state.message.startsWith('Rejected:'));
      $('vehicles-title').textContent = vehicle.name;
      $('vehicles-description').textContent = vehicle.description;
      const stats = $('vehicles-stats'); stats.replaceChildren();
      for (const [label, amount] of [['km / unit',vehicle.efficiency],['km / h max',vehicle.speed],['value',vehicle.value],['km travelled',vehicle.distance]]) {
        const stat = node('div'); stat.append(node('strong', Number(amount).toLocaleString(undefined,{maximumFractionDigits:2})), node('small',label)); stats.append(stat);
      }
      $('vehicles-fuel').max = vehicle.capacity; $('vehicles-fuel').value = vehicle.fuel;
      $('vehicles-range').textContent = `${Number(vehicle.fuel).toFixed(2)} / ${vehicle.capacity} units · ${vehicle.reserved} reserved · ${(vehicle.fuel * vehicle.efficiency).toFixed(1)} km range`;
      $('vehicles-identity').textContent = `ExampleGarageVehicle → BaseVehicle → BaseObject → CoG. Rarity: ${vehicle.rarity}. Owner: ${vehicle.owner}. Inspections: ${vehicle.inspections}. ${vehicle.lastEnvironment}.`;
      $('vehicles-tags').textContent = 'Tags: ' + (list(vehicle.tags).join(', ') || 'none');
      const components = $('vehicles-components'); components.replaceChildren();
      for (const component of list(vehicle.components)) {
        const row = node('div', undefined, 'vehicles-component');
        row.append(node('strong', component.slot), node('span', component.installed ? `${component.condition}% condition` : 'Empty · null'));
        for (const [operation, label] of [['install','Install new'],['remove','Remove'],['damage','Damage −25'],['repair','Repair +25'],['share','Share from other']]) {
          const button = node('button', label, 'button subtle');
          button.type = 'button'; button.onclick = () => act('component', {slot:component.slot,operation}); row.append(button);
        }
        components.append(row);
      }
      if (!$('vehicles-rarity').options.length) for (const rarity of list(state.rarities)) {
        const option = node('option', rarity); option.value = rarity; $('vehicles-rarity').append(option);
      }
      if (!dirty || selectedID !== vehicle.id) { fill(vehicle); dirty = false; }
      selectedID = vehicle.id;
      $('vehicles-history').textContent = list(state.events).slice().reverse().join('\n\n');
      availability();
    },
  };
  availability();
})();
