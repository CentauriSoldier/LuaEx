/* The inspector displays Lua snapshots. All catalog operations run in Lua. */
(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const list = value => Array.isArray(value) ? value : Object.values(value || {});
  const panel = document.createElement('section');
  panel.id = 'textcatalog-panel';
  panel.hidden = true;
  panel.innerHTML = `
    <header class="tc-heading"><div><small>WORDS FOR YOUR WORLD</small><h2>The dialogue desk</h2><p>One catalog, many voices. Find the wording, change the context.</p></div><button type="button" class="button subtle" data-tc-action="reset">Reset example</button></header>
    <div id="tc-conversations" class="tc-conversations"></div>
    <p id="tc-message" class="tc-message" role="status" aria-live="polite"></p>
    <div class="tc-layout"><aside class="tc-card tc-browser"><small>CATALOG BROWSER</small><h3>Nodes & text</h3><p class="tc-hint">Choose a node to make it active. Choose a text entry to inspect its template.</p><button id="tc-root" type="button" class="tc-tree-node">/ Root</button><div id="tc-tree"></div><p class="tc-hint">This navigation list is ordered for readability. Search results follow the library’s unspecified first-match order.</p></aside>
    <div class="tc-workspace"><section class="tc-card"><div class="tc-section-heading"><div><small>ACTIVE NODE</small><h3 id="tc-active">/ Root</h3></div><button type="button" class="button subtle" data-tc-action="resetactive">Reset to root</button></div>
    <form id="tc-active-form" class="tc-inline"><label>Full node path <input id="tc-active-input" placeholder="dialogue.merchant" autocomplete="off"></label><button class="button subtle">Set active node</button></form>
    <div class="tc-section-heading"><h3>Look up & search</h3><button type="button" class="button subtle" data-tc-action="snapshot">Test snapshot isolation</button></div>
    <form id="tc-lookup-form"><div class="tc-fields"><label>Public method <select id="tc-method"><option value="gettext">gettext · exact text key</option><option value="findtext" selected>findtext · stored text substring</option><option value="findnode">findnode · node-name substring</option><option value="getnode">getnode · full node snapshot</option></select></label><label>Key or search text <input id="tc-query" value="traveler" autocomplete="off"></label></div>
    <label class="tc-check"><input id="tc-use-active" type="checkbox" checked> Omit scope: use the active node</label><label>Explicit scope from root <input id="tc-scope" placeholder="Empty = root; or dialogue.merchant" autocomplete="off"></label><button class="button primary">Run lookup</button></form>
    <div class="tc-result"><div class="tc-section-heading"><strong id="tc-result-heading">Last call result</strong><code id="tc-result-path"></code></div><pre id="tc-result">Run a lookup to see its return value.</pre></div>
    <p class="tc-hint">Paths and searches ignore case. Search text is literal: try <code>100%?</code> or <code>[gold]</code>. Matching happens before substitutions. No match returns nil plus the valid scope path; an invalid scope returns nil, nil. An empty search matches the first eligible entry.</p>
    </section><section class="tc-card"><small>TEXT INSPECTOR</small><h3 id="tc-edit-path">Select a text entry</h3><form id="tc-edit-form"><label>Stored template <textarea id="tc-template" maxlength="2000" rows="3" spellcheck="false"></textarea></label><button class="button primary">settext · apply wording</button></form><label>Rendered now <output id="tc-rendered" class="tc-preview"></output></label><p class="tc-hint">The selected full path is edited from the root. Only existing text entries can change; node structure stays fixed. Empty wording is allowed.</p></section>
    <section class="tc-card"><div class="tc-section-heading"><div><small>PUBLIC PERSISTENCE</small><h3>Save, change, restore</h3></div></div><div class="tc-actions"><button type="button" class="button primary" data-tc-action="checkpoint">serialize · checkpoint</button><button type="button" class="button subtle" data-tc-action="restore">deserialize · restore</button><button type="button" class="button subtle" data-tc-action="clone">Clone into other conversation</button></div><p class="tc-hint">Saved data contains raw templates, variables and active scope. Restoration creates an independent catalog through the global deserialize function. Clone replaces the other conversation and selects it.</p><details><summary>Serialized checkpoint</summary><pre id="tc-saved">No checkpoint yet.</pre></details></section></div>
    <aside class="tc-card tc-variables"><small>PERSISTENT CONTEXT</small><h3>Variables</h3><p class="tc-hint">Each conversation owns its variables. Every future get or snapshot uses the latest values.</p><div id="tc-variables"></div><form id="tc-variable-form"><label>Name <input id="tc-variable-name" value="friend" maxlength="80" required autocomplete="off"></label><label>String value <input id="tc-variable-value" value="Elian" maxlength="500" autocomplete="off"></label><button class="button primary">setvar</button><button id="tc-clear-variable" type="button" class="button subtle">clearvar</button></form><button type="button" class="button subtle" data-tc-action="clearvars">clearvars · remove all</button><button type="button" class="button subtle" data-tc-action="nochain">Try friend = player placeholder</button><p class="tc-hint">Choose <code>dialogue.merchant.contact</code>, then try the button above. The inserted player placeholder stays literal. Missing variables remain visible, and escaped placeholders are never replaced.</p><h3>Contract probes</h3><label>Expected failure <select id="tc-probe"><option value="insert">Add a new text entry</option><option value="node">Replace a node with text</option><option value="variable">Use a numeric variable value</option><option value="active">Activate a missing node</option><option value="duplicate">Create case-only duplicate keys</option></select></label><button type="button" class="button subtle" data-tc-action="probe">Run rejection probe</button></aside></div>
    <details class="tc-journal"><summary>Operation journal</summary><pre id="tc-history"></pre></details>`;
  $('visual-panel').after(panel);
  let state, send, busy = false, dirty = false, selectionKey;
  const node = (tag, text, className) => {
    const element = document.createElement(tag);
    if (text !== undefined) element.textContent = text;
    if (className) element.className = className;
    return element;
  };
  function availability() {
    for (const element of panel.querySelectorAll('button, input, textarea, select')) element.disabled = busy || !send;
    $('tc-scope').disabled = busy || !send || $('tc-use-active').checked;
    $('tc-query').disabled = busy || !send || $('tc-method').value === 'getnode';
    panel.querySelector('[data-tc-action="restore"]').disabled = busy || !send || !state?.saved;
  }
  async function act(action, payload = {}) {
    if (busy || !send) return;
    busy = true; availability();
    try { return await send(action, payload); }
    finally { busy = false; availability(); }
  }
  $('tc-use-active').onchange = availability;
  $('tc-method').onchange = availability;
  $('tc-root').onclick = () => act('active', {path:''});
  $('tc-active-form').onsubmit = event => { event.preventDefault(); act('active', {path:$('tc-active-input').value}); };
  $('tc-lookup-form').onsubmit = event => {
    event.preventDefault();
    act('inspect', {method:$('tc-method').value, query:$('tc-query').value, useactive:$('tc-use-active').checked, scope:$('tc-scope').value});
  };
  $('tc-template').oninput = () => { dirty = true; };
  $('tc-edit-form').onsubmit = async event => {
    event.preventDefault();
    const result = await act('settext', {text:$('tc-template').value});
    if (result && !result.message.startsWith('Rejected:')) { dirty = false; $('tc-template').value = result.selection.template; }
  };
  $('tc-variable-form').onsubmit = event => {
    event.preventDefault();
    act('setvar', {name:$('tc-variable-name').value, value:$('tc-variable-value').value});
  };
  $('tc-clear-variable').onclick = () => act('clearvar', {name:$('tc-variable-name').value});
  for (const button of panel.querySelectorAll('[data-tc-action]')) button.onclick = () => {
    const action = button.dataset.tcAction;
    if (['reset','restore','clone'].includes(action)) dirty = false;
    if (action === 'resetactive') act('active', {reset:true});
    else if (action === 'probe') act(action, {test:$('tc-probe').value});
    else if (action === 'nochain') act('setvar', {name:'friend', value:'${player}'});
    else act(action);
  };
  window.TextCatalogView = {
    dispose() { state = send = undefined; busy = dirty = false; selectionKey = undefined; availability(); },
    render(value, action) {
      state = value; send = action;
      $('tc-message').textContent = state.message;
      $('tc-message').classList.toggle('rejected', state.message.startsWith('Rejected:'));
      $('tc-active').textContent = state.active || '/ Root';
      $('tc-root').classList.toggle('active', state.active === '');
      const conversations = $('tc-conversations'); conversations.replaceChildren();
      for (const catalog of list(state.catalogs)) {
        const button = node('button', undefined, 'tc-conversation' + (catalog.id === state.selected ? ' selected' : ''));
        button.type = 'button'; button.setAttribute('aria-pressed', String(catalog.id === state.selected));
        button.append(node('strong', catalog.name), node('span', catalog.greeting));
        button.onclick = () => { dirty = false; act('select', {id:catalog.id}); };
        conversations.append(button);
      }
      const tree = $('tc-tree'); tree.replaceChildren();
      for (const entry of list(state.rows).sort((a,b) => a.path.localeCompare(b.path))) {
        const button = node('button', undefined, 'tc-tree-node ' + entry.kind + (entry.kind === 'node' && entry.path === state.active ? ' active' : '') + (entry.kind === 'text' && entry.path === state.selection.path ? ' selected' : ''));
        button.type = 'button'; button.style.paddingLeft = (10 + entry.depth * 12) + 'px';
        button.title = entry.path; button.setAttribute('aria-label', entry.kind + ': ' + entry.path); button.append(node('span', entry.kind === 'node' ? '▸ ' : '· '), node('span', entry.name));
        button.onclick = () => {
          if (entry.kind === 'node') act('active', {path:entry.path});
          else { dirty = false; act('selecttext', {path:entry.path}); }
        };
        tree.append(button);
      }
      const variables = $('tc-variables'); variables.replaceChildren();
      for (const variable of list(state.variables).sort((a,b) => a.name.localeCompare(b.name))) {
        const button = node('button', undefined, 'tc-variable'); button.type = 'button';
        button.append(node('code', variable.name), node('span', JSON.stringify(variable.value)));
        button.onclick = () => { $('tc-variable-name').value = variable.name; $('tc-variable-value').value = variable.value; };
        variables.append(button);
      }
      if (!list(state.variables).length) variables.append(node('p', 'No bindings. Placeholders remain visible.', 'tc-hint'));
      const selection = state.selection;
      $('tc-edit-path').textContent = selection.path;
      const nextKey = state.selected + ':' + selection.path;
      if (!dirty || nextKey !== selectionKey) { $('tc-template').value = selection.template; dirty = false; }
      selectionKey = nextKey;
      $('tc-rendered').textContent = selection.rendered === '' ? '(empty string)' : selection.rendered;
      const result = state.result;
      $('tc-result-heading').textContent = result.kind === 'none' ? 'Last call result' : result.found ? 'Matched result · snapshot of that call' : 'No match';
      $('tc-result-path').textContent = result.kind === 'none' ? '' : result.path === undefined ? 'path: nil' : 'path: ' + (result.path || '/ Root');
      $('tc-result').textContent = result.kind === 'none' ? 'Run a lookup to see its return value.' : !result.found ? 'nil' : result.kind === 'node' ? JSON.stringify(result.value, null, 2) : JSON.stringify(result.value);
      $('tc-saved').textContent = state.saved || 'No checkpoint yet.';
      $('tc-history').textContent = list(state.history).slice().reverse().join('\n\n');
      availability();
    },
  };
  availability();
})();
