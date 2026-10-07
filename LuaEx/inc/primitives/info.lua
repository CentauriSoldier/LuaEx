--[[!
@fqxn LuaEx.Primitives
@desc
<pre style="overflow-x: auto;">
    <h1 class="text-center m-0 p-0" aria-label="Primitives" style="font-family: monospace; font-size: clamp(6px, 1.05vw, 16px); line-height: 1.15;">
        <span style="color: #FF6F61;">██████╗  ██████╗  ██╗ ███╗   ███╗ ██╗ ████████╗ ██╗ ██╗   ██╗ ███████╗ ███████╗</span>
        <span style="color: #FFAB00;">██╔══██╗ ██╔══██╗ ██║ ████╗ ████║ ██║ ╚══██╔══╝ ██║ ██║   ██║ ██╔════╝ ██╔════╝</span>
        <span style="color: #00C6FF;">██████╔╝ ██████╔╝ ██║ ██╔████╔██║ ██║    ██║    ██║ ██║   ██║ █████╗   ███████╗</span>
        <span style="color: #FF6F61;">██╔═══╝  ██╔══██╗ ██║ ██║╚██╔╝██║ ██║    ██║    ██║ ╚██╗ ██╔╝ ██╔══╝   ╚════██║</span>
        <span style="color: #FFAB00;">██║      ██║  ██║ ██║ ██║ ╚═╝ ██║ ██║    ██║    ██║  ╚████╔╝  ███████╗ ███████║</span>
        <span style="color: #00C6FF;">╚═╝      ╚═╝  ╚═╝ ╚═╝ ╚═╝     ╚═╝ ╚═╝    ╚═╝    ╚═╝   ╚═══╝   ╚══════╝ ╚══════╝</span>
    </h1>
</pre>

<p><strong>Primitives</strong> are small, table-like geometry objects with selected class-like behavior. They use metatables and hidden backing data rather than the LuaEx class system.</p>

<p>Geometry inputs are numbers. Read and write supported coordinates directly, such as <code>oCircle.center.x</code>, <code>oPoint.y</code> or <code>oLine.start.x</code>. Shape-defining values are writable; derived measurements are read-only and remain consistent with the shape. Invalid assignments leave existing values intact.</p>

<ul>
    <li><strong>point</strong>: a validated X/Y coordinate container.</li>
    <li><strong>line</strong>: a segment defined by two endpoints.</li>
    <li><strong>circle</strong>: a center and radius, with derived diameter, circumference and area.</li>
    <li><strong>circlearc</strong>: a center, radius and two angles in radians, with derived arc length and sector area.</li>
    <li><strong>ellipse</strong>: a center and full major/minor axis lengths, with exact area and approximate circumference.</li>
    <li><strong>polygon</strong>: an ordered numeric vertex sequence forming a simple boundary, with selectable positioning anchors and derived geometry.</li>
</ul>

<p>Shape primitives provide <code>autoUpdate</code> and <code>update()</code> controls. Reads refresh dirty results, and clean reads do not repeat calculations. Some shapes calculate candidates before mutation to validate them atomically. Point simply stores coordinates and needs no update control.</p>

<p>Primitives are intended for lightweight geometry in games and other frameworks. Their constructors use lowercase names. Collision queries belong in separate geometry helpers. Ordinary writes and metatable access are protected; deliberate use of Lua's <code>rawset</code> or debug tools can bypass those protections.</p>
!]]
