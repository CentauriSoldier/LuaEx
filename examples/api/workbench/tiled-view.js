(() => {
    'use strict';
    const $ = id => document.getElementById(id);
    const panel = document.createElement('section');
    panel.id = 'tiled-panel';
    panel.className = 'visual-panel tiled-panel';
    panel.hidden = true;
    panel.innerHTML = `
        <div class="tiled-heading"><div><span class="eyebrow">TMX → TILED → ASTAR</span><h2>Tiled terrain explorer</h2><p>Square and both hex grids. Native rovers, terrain costs and goblin-only caves.</p></div></div>
        <div class="tiled-toolbar">
            <label>Map <select id="tiled-map"><option value="square">Square</option><option value="hex-flat">Flat-top hex</option><option value="hex-pointy">Pointy-top hex</option></select></label>
            <label>Creature <select id="tiled-creature"><option value="SCOUT">Scout</option><option value="GOBLIN">Goblin</option></select></label>
            <label>Click a tile to <select id="tiled-tool"><option value="goal">Set destination</option><option value="grass">Paint grass</option><option value="mud">Paint mud</option><option value="wall">Paint wall</option></select></label>
        </div>
        <div class="tiled-layout"><div class="tiled-board"><svg id="tiled-svg" role="group" aria-label="Editable Tiled map"></svg></div>
        <aside class="tiled-inspector"><h3 id="tiled-profile">Scout</h3>
            <label>Mud affinity <input id="tiled-affinity" type="range" min="0" max="1" step="0.05"><output id="tiled-affinity-value"></output></label>
            <label>Mud aversion <input id="tiled-aversion" type="range" min="0" max="1" step="0.05"><output id="tiled-aversion-value"></output></label>
            <dl><dt>Movement points</dt><dd id="tiled-points"></dd><dt>Route cost</dt><dd id="tiled-cost"></dd><dt>Moves / turn</dt><dd id="tiled-progress"></dd><dt>Cave passage</dt><dd id="tiled-caves"></dd></dl>
            <p>Affinities reduce terrain cost; aversions increase it. Only goblins can use the paired cave ports.</p>
        </aside></div>
        <div class="tiled-actions"><button class="button primary" id="tiled-step">Step</button><button class="button" id="tiled-turn">Next turn</button><button class="button" id="tiled-reset">Reset map</button><button class="button" id="tiled-save">Download TMX</button></div>
        <p id="tiled-message" role="status"></p>
        <div class="tiled-legend"><span><i class="grass"></i>Grass</span><span><i class="mud"></i>Mud</span><span><i class="wall"></i>Wall</span><span><i class="route"></i>Planned route</span><span>◇ Cave</span><span>◎ Destination</span></div>
        <p class="tiled-note">Terrain or destination edits rebuild navigation and return the rover to spawn. Download includes map properties and cave links; the goblin-only passage predicate belongs to this program. Keep the matching sample TSX/PNG beside the downloaded map.</p>`;
    $('visual-panel').after(panel);
    const ns = 'http://www.w3.org/2000/svg';
    const list = value => Array.isArray(value) ? value : Object.values(value || {});
    let state, send, busy = false;

    function svg(tag, attributes, text) {
        const node = document.createElementNS(ns, tag);
        for (const [name, value] of Object.entries(attributes || {})) node.setAttribute(name, value);
        if (text !== undefined) node.textContent = text;
        return node;
    }

    function availability() {
        for (const node of panel.querySelectorAll('button,select,input')) node.disabled = busy || !send;
        $('tiled-step').disabled = busy || !send || !state?.hasPath || state?.complete;
        for (const cell of panel.querySelectorAll('[data-cell]')) cell.setAttribute('aria-disabled', String(busy || !send));
    }

    async function act(name, payload = {}) {
        if (busy || !send) return;
        busy = true;
        availability();
        try { return await send(name, payload); }
        finally { busy = false; availability(); }
    }

    function footprint(cell) {
        const w = state.tilewidth / 2, h = state.tileheight / 2, side = state.side / 2;
        let points = [[-w, -h], [w, -h], [w, h], [-w, h]];
        if (state.orientation === 'hexagonal') {
            points = state.axis === 'x'
                ? [[-w, 0], [-side, -h], [side, -h], [w, 0], [side, h], [-side, h]]
                : [[0, -h], [w, -side], [w, side], [0, h], [-w, side], [-w, -side]];
        }
        return points.map(([x, y]) => `${cell.px + x},${cell.py + y}`).join(' ');
    }

    function draw() {
        const board = $('tiled-svg');
        const cells = list(state.cells);
        const byPosition = new Map(cells.map(cell => [`${cell.x}:${cell.y}`, cell]));
        const width = Math.max(...cells.map(cell => cell.px)) + state.tilewidth / 2 + 12;
        const height = Math.max(...cells.map(cell => cell.py)) + state.tileheight / 2 + 12;
        board.setAttribute('viewBox', `-12 -12 ${width + 12} ${height + 12}`);
        board.replaceChildren();
        for (const cell of cells) {
            const group = svg('g', {'data-cell': `${cell.x}:${cell.y}`, role: 'button', tabindex: 0});
            const terrain = ({1: 'Grass', 2: 'Mud', 3: 'Wall'})[cell.gid] || 'Empty';
            const description = `${terrain} at ${cell.x}, ${cell.y}. ${cell.passable ? `Entry cost ${cell.cost}` : 'Blocked'}`;
            group.setAttribute('aria-label', description);
            group.append(svg('title', {}, description), svg('polygon', {points: footprint(cell), class: `tiled-cell terrain-${cell.gid}`}));
            group.append(svg('text', {x: cell.px, y: cell.py + 4, class: 'tiled-cell-label'}, `${cell.x},${cell.y}`));
            const click = () => act('cell', {x: cell.x, y: cell.y});
            group.onclick = click;
            group.onkeydown = event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); click(); } };
            board.append(group);
        }
        const route = list(state.route);
        if (route.length > 1) board.append(svg('polyline', {points: route.map(cell => `${cell.px},${cell.py}`).join(' '), class: 'tiled-route'}));
        for (const cave of list(state.caves)) {
            const cell = byPosition.get(`${cave.x}:${cave.y}`);
            board.append(svg('text', {x: cell.px, y: cell.py + 8, class: 'tiled-marker cave'}, '◇'));
        }
        const goal = byPosition.get(`${state.goal.x}:${state.goal.y}`);
        board.append(svg('circle', {cx: goal.px, cy: goal.py, r: 13, class: 'tiled-goal'}));
        const rover = byPosition.get(`${state.rover.x}:${state.rover.y}`);
        board.append(svg('circle', {cx: rover.px, cy: rover.py, r: 14, class: `tiled-rover ${state.creature.toLowerCase()}`}));
        board.append(svg('text', {x: rover.px, y: rover.py + 5, class: 'tiled-rover-label'}, state.creature === 'GOBLIN' ? 'G' : 'S'));
    }

    $('tiled-map').onchange = () => act('map', {sample: $('tiled-map').value});
    $('tiled-creature').onchange = () => act('creature', {creature: $('tiled-creature').value});
    $('tiled-tool').onchange = () => act('tool', {tool: $('tiled-tool').value});
    for (const id of ['tiled-affinity', 'tiled-aversion']) {
        $(id).onchange = () => act('responses', {affinity: Number($('tiled-affinity').value), aversion: Number($('tiled-aversion').value)});
        $(id).oninput = () => $(id + '-value').textContent = Number($(id).value).toFixed(2);
    }
    $('tiled-step').onclick = () => act('step');
    $('tiled-turn').onclick = () => act('turn');
    $('tiled-reset').onclick = () => act('reset');
    $('tiled-save').onclick = async () => {
        const result = await act('save');
        if (!result?.xml) return;
        const url = URL.createObjectURL(new Blob([result.xml], {type: 'application/xml'}));
        const link = document.createElement('a');
        link.href = url;
        link.download = result.name;
        link.click();
        setTimeout(() => URL.revokeObjectURL(url), 1000);
    };

    window.TiledView = {
        dispose() { send = null; state = null; busy = false; availability(); },
        render(value, action) {
            state = value;
            send = action;
            $('tiled-map').value = state.sample;
            $('tiled-creature').value = state.creature;
            $('tiled-tool').value = state.tool;
            $('tiled-profile').textContent = state.creature === 'GOBLIN' ? 'Goblin' : 'Scout';
            for (const key of ['affinity', 'aversion']) {
                $('tiled-' + key).value = state[key];
                $('tiled-' + key + '-value').textContent = state[key].toFixed(2);
            }
            $('tiled-points').textContent = state.points.toFixed(1);
            $('tiled-cost').textContent = state.hasPath ? state.cost.toFixed(2) : 'No route';
            $('tiled-progress').textContent = `${state.moves} / ${state.turn}`;
            $('tiled-caves').textContent = state.cavesAllowed ? 'Allowed' : 'Goblin only';
            $('tiled-message').textContent = state.message;
            draw();
            availability();
        },
    };
    availability();
})();
