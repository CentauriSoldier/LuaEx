return [[
<div align="center">
  <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx Logo">
</div>

<hr>
<h2 id="🆆🅷🅰🆃-🅸🆂-🅻🆄🅰🅴🆇❓-🔬">🆆🅷🅰🆃 🅸🆂 🅻🆄🅰🅴🆇❓ 🔬</center></h2>
<p>Simply put, <strong>LuaEx</strong> is a lightweight overhaul of Lua that extends its functionality.</p>
<p>Below are some of the <a href="#features">🅵🅴🅰🆃🆄🆁🅴🆂</a>
in <strong>LuaEx</strong> (<em>See documentation for full details</em>).</p>
<h2 id="🅶🅴🆃🆃🅸🅽🅶-🆂🆃🅰🆁🆃🅴🅳-🚀">🅶🅴🆃🆃🅸🅽🅶 🆂🆃🅰🆁🆃🅴🅳 🚀</h2>
<p>In order to push all the code in <strong>LuaEx</strong> into the global environment, place the <strong>LuaEx</strong> folder into your package path and run the following code:</p>
<pre><code class="language-lua">require(&quot;LuaEx.init&quot;);
</code></pre>
<p>From here on out, all modules of <strong>LuaEx</strong> will be available in the global environment.</p>
<h2 id="🆅🅴🆁🆂🅸🅾🅽-⚗">🆅🅴🆁🆂🅸🅾🅽 ⚗</h2>
<h4 id="current-version-beta-v090">Current Version: Beta v0.90</h4>
<details>
<summary>🆅🅸🅴🆆 🅲🅷🅰🅽🅶🅴🅻🅾🅶</summary>

<h3 id="🇨🇭🇦🇳🇬🇪🇱🇴🇬">🇨​​​​​🇭​​​​​🇦​​​​​🇳​​​​​🇬​​​​​🇪​​​​​🇱​​​​​🇴​​​🇬​​​​​</h3>
<p><strong>v0.91</strong> <em><strong>(IN PROGRESS)</strong></em></p>
<ul>
<li>Bugfix:  <strong>Structfactory</strong> not properly cloning itself.</li>
<li>Bugfix:  <strong>Structs</strong> not properly cloning internal objects.</li>
<li>Bugfix:  Instance returns in parent class were not properly returning child instance when subclassed.</li>
<li>Bugfix:  Dox &quot;Copy&quot; button not working.</li>
<li>Change:  Dox now places all output into a single HTML file instead of using a separate <em>.js</em> file.</li>
<li>Change:  Dox CSS redesigned to be more functional and aesthetically pleasing.</li>
<li>Feature: Dox now allows custom intro page message.</li>
<li>Feature: Subclassing is now able to be limited to certain subclass types by providing either a blacklist or whitelist.</li>
<li>Feature Added several class-level checks:<ul>
<li><strong>class.of</strong></li>
<li><strong>class.getname</strong></li>
<li><strong>class.getbase</strong></li>
<li><strong>class.is</strong></li>
<li><strong>class.isbase</strong></li>
<li><strong>class.ischild</strong></li>
<li><strong>class.ischildorself</strong></li>
<li><strong>class.isdirectchild</strong></li>
<li><strong>class.isdirectparent</strong></li>
<li><strong>class.isinlineage</strong></li>
<li><strong>class.isinstance</strong></li>
<li><strong>class.isinstanceof</strong></li>
<li><strong>class.isparent</strong></li>
<li><strong>class.isparentorself</strong></li>
</ul>
</li>
<li>Feature: Classes now fully respect polymorphism in assignment operation type checking.</li>
<li>Feature: The class constructor may now be either private, protected or public.</li>
<li>Feature: Classes now have an <em>optional</em> static constructor using the class name as the static method name.</li>
<li>Feature: Dox comment blocks can now use anchor links (<em>#</em>) to other FQXNs.</li>
<li>Feature: added Dox output back navigation.</li>
<li>Feature: Dox now uses <strong>prism.js</strong> for displaying code blocks with syntax highlighting for all available <strong>prism.js</strong> languages.</li>
<li>Feature: added a &quot;Copy&quot; (to clipboard) button to all user-created code blocks.</li>
<li>Feature: added a <strong>Code</strong> <em><strong>BlockTag</strong></em> to Dox, permitting code examples with any user-specified <strong>prism.js</strong> language.</li>
<li>Feature: <strong>Example</strong> <em><strong>BlockTag</strong></em> now automatically detects the <strong>prism.js</strong> language based on the Dox subclass being used.</li>
<li>Feature: <strong>prism.js</strong> scripts are automatically added to Dox&#39;s finalized HTML output based on the languages used in the documentation.</li>
<li>Feature: added Dox parsers (subclasses) for several new languages.</li>
</ul>
<p><strong>v0.90</strong></p>
<ul>
<li>Bugfix:  error in <em><strong>type.assert.table</strong></em> where value type was showing as index type, resulting in false negatives.</li>
<li>Bugfix:  error in <strong>SortedDictionary</strong> causing malformed returns.</li>
<li>Bugfix:  fatal bug in cloner preventing the cloning of items.</li>
<li>Change:  rewrote and completed the interface system for classes.</li>
<li>Feature: added support for code html tags using <strong>prism.js</strong> in <strong>Dox</strong> module.</li>
<li>Feature: added several new features to <strong>Dox</strong> and prepped it for major updates in future releases.</li>
<li>Feature: added <em><strong>type.assert.function</strong></em>.</li>
<li>Feature: all items in tables are now properly cloned.</li>
<li>Feature: class tables are now cloned so class instances may now start with clonable objects as default properties.</li>
</ul>
<p><strong>v0.83</strong></p>
<ul>
<li>Bugfix:   various, minor bugs.</li>
<li>Bugfix:   major bug in class auto directive causing malformed classes.</li>
<li>Feature:  reorganized and added sections and examples to README.</li>
<li>Feature:  integrated and rewrote Dox documentation module and added support for other languages.</li>
<li>Refactor: restructured module layout and added more examples to the <strong>examples</strong> directory.</li>
</ul>
<p><strong>v0.82</strong></p>
<ul>
<li>Bugfix:   various, minor bugs.</li>
<li>Feature:  created new <strong>Ini.lua</strong> module.</li>
<li>Feature:  created new <strong>base64.lua</strong> module.</li>
<li>Feature:  created <strong>cloner.lua</strong> module. Updated various, existing items to make them clonable.</li>
<li>Feature:  created new <strong>serializer.lua</strong> module that handles serialization and deserialization.</li>
<li>Feature:  added serval examples in the <strong>examples</strong> directory for demonstrating usage.</li>
<li>Change:   removed old <strong>ini.lua</strong> module.</li>
<li>Change:   removed old <strong>base64.lua</strong> module.</li>
<li>Change:   modified <strong>cloner</strong> to work with custom, user-created objects.</li>
<li>Change:   removed old <strong>serialize.lua</strong> and <strong>deserialize.lua</strong> modules.</li>
<li>Change:   modified the serializer to work with custom, user-created objects.</li>
<li>Change:   modified the cloner to work with custom, user-created objects.</li>
<li>Change:   modified <strong>init.lua</strong> to provide some user options for class loading.</li>
<li>Change:   changed all class names to PascalCase to provide clear distinction between class variables and other variables.</li>
<li>Refactor: moved several items in the directory structure</li>
</ul>
<p><strong>v0.81</strong></p>
<ul>
<li>Bugfix: renamed the <strong>__LUAEX__</strong> table reference in the <strong>enum</strong> module that got missed.</li>
<li>Change: removed class system from <strong>v0.8</strong> as it had a fatal, uncorrectable flaw.</li>
<li>Change: rewrote the class system again from scratch, avoiding fatal flaw in previous system.</li>
<li>Change: renamed <em><strong>type.x</strong></em> to <em><strong>type.ex</strong></em> and <em><strong>typex</strong></em> to <em><strong>typeex</strong></em> to more clearly indicate the check refers to <strong>LuaEx</strong> types.</li>
<li>Change: set types for factories. (E.g., print(type(class)); --&gt; classfactory)</li>
<li>Change: removed static protected members from the class system as using them is, almost always, an anti-pattern.</li>
<li>Change: class members are now strongly typed.</li>
<li>Change: <em><strong>temporarily</strong></em> disabled compulsory classes until they&#39;re refactored for new class system.</li>
<li>Change: <em><strong>temporarily</strong></em> removed class interfaces until it&#39;s rewritten to operate with the new class system.</li>
<li>Change: cleaned up and reorganized a lot of the files in the <strong>LuaEx</strong> module.</li>
</ul>
<p><strong>v0.80</strong></p>
<ul>
<li>Change:   rewrote the class system from scratch.</li>
<li>Change:   renamed <strong>__LUAEX__</strong> global table <strong>luaex</strong>.</li>
<li>Feature:  added class interfaces.</li>
<li>Feature:  class system now uses full encapsulation (static protected, static public, private, protected and public fields &amp; methods).</li>
<li>Feature:  <strong>luaex</strong> table now contains a <strong>_VERSION</strong> variable.</li>
<li>Refactor: moved various modules to different directories.</li>
</ul>
<p><strong>v0.70</strong></p>
<ul>
<li>Change:   enum items now use functions (.) instead of methods (:) and automatically input themselves as arguments.</li>
<li>Change:   enum items&#39; <em><strong>next</strong></em> and <em><strong>previous</strong></em> functions <em>may</em> now wrap around to the start and end respectively.</li>
<li>Change:   renamed functions in various modules to conform with Lua&#39;s lowercase naming convention.</li>
<li>Change:   improved the <em><strong>string.totable</strong></em> function.</li>
<li>Change:   the <em><strong>xtype</strong></em> function will now ignore user-defined types but return <strong>LuaEx</strong>&#39;s type names for <strong>classes</strong>, <strong>constants</strong>, <strong>enums</strong>, structs, <strong>struct factories</strong> (and <strong>struct_factory_constructor</strong>) and <strong>null</strong> (and <strong>NULL</strong>) as opposed to returning, <em>&quot;table&quot;</em>. <em>Use the <strong>rawtype</strong> function to ignore all <strong>LuaEx</strong> type mechanics</em>.</li>
<li>Change:   renamed the <em><strong>string.delimitedtotable</strong></em> function to <em><strong>string.totable</strong></em>.</li>
<li>Bugfix:   corrected several minor bugs in enum library.</li>
<li>Bugfix:   corrected assertions in stack class.</li>
<li>Bugfix:   <em><strong>set.addset</strong></em> was not adding items.</li>
<li>Feature:  added several type functions and metamethods to various default types (e.g., boolean, string, number, etc.).</li>
<li>Feature:  added serialization to enums.</li>
<li>Feature:  added the <strong>ini</strong> module.</li>
<li>Feature:  added <em><strong>string.isnumeric</strong></em> function.</li>
<li>Feature:  added a <em><strong>__mod</strong></em> metamethod for string which allows for easy interpolation.</li>
<li>Feature:  added null type.</li>
<li>Feature:  added the <strong>struct</strong> factory module.</li>
<li>Feature:  added the <em><strong>xtype</strong></em> function.</li>
<li>Feature:  added the <em><strong>fulltype</strong></em> function.</li>
<li>Refactor: moved all type items to <strong>types.lua</strong>.</li>
</ul>
<p><strong>v0.60</strong></p>
<ul>
<li>Feature:  removed <em><strong>string.left</strong></em> as it was an unnecessary and inefficient wrapper of <em><strong>string.sub</strong></em>.</li>
<li>Feature:  removed <em><strong>string.right</strong></em> as it was an unnecessary and inefficient wrapper of <em><strong>string.sub</strong></em>.</li>
<li>Feature:  added <em><strong>string.trim</strong></em> function.</li>
<li>Feature:  added <em><strong>string.trimleft</strong></em> function.</li>
<li>Feature:  added <em><strong>string.trimright</strong></em> function.</li>
<li>Bugfix:   corrected package.path code in init.lua and removed <em><strong>import</strong></em> function.</li>
<li>Refactor: moved modules into appropriate subdirectories and updated init.lua to find them.</li>
<li>Refactor: appended <em><strong>string</strong></em>, <em><strong>math</strong></em> &amp; <em><strong>table</strong></em> module files with &quot;hook&quot; without which they would not load properly.</li>
<li>Update:   updated README with more information.</li>
</ul>
<p><strong>v0.50</strong></p>
<ul>
<li>Bugfix: <em><strong>table.lock</strong></em> was altering the metatable of <strong>enums</strong> when it should not have been.</li>
<li>Bugfix: <em><strong>table.lock</strong></em> was not preserving metatable items (where possible).</li>
<li>Change: classes are no longer automatically added to the global scope when created; rather, they are returned for the calling script to handle.</li>
<li>Change:  <strong>LuaEx</strong> classes and modules are no longer auto-protected and may now be hooked or overwritten. This change does not affect the way constants and enums work in terms of their immutability.</li>
<li>Change:  <strong>enums</strong> values may now be of any non-nil type(previously only <strong>string</strong> and <strong>number</strong> were allowed).</li>
<li>Feature: <strong>class</strong> constructor methods now pass, not only the instance, but a protected, shared (fields and methods) table to parent classes.</li>
<li>Feature: <strong>enums</strong> may now be nested.</li>
<li>Feature: added <em><strong>protect</strong></em> function (in <em><strong>stdlib</strong></em>).</li>
<li>Feature: added <em><strong>sealmetatable</strong></em> function (in <em><strong>stdlib</strong></em>).</li>
<li>Feature: added <em><strong>subtype</strong></em> function (in <em><strong>stdlib</strong></em>).</li>
<li>Feature: added <em><strong>table.lock</strong></em> function.</li>
<li>Feature: added <em><strong>table.purge</strong></em> function.</li>
<li>Feature: added <em><strong>table.settype</strong></em> function.</li>
<li>Feature: added <em><strong>table.setsubtype</strong></em> function.</li>
<li>Feature: added <em><strong>table.unlock</strong></em> function.</li>
<li>Feature: added <em><strong>queue</strong></em> class.</li>
<li>Feature: added <em><strong>set</strong></em> class.</li>
<li>Feature: added <em><strong>stack</strong></em> class.</li>
</ul>
<p><strong>v0.40</strong></p>
<ul>
<li>Bugfix:  metavalue causing custom type check to fail to return the proper value.</li>
<li>Bugfix:  typo that caused global enums to not be put into the global environment.</li>
<li>Feature: enums can now also be non-global.</li>
<li>Feature: the enum created by a call to the enum function is now returned.</li>
</ul>
<p><strong>v0.30</strong></p>
<ul>
<li>Change:  Added a meta table to <em><strong>_G</strong></em> in the <strong>init</strong> module.</li>
<li>Change:  Changed the name of the <strong>const</strong> module and function to <strong>constant</strong> for Lua 5.1 - 5.4 compatibility.</li>
<li>Change:  Altered the way constants and enums work by using the new, <em><strong>_G</strong></em> metatable to prevent deletion or overwriting.</li>
<li>Change:  Updated several modules.</li>
<li>Feature: Hardened the protected table to prevent accidental tampering.</li>
</ul>
<p><strong>v0.20</strong></p>
<ul>
<li>Change: Added the enum object.</li>
<li>Change: Updated a few modules.</li>
</ul>
<p><strong>v0.10</strong></p>
<ul>
<li>Compiled various modules into <strong>LuaEx</strong>.</details></li>
</ul>
<h2 id="🅻🅸🅲🅴🅽🆂🅴-©">🅻🅸🅲🅴🅽🆂🅴 ©</h2>
<p>All code is placed in the public domain under <a href="https://opensource.org/licenses/unlicense" title="The Unlicense">The Unlicense</a> <em>(except where otherwise noted)</em>.</p>
<details>
<summary>🆅🅸🅴🆆 🅻🅸🅲🅴🅽🆂🅴</summary>
This is free and unencumbered software released into the public domain.

<p>Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.</p>
<p>In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.</p>
<p>THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.</p>
<p>For more information, please refer to <a href="http://unlicense.org/">http://unlicense.org/</a></p>
</details>

<h2 id="🆆🅰🆁🆁🅰🅽🆃🆈-🗞">🆆🅰🆁🆁🅰🅽🆃🆈 🗞</h2>
<p>None. Use at your own risk. 💣</p>
<h2 id="🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽-🗎">🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽 🗎</h2>
<p>All documentation for <strong>LuaEx</strong> is on <em><strong>GitHub Pages</strong></em> found here:</p>
<h3 id="httpscentaurisoldiergithubioluaex"><a href="https://centaurisoldier.github.io/LuaEx">https://centaurisoldier.github.io/LuaEx</a></h3>
<h2 id="🅳🅴🆅🅴🅻🅾🅿🅼🅴🅽🆃-🅶🅾🅰🅻🆂-⌨">🅳🅴🆅🅴🅻🅾🅿🅼🅴🅽🆃 🅶🅾🅰🅻🆂 ⌨</h2>
<h4 id="why-write-luaex">Why Write LuaEx?</h4>
<p><strong>LuaEx</strong> attempts to implement code solutions for common and frequent problems. I found myself rewriting code over and again or copying old blocks of code from other projects into new projects and finally decided it would be better to compile that code into one single, easy-to-use module.</p>
<h4 id="big-things-come-in-small-package">Big Things Come in Small Package</h4>
<p>Keeping this module small is essential to making it useful. You shouldn&#39;t have to spend a year learning how to use something designed to be easy to use; <strong>LuaEx</strong> is developed with that in mind.</p>
<h4 id="simplicity">Simplicity</h4>
<p>Retaining simplicity of the code is also a primary goal of this module. The code should be intuitive and I strive toward that end. The purpose being that both you and I should be able to read the code and understand it.</p>
<h4 id="conventional-consistency">Conventional Consistency</h4>
<p>This project is made to be consistent both with Lua&#39;s naming &amp; coding conventions as well as internally.<br>While my own convention uses (dromedary) <a href="https://en.wikipedia.org/wiki/Camel_case"><em>camelCase</em></a> and <em>PascalCase</em>, I defer to <strong>Lua&#39;s</strong> convention where appropriate.<br>What that means is, everything that&#39;s hooked directly into <strong>Lua</strong> or creates new base types (<em>e.g.</em>, <em><strong>table.clone</strong></em>, <em><strong>rawtype</strong></em>, <strong>enums</strong>, <strong>arrays</strong>, <strong>structs</strong>), respects the <em>alllowercase</em> convention used by <strong>Lua</strong>; however, for any items which do not the convention is <em>camelCase</em> (e.g., functions) and <em>PascalCase</em> (e.g., classes).
This helps maintain expectations of the user while accessing <strong>Lua</strong> items while still allowing me to adhere to my own convention for things outside of <strong>Lua&#39;s</strong> core.</p>
<h4 id="naming-conventions">Naming Conventions</h4>
<p><strong>LuaEx</strong> adheres to strict naming conventions for the sake of clarity, consistency, readability and <a href="https://en.wikipedia.org/wiki/Obsessive%E2%80%93compulsive_disorder">OCD</a> compliance.</p>
<details>
<summary>🆅🅸🅴🆆 🅲🅾🅽🆅🅴🅽🆃🅸🅾🅽🆂</summary>
Variables are prefixed with the following lower-case symbols based on their type/application and appear to be PascalCase *after* the prefix. Combined with the prefix, this makes them camelCase.

<p><em>_</em> |   <strong>file-scoped local variables</strong> <em>e.g.,</em> <code>local _nMaxUnits = 12;</code><br><em>a</em> |   <strong>array</strong><br><em>b</em>	|	<strong>boolean</strong><br><em>c</em>	|	<strong>class</strong>
<em>d</em>	|	<strong>classaide</strong>
<em>e</em>	|	<strong>enum</strong><br><em>f</em>	| 	<strong>function</strong><br><em>h</em>	|	<strong>file\window\etc. handle</strong> <em>(number)</em>
<em>n</em>	|	<strong>number</strong><br><em>p</em>	|	<strong>file\dir path</strong> <em>(string)</em><br><em>r</em>	|	<strong>struct</strong><br><em>o</em>	|	<strong>class\other</strong> <em>(object)</em><br><em>s</em>	|	<strong>string</strong><br><em>t</em>	|	<strong>table</strong><br><em>u</em>	| 	<strong>userdata</strong><br><em>v</em>	|	<strong>variable/unknown type</strong>
<em>w</em>	|	<strong>environment table</strong> <em>(table)</em><br><em>x</em>	|	<strong>factory</strong><br><em>z</em>	|	<strong>type</strong> <em>(string)</em> (e.g., &quot;string&quot;, &quot;table&quot;, etc.)  </p>
<p>Types ignored by this convention are types <strong>nil</strong> and <strong>null</strong> since prefixing such a variable type would, generally, serve no real purpose.</p>
<h6 id="exceptions">Exceptions:</h6>
<p>In <strong>for loops</strong>, sometimes &#39;<em>x</em>&#39; is used to indicate active index while &#39;k&#39; and &#39;v&#39; are used (when using pairs/ipairs) to reference the key and value of a table respectively. This shorthand is used often when the purpose and process of the loop is self-evident or easily determined at a glance.</p>
<p>Global variables that are directory paths begin with <strong>_</strong> and <em><strong>do not</strong></em> have a variable prefix.
E.g., _Scripts</p>
<p>In class methods, the first two arguments--the instance object and the class data table respectively) are written as &#39;<em>this</em>&#39; and &#39;<em>cdat</em>&#39; while the third argument in a child class constructor—the parent constructor method—is written as &#39;<em>super</em>&#39;.<br>Additionally, In any method that accepts the input of another class instance, the variable is written as &#39;<em>other</em>&#39; (or as &#39;<em>left</em>&#39; and &#39;<em>right</em>&#39; in metamethods). This intentional and obvious deviation from convention makes these variables stand out clearly.<br>Within methods, cdat.pri (and other class data tables) may be set as <code>local pri = cdat.pri; </code>.</p>
<p>Class name are <em>PascalCase</em>.<br>E.g,  </p>
<pre><code class="language-lua">MyNewClass = class(...);
</code></pre>
</details>
<br>

<h4 id="principle-of-least-astonishment">Principle of Least Astonishment</h4>
<p>In developing <strong>LuaEx</strong>, I strive to take full advantage of the flexibility of the Lua language while still adhering to the <a href="https://en.wikipedia.org/wiki/Principle_of_least_astonishment">Principle of Least Astonishment</a>.</p>
<p>The only <em>limited</em> exceptions made are for new features (<em>whose developments are generally permitted exclusively by Lua</em>) not otherwise found in other OOP languages.<br>Simply put, things are intended to be intuitive.</p>
<h4 id="user-feedback">User Feedback</h4>
<p>While I develop LuaEx for my own projects, it&#39;s also designed to be used by others.<br>For their benefit and my own, I take user feedback seriously and address and appreciate submitted issues and pull requests.</p>
<h2 id="🅲🅾🅼🅿🅰🆃🅸🅱🅸🅻🅸🆃🆈-❤">🅲🅾🅼🅿🅰🆃🅸🅱🅸🅻🅸🆃🆈 ❤</h2>
<p><strong>LuaEx</strong> is designed for <strong>Lua 5.3</strong>; however, I will make every possible effort to make it backward compatible with the latest version of <strong>Lua 5.1</strong>.<br>To that end, if you&#39;re using <strong>Lua 5.1</strong> and come across a bug that appears specific to that version, please submit a issue and I&#39;ll address it.<br>Please keep in mind, if there is ever an intractable conflict between <strong>Lua 5.1</strong> and <strong>Lua 5.3</strong>, <strong>Lua 5.3</strong> will <em><strong>always</strong></em> take precedence.</p>
<br>
<br>

<hr>
<h1 id="🅵🅴🅰🆃🆄🆁🅴🆂✨⭐📲"><center><a id="features"></a>🅵🅴🅰🆃🆄🆁🅴🆂✨⭐📲</center></h1>
<hr>
<br>
<br>

<h2 id="🅽🅴🆆-🆃🆈🅿🅴-🆂🆈🆂🆃🅴🅼-💫">🅽🅴🆆 🆃🆈🅿🅴 🆂🆈🆂🆃🅴🅼 💫</h2>
<ul>
<li>Allows for type checking against old, new and user-created types. For example, if the user created a <strong>Creature</strong> class, instantiated an object and checked the type of that object, <em><strong>type</strong></em> would return <strong>&quot;Creature&quot;</strong>. In addition to new <strong>LuaEx</strong> types (such as <strong>array</strong>, <strong>enum</strong>, <strong>class</strong>, <strong>struct</strong>, etc.), users can create their own types by setting a string value in the table&#39;s metatable under the key, <em>__type</em>. Subtypes are also available using the <em>__subtype</em> key (use <em><strong>type.sub</strong></em> function to check that).</li>
<li>boolean to number/string coercion, number to boolean coercion, boolean math, boolean negation, etc.</li>
<li>The <em><strong>null</strong></em> (or <em><strong>NULL</strong></em>) type now exists for the main purpose of retaining table keys while providing no real value. While setting a table key to nil will remove it, setting it to <em><strong>null</strong></em> will not.<br>The <em><strong>null</strong></em> value can be compared to other types and itself.<br>In addition, it allows for undeclared initial types in <strong>classes</strong>, <strong>arrays</strong> and <strong>structs</strong>.  <ul>
<li>As shown above, The <em><strong>null</strong></em> value has an alias: <em><strong>NULL</strong></em>.  </li>
<li><em><strong>WARNING</strong></em>: <u><em>never</em></u> localize the <em><strong>null</strong></em> (or <em><strong>NULL</strong></em>) value! Strange things happen...you&#39;ve been warned. <strong>☠ ☣ ☢ 💥</strong></li>
</ul>
</li>
</ul>
<h6 id="boolean">Boolean</h6>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">-- Logical OR
print(true + false);  -- true (logical OR)
print(false + false);  -- false (logical OR)

-- Concatenation
print(&quot;This value is &quot; .. true);  -- &quot;This value is true&quot;
print(false .. &quot; value&quot;);  -- &quot;false value&quot;

-- Length
print(#true);  -- 1
print(#false);  -- 0

-- Logical AND
print(true * false);  -- false (logical AND)
print(true * true);  -- true (logical AND)

-- String Coercion
print(tostring(true));  -- &quot;true&quot;
print(tostring(false));  -- &quot;false&quot;

-- Negation
print(-true);  -- false (negation)
print(-false);  -- true (negation)

-- Logical XOR (custom operator)
print(true ~ false);  -- true (logical XOR)
print(true ~ true);  -- false (logical XOR)

-- Logical NAND
print(not (true and true));  -- false (logical NAND)
print(not (true and false));  -- true (logical NAND)

-- Logical NOR
print(not (true or false));  -- false (logical NOR)
print(not (false or false));  -- true (logical NOR)

-- Logical XNOR (equivalence)
print(true == true);  -- true (logical XNOR/equivalence)
print(false == true);  -- false (logical XNOR/equivalence)

-- Implication
print((not false) or true);  -- true (implication)
print((not true) or false);  -- false (implication)


--etc.
</code></pre>
</details>



<h6 id="number">Number</h6>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>
</details>

<h6 id="null">Null</h6>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">print(null &lt; 1);    --&gt; true
print(null &lt; &quot;&quot;);   --&gt; true
print(null &lt; nil);  --&gt; false
local k = null;
print(k)            --&gt; null
</code></pre>
</details>

<hr>
<h5 id="constants-♾️">Constants ♾️</h5>
<p>While <strong>Lua 5.4</strong> offers constants natively, previous versions don&#39;t.<br>As <strong>LueEx</strong> is not built for <strong>5.4</strong>, constants are provided. They may be of any non-nil type (<em>though <em><strong>null</strong></em> [or <em><strong>NULL</strong></em>] should <strong>never</strong> be set as a constant, as it already is</em>).  </p>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">constant(&quot;MAX_CREATURES&quot;, 45);
print(MAX_CREATURES);           --&gt; 45
constant(&quot;ERROR_MARKER&quot;, &quot;err:&quot;);
print(ERROR_MARKER);            --&gt; &quot;err:&quot;
</code></pre>
</details>

<hr>
<h5 id="string-interpolation-💱">String Interpolation 💱</h5>
<pre><code class="language-lua">&quot;I can embed variables like, ${var1}, in my strings and make ${adjective} madlibs.&quot; % {var1 = &quot;Frog&quot;, adjective = &quot;crazy&quot;};
</code></pre>
<hr>
<h5 id="class-system-💠">Class System 💠</h5>
<ul>
<li>A fully-functional, (<em>pseudo</em>) <a href="https://en.wikipedia.org/wiki/Object-oriented_programming">Object Oriented Programming</a> class system which features encapsulation, inheritance, and polymorphism as well as optional interfaces.</li>
<li>The class system also takes advantage of metatables and allows user to create, inherit and override these for class objects.</li>
<li>Optional <strong>Properties</strong>: auto getter/setter (<em>accessor/mutator</em>) directives which create getter/setter methods for a given non-method member.</li>
<li>Optional static initializer method called once during class creation.</li>
<li>Strongly typed values (although allowing initial <em><strong>null</strong></em> values).</li>
<li>Optional final methods (preventing subclass overrides).</li>
<li>Optional final classes.</li>
<li>Optional limited classes meaning a class can limit which classes can subclass it.</li>
<li><strong>More</strong> features inbound...</li>
</ul>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">Creature = class(&quot;Creature&quot;,
{--metamethods
},
{--public static members
    createCount = 0;
    _INIT = function(stapub)
        --DO static things here during class creation.
    end,
},
{--private members
    DeathCount = 0,
    Allies = {},
},
{--protected members --set up properties using the _AUTO directive
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
    Damage_AUTO = 5,
    AC_AUTO     = 0,
    Armour_AUTO = 0,
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        cdat.pro.HP     = nHP &lt; 1 and 1 or nHP;
        cdat.pro.HP     = nHP &gt; nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
    end,
    isDead__FNL = function(this, cdat) --set this method as final
        return cdat.pro.HP &lt;= 0;
    end,
    kill = function(this, cdat)
        cdat.pro.HP = 0;
    end,
    move = function(this, cdat)

    end
},
NO_PARENT, false, NO_INTERFACES);



local HP_MAX = 120; -- this is an example of a private static field

Human = class(&quot;Human&quot;,
{--metamethods
},
{--public static members
},
{--private members
    Name_AUTO = &quot;&quot;,
},
{--protected members
},
{--public members
    Human = function(this, cdat, super, sName, nHP)
        --print(&quot;human&quot;, sName, nHP, HP_MAX)
        super(nHP, HP_MAX);
        cdat.pri.Name = sName;
    end,
},
Creature, false, NO_INTERFACES);

local Dan = Human(&quot;Dan&quot;, 45);
print(&quot;Name: &quot;..Dan.getName());                         --&gt; &quot;Name: Dan&quot;
print(&quot;HP: &quot;..Dan.getHP());                             --&gt; &quot;HP: 45:&quot;
print(&quot;Type: &quot;..type(Dan));                             --&gt; &quot;Type: Human&quot;
print(&quot;Is Dead? &quot;..Dan.isDead());                       --&gt; &quot;Is Dead? false&quot;
print(&quot;Kill Dan ):!&quot;); Dan.kill();                      --&gt; &quot;Kill Dan ):!&quot;
print(&quot;Is Dead? &quot;..Dan.isDead());                       --&gt; &quot;Is Dead? true&quot;
print(&quot;Set Name: Dead Dan&quot;); Dan.setName(&quot;Dead Dan&quot;);   --&gt; &quot;Set Name: Dead Dan&quot;
print(&quot;Name: &quot;..Dan.getName());                         --&gt; &quot;Name: Dead Dan&quot;
</code></pre>
</details>

<hr>
<h5 id="enums-🔠">Enums 🔠</h5>
<ul>
<li>Can be local or global and even embedded at runtime.</li>
<li>Have the option for custom value types for items.</li>
<li>Strict ordinal adherence.</li>
<li>Built-in iterator.</li>
<li>QoL methods and properties like <em><strong>next</strong></em>, <em><strong>previous</strong></em>, etc.</li>
</ul>
<hr>
<h5 id="structs-🕋">Structs 🕋</h5>
<p>These objects are meant to behave as you might expect from other languages but with added features.  </p>
<p>They are made by first creating a struct factory. The factory created is of type <strong>[sName]factory</strong> (of subtype <strong>structfactory</strong>) where <em>sName</em> is the name input into the <em>struct factory builder</em> (as shown in the example below).  </p>
<p>Struct factories output type <strong>sName</strong> (of subtype <strong>struct</strong>).</p>
<p>Creation of a <strong>structfactory</strong> object involves inputting a string-indexed table whose value types are rigidly set by the type given in the input table (or null to remain variable). <strong>Structs</strong> can be set to immutable but are mutable by default.  </p>
<p><em><strong>Note</strong>: item types are <strong>not</strong> mutable save for an item containing a <strong>null</strong> value (before being set to a value type). Once an item that contains a <strong>null</strong> value has been set to a real value type, the type cannot be changed.</em></p>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">--create a mutable bullet struct table
local bImmutable = false; --set this to true to disallow value changes
local tBullet = {
   speed   = 5,
   damage  = 10,
   caliber = &quot;9mm&quot;,
   owner   = null, --this type can be set later by each bullet created
};

--create the struct factory
xBullet = structfactory(&quot;bullet&quot;, tBullet, bImmutable);

--print the details of the struct factory
print(&quot;Bullet factory:\n&quot;, xBullet);

--print the factory&#39;s type and subtype
print(&quot;Factory&#39;s Type - Subtype :\n&quot;, type(xBullet), &quot; - &quot;,subtype(xBullet));

--let&#39;s make a bullet with the default values
local oBullet1 = xBullet();

--print the first bullet
print(&quot;\n\nBullet #1:\n&quot;, oBullet1);

--print the bullet&#39;s type and subtype
print(&quot;Bullet #1&#39;s Type - Subtype :\n&quot;, type(oBullet1), &quot; - &quot;,subtype(oBullet1));

--let&#39;s make another but with some custom initial values
local oBullet2 = xBullet({damage = 25, caliber = &quot;.30-06&quot;});

--print the second bullet
print(&quot;\n\nBullet #2:\n&quot;, oBullet2);

--clone oBullet1
local oBullet1Clone = clone(oBullet1);

--print the clone&#39;s details
print(&quot;\n\nBullet #1 Cloned:\n&quot;, oBullet1Clone);

--make some changes to oBullet1
oBullet1.speed = 35;
--print the bullet&#39;s caliber and speed
print(&quot;\n\nBullet #1 Caliber: &quot;, oBullet1.caliber);
print(&quot;\n\nBullet #1&#39;s New Speed: &quot;, oBullet1.speed);

--serialize oBullet1 and print it
local zBullet1 = serialize(oBullet1);
print(&quot;\n\nBullet #1 Serialized:\n&quot;, zBullet1);

--deserialize it (creating a new struct object) and show it&#39;s type and details
local oBullet1Deserialized = deserialize(zBullet1);
print(&quot;\n\nBullet #1 Deerialized:\n&quot;, &quot;type: &quot;..type(oBullet1Deserialized)..&quot;\n&quot;, oBullet1Deserialized);
</code></pre>
</details>

<hr>
<h5 id="arrays-🔢">Arrays 🔢</h5>
<ul>
<li>The <strong>array</strong> object behaves like traditional arrays in as many ways as is possible in <strong>Lua</strong>.</li>
<li>Are type-safe, meaning only one type may be put into an <strong>array</strong>.</li>
<li>Have a fixed length.</li>
<li>Are numerically indexed.</li>
<li>Have the option to initialize with a numerically-indexed table of values or a number.</li>
<li>Initializing with a number—e,g., aMyArray = <strong>array</strong>(<em>nLength</em>)—all values are set to <strong>null</strong> and the <strong>array</strong> type is set upon the first value assignment.</li>
<li>Strict bounds checking upon assignment/retrieval.</li>
<li>Returns <strong>null</strong> value for unassigned values in numerically-instantiated <strong>array</strong>.</li>
<li>Obligatory methods such as <em><strong>sort</strong></em>, <em><strong>clear</strong></em>, <em><strong>copy</strong></em>, etc.  </li>
<li>Array cloning is done via the cloner (as shown in the example below).</li>
</ul>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">--initialized with a size, but no type.
local aPet = array(5);

--show some info on the aPet array
print(&quot;aPets is an &quot;..type(aPet)..&quot; made by the &quot;..type(array)..&#39;.&#39;);

--print the value at index 5 (null)
print(&quot;aPet[5] -&gt; &quot;..tostring(aPet[5]));

--initialized with a size and type.
local aNoPet = array({&quot;Aligator&quot;, &quot;T-Rex&quot;, &quot;Rino&quot;, &quot;Leech&quot;, &quot;Dragon&quot;});

--print the aNoPet array
print(&quot;aNoPet (Don&#39;t pet these things! Stop it, no pet!) -&gt; &quot;, aNoPet);

--add some items to the aPet array (and set the type with the first assignment)
aPet[1] = &quot;Cat&quot;;
aPet[2] = &quot;Frog&quot;;
aPet[3] = &quot;Doggo&quot;;
aPet[4] = &quot;Lizard&quot;;
--aPet[4] = 45; --this will throw an error for trying to set a different type
aPet[5] = &quot;Bunny&quot;;

--print the aPet array
print(&quot;aPet (It&#39;s okay, you can pet these ones.) -&gt; &quot;, aPet);

--access some items by index
print(&quot;Don&#39;t pet the &quot;..aNoPet[3]..&#39;! But, you can pet the &#39;..aPet[1]..&#39;.&#39;);

--iterate over one of the arrays using the built-in iterator
for nIndex, sValue in aNoPet() do
    print(&quot;No pet the &quot;..sValue..&#39;!&#39;);
end

--show the legth of an array
print(&quot;There are &quot;..aPet.length..&quot; animals you can pet.&quot;);

--sort and print the arrays
aPet.sort();
aNoPet.sort()

print(&quot;\naPet Sorted: -&gt; &quot;..tostring(aPet));
print(&quot;aNoPet Sorted: -&gt; &quot;..tostring(aNoPet));

--reverse sort the aNoPet array and print the results
aNoPet.sort(function(a, b) return a &gt; b end)
print(&quot;aNoPet Reverse Sorted: -&gt; &quot;..tostring(aNoPet));

print(&quot;\n&quot;)

--you can create arrays of any single type (including functions)
local aMethods = array(3);
aMethods[1] = function()
    print(&quot;You can make an array of functions/methods.&quot;);
end
aMethods[2] = function(...)
    local sOutput = &quot;You can referene the aMethods &quot;..type(aMethods)..&quot;.\n&quot;;
    sOutput = sOutput..&quot;\nThen, you can do whatever else you want even setting the other items.&quot;

    if (type(aMethods[3]) == &quot;null&quot;) then
        aMethods[3] = function()
            print(&quot;Calling aMethods[2] will print this very boring message.&quot;);
        end

    end

    print(sOutput);
end

aMethods[1]();
aMethods[2]();
aMethods[3]();

--TODO clone and copy examples
local aCloned = clone(aNoPet);
print(aCloned)
</code></pre>
</details>

<hr>
<h5 id="notes-on-factories-🚧">Notes on Factories 🚧</h5>
<ul>
<li>All <strong>arrays</strong>, <strong>enums</strong>, <strong>structs</strong> and other such items are made by <em>factories</em>. The <strong>array</strong> <em>factory</em> is called by <em><strong>array()</strong></em>, <strong>enum</strong> <em>factory</em> by <em><strong>enum()</strong></em>, <strong>class</strong> <em>factory</em> by <em><strong>class()</strong></em>, etc.</li>
<li>While some objects are made by <em>factories</em>, some things make <em>factories</em> (<em>that, in turn, make objects</em>). One example of this is <strong>structs</strong>. These are made by <em>factories</em> that are made by a <em>struct factory builder</em> called with <em><strong>structfactory()</strong></em> that returns a <em>struct factory</em>.</li>
</ul>
<hr>
<h2 id="🆂🅴🆁🅸🅰🅻🅸🆉🅴🆁-❓➡️-🔤">🆂🅴🆁🅸🅰🅻🅸🆉🅴🆁 ❓➡️ 🔤</h2>
<p>The serializer system is designed to work with most native <strong>Lua</strong> types as well as custom objects such as <strong>classes</strong>, <strong>arrays</strong>, etc., and user-created objects.<br>The two <strong>Lua</strong> types <u><strong>not currently</strong></u> able to be serialized/deserialized are:</p>
<ul>
<li><strong>thread</strong></li>
<li><strong>userdata</strong></li>
</ul>
<p>To serialize something, simply call the <em><strong>serialize()</strong></em> function with the item input (as shown in the example below).<br>To deserialize something that was serialized, call the <em><strong>deserialize()</strong></em> function with the item as input.</p>
<p>These two functions work effortlessly for  native <strong>Lua</strong> types but use with custom objects depends on a contract.<br>Any object which is to be serialized must have a <em><strong>__serialize</strong></em> metamethod.
To deserialize it, a static <em><strong>deserialize</strong></em> method must exist.</p>
<p>The contract between the <em><strong>__serialize</strong></em> metamethod and the static <em><strong>deserialize</strong></em> method is as follows: whatever is returned from <em><strong>__serialize</strong></em> will be input by the serializer system into the <em><strong>deserialize</strong></em> method as the first argument exactly as output by <em><strong>__serialize</strong></em>.  </p>
<p>It&#39;s the responsibility of the <em><strong>__serialize</strong></em> metamethod to ensure all custom objects it returns are serialized before returned (user should confirm those custom objects also have a <em><strong>__serialize</strong></em> metamethod).  </p>
<p>It&#39;s the responsibility of the static <em><strong>deserialize</strong></em> method to return the expected object.</p>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">
Creature = class(&quot;Creature&quot;,
{--metamethods
    __serialize = function(this, cdat)
        --local pri = cdat.pri;
        local pro = cdat.pro;

        local tData = {
            [&quot;pro&quot;] = {
                damage  = pro.damage,
                armour  = pro.armour,
                HP      = pro.HP,
                HPMax   = pro.HPMax,
            },
        };

        return tData;
    end,
    __tostring = function(this, cdat)
        local sRet  = &quot;&quot;;
        local pro   = cdat.pro;

        sRet = sRet..&quot;Damage: &quot;..pro.damage;
        sRet = sRet..&quot;\nArmour: &quot;..pro.armour;
        sRet = sRet..&quot;\nHP: &quot;..pro.HP;
        sRet = sRet..&quot;\nMax HP: &quot;..pro.HPMax;

        return sRet;
    end,
},
{--public static members
    deserialize = function(tData)
        local oRet = Creature(tData.pro.HP, tData.pro.HPMax);
        oRet.setArmour(tData.pro.armour);
        oRet.setDamage(tData.pro.damage);
        return oRet;
    end,
},
{--private members
    DeathCount = 0,
    Allies = {},
},
{--protected members
    armour_AUTO = 0,
    damage_AUTO = 5,
    HP_AUTO     = 10,
    HPMax_AUTO  = 100,
},
{--public members
    Creature = function(this, cdat, nHP, nHPMax)
        cdat.pro.HP     = nHP &lt; 1 and 1 or nHP;
        cdat.pro.HP     = nHP &gt; nHPMax and nHPMax or nHP;
        cdat.pro.HPMax  = nHPMax;
    end,
    isDead = function(this, cdat)
        return cdat.pro.HP &lt;= 0;
    end,
    kill = function(this, cdat)
        cdat.pro.HP = 0;
    end,
    move = function(this, cdat)

    end,
    getArmour = function(this, cdat)
        return cdat.pro.armour;
    end,
    setArmour = function(this, cdat, nArmour)
        cdat.pro.armour = nArmour;
    end,
    getDamage = function(this, cdat)
        return cdat.pro.damage;
    end,
    setDamage = function(this, cdat, nDamage)
        cdat.pro.damage = nDamage;
    end,
},
NO_PARENT, false, NO_INTERFACES);

--create a creature
local oMonster           = Creature(80, 100);
--print stats
print(&quot;Before serialization:\n&quot;..tostring(oMonster));
--serialize the creature
local sMonsterSerialized = serialize(oMonster);
--print the serialized string
print(&quot;\n\n&quot;..sMonsterSerialized..&quot;\n&quot;);
--deserialize the creature
oMonster        = deserialize(sMonsterSerialized)
--print stats
print(&quot;After serialization:\n&quot;..tostring(oMonster));
</code></pre>
</details>

<hr>
<h2 id="🅲🅻🅾🅽🅴🆁-🐝➡️🐝">🅲🅻🅾🅽🅴🆁 🐝➡️🐝</h2>
<h4 id="info-coming-soon">Info coming soon...</h4>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">
</code></pre>
</details>

<hr>
<h2 id="🅳🅾🆇---🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽-🆂🆈🆂🆃🅴🅼-📚">🅳🅾🆇 - 🅳🅾🅲🆄🅼🅴🅽🆃🅰🆃🅸🅾🅽 🆂🆈🆂🆃🅴🅼 📚</h2>
<h4 id="info-coming-soon-1">Info coming soon...</h4>
<details>
<summary>🆅🅸🅴🆆 🅴🆇🅰🅼🅿🅻🅴</summary>

<pre><code class="language-lua">
</code></pre>
</details>

<hr>
<h2 id="🅼🅾🅳🆄🅻🅴🆂-⚙">🅼🅾🅳🆄🅻🅴🆂 ⚙</h2>
<p>Below is the complete list of modules in <strong>LuaEx</strong>.</p>
<details>
<summary>TODO 🛠</summary>

<ul>
<li><h4 id="class"><a href="https://centaurisoldier.github.io/LuaEx/api/class.html">class</a></h4>
</li>
<li><h4 id="constant"><a href="https://centaurisoldier.github.io/LuaEx/api/constant.html">constant</a></h4>
</li>
<li><h4 id="deserialize"><a href="https://centaurisoldier.github.io/LuaEx/api/deserialize.html">deserialize</a></h4>
</li>
<li><h4 id="enum"><a href="https://centaurisoldier.github.io/LuaEx/api/enum.html">enum</a></h4>
</li>
<li><h4 id="math"><a href="https://centaurisoldier.github.io/LuaEx/api/math.html">math</a></h4>
</li>
<li><h4 id="serialize"><a href="https://centaurisoldier.github.io/LuaEx/api/serialize.html">serialize</a></h4>
</li>
<li><h4 id="stdlib"><a href="https://centaurisoldier.github.io/LuaEx/api/stdlib.html">stdlib</a></h4>
</li>
<li><h4 id="string"><a href="https://centaurisoldier.github.io/LuaEx/api/string.html">string</a></h4>
</li>
<li><h4 id="struct"><a href="https://centaurisoldier.github.io/LuaEx/api/struct.html">struct</a></h4>
</li>
<li><h4 id="table"><a href="https://centaurisoldier.github.io/LuaEx/api/table.html">table</a></h4>
</li>
</ul>
</details>

<hr>
<h2 id="🅲🅻🅰🆂🆂🅴🆂--🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂-📔">🅲🅻🅰🆂🆂🅴🆂 &amp; 🅸🅽🆃🅴🆁🅵🅰🅲🅴🆂 📔</h2>
<p>LuaEx ships with a classes and interfaces which can be found in the documentation section.</p>
<hr>
<h2 id="🆁🅴🆂🅾🆄🆁🅲🅴🆂-⚒">🆁🅴🆂🅾🆄🆁🅲🅴🆂 ⚒</h2>
<ul>
<li>Logo: <a href="https://cooltext.com/">https://cooltext.com/</a></li>
<li>Special ASCII Fonts: <a href="https://fsymbols.com/generators/carty/">https://fsymbols.com/generators/carty/</a></li>
<li>Unicode Characters: <a href="https://unicode-table.com/en/sets/symbols-for-instagram/">https://unicode-table.com/en/sets/symbols-for-instagram/</a></li>
</ul>
<h2 id="🅲🆁🅴🅳🅸🆃🆂-⚛">🅲🆁🅴🅳🅸🆃🆂 ⚛</h2>
<ul>
<li>Huge thanks to <a href="https://github.com/imagine-programming">Bas Groothedde</a> at Imagine Programming for creating the original <strong>class</strong> module.</li>
</ul>
]];
