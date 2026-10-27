<div align="center">
  <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx">
  <h1>🅲🅷🅰🅽🅶🅴🅻🅾🅶</h1>
</div>

## [**v0.62**] (*in progress*)

### Added
- Native **lua tests/run.lua** core regression runner with isolated processes, loader-level checks, collection models, formatting corpus, explicit unavailable legacy coverage, and nonzero failure status.
- **eventrix** serialization and **eventrix.deserialize** with versioned state, callback order and activation preservation, empty-event restoration, independent runtime containers, and named external environment bindings. Shared callbacks and captured state use the existing graph serializer.
- **XML** class for parsing UTF-8 XML documents, including elements, attributes, text, CDATA, comments, and processing instructions.
- XML source preservation, independent document-tree snapshots, element searches, cloning, and class serialization support.
- **VFS** class providing virtual mounts, registered directories, aliases, restricted access objects, permission checks, and access revocation.
- VFS file reading, writing, listing, directory creation, removal, copying, and moving through native or custom backends.
- **textcatalog** library providing structured text templates, persistent variables, active-node selection, scoped searches, and editable text.
- Independent cloning and serialization of text catalogs, including their variables and active scope.
- **prettyLua** source formatter supporting Lua chunks, standalone expressions, Lua 5.3 syntax, and Lua 5.4 local attributes. Formatting preserves tokens without executing the source.
- Private class snapshot hooks **prepareSnapshot** and **validateSnapshot** for customizing generated serialization without replacing the class serializer.
- Browser-based example workbench with source editing, execution output, isolated Lua sessions, and an offline bundled runtime.
- Interactive examples for enums, Potentiometer, Protean, Stack, and text catalogs.
- Regression tests and supporting verification scripts for core libraries, classes, and utilities.
- Standalone public-boolean class reproduction in **EDITED/BUG TEST/class.lua**.

### Changed
- Aligned the runtime and README version with **v0.62**. Corrected the current one-argument loader documentation and separated verified Lua 5.4 configurations from unverified versions and hosts.
- Updated collection tutorials to verify repaired behavior and documented the supported global serialization path and remaining 1.0 readiness blockers.
- Replaced public **class.getparent**, **getbase**, and **getchildren** with **getparentname**, **getbasename**, and **getchildnames**, returning names instead of class objects. Child-name lists are independent and alphabetically sorted.
- **class.getbyname(name, environment)** now returns only registered class objects directly present in the supplied table, using **rawget**. Missing or non-table environments use a private empty table; registry lookup and metatable fallback cannot supply a class object.
- **class.getname** now accepts registered instances as well as class objects and names. Removed public **class.of**, retaining only a private internal lookup for framework validation.
- Removed the ineffective **isInScope** mechanism. Name-based metadata queries remain available without granting access to class objects; updated affected callers and regression coverage.
- Replaced automatic initialization through **LuaEx.init** with explicit initialization through **LuaEx.load**.
- Simplified initialization to one optional class-load level, from **0** through **5**, defaulting to **5**.
- Loading **LuaEx.load** returns the initializer without initializing the framework.
- Initialization enables required dependencies, restores **package.path**, and publishes **LUAEX_INIT** only after successful loading.
- Moved classes, interfaces, enums, and primitives out of **LuaEx/inc** into directories directly beneath **LuaEx**.
- Reworked **strata** into validated, immutable identifier hierarchies with case-insensitive lookup, sorted iteration, parent navigation, identity-preserving cloning, and registered restoration.
- Class snapshot hooks run from base to derived; restoration validates the complete hierarchy before constructing instances.
- Snapshot copying preserves shared references and cycles among plain tables while retaining decoded typed-object identities.
- Clone traversals now maintain separate coroutine contexts and clean up traversal state after failures.
- Reorganized examples into topic folders, separate editable tutorials, shared support modules, and visual examples.
- Added documentation and example resources for XML, VFS, and text catalogs.
- Corrected the earlier changelog claim that class scope checking was fixed; class-object access is now governed by explicit environment bindings rather than the captured-reference scope check.

### Fixed
- **Stack.peek** and **Queue.peek** discarded stored **false** values; **Stack.pop** leaked a global return variable and reused stale values when empty.
- **Set.remove** and **purgeSet** called a missing global helper. Removal now uses the protected method and matches member identity consistently; empty Sets print as **{}**.
- Set cloning built membership keys from original table objects while iterating copied objects. Membership now follows copied members, with circular clone references registered before descent.
- **SortedDictionary** iteration referenced nonexistent class data and exposed private iterator state. Both call and **pairs** traversal now use the ordered iterator without exposing storage; **containsValue** now searches ordered entries.
- SortedDictionary removal could discard custom ordering. Comparator changes and insertions now sort temporary key lists so errors preserve existing state and do not leave ghost keys.
- **eventrix.removeEvent** passed an undefined variable to its validation error helper. Invalid event IDs now report their actual input type instead of leaving an unresolved template placeholder.
- **eventrix.fire** created or overwrote an unrelated global **bFired** through an unused assignment. Dispatch no longer modifies that global.
- Eventrix snapshots and construction now work during dispatch under restricted environment bindings; nil callback results retain the **EVENTRIX_NIL** sentinel in those environments.
- **eventrix.addHook** returned an undefined variable after registering a callback. It now returns its eventrix object, restoring method chaining for both new and already-registered callbacks.
- **type.mathchesonlyleft**, **mathchesonlyright**, and **mathchesboth** compared the left type against an undefined variable. Both sides now compare against the supplied type name; existing helper names are retained for compatibility.
- Callable class instances received a duplicate instance argument before their user arguments. The **__call** wrapper now consumes Lua's implicit instance while preserving user argument counts, nil values, and return values.
- Preserved serializer factory-reference restoration independently of public class lookup restrictions, including saved class references whose external bindings are later removed or replaced.
- Class public fields containing **false** incorrectly returned **nil**. Instance lookup now returns **tClassData.pub[k]** directly.
- **class.isbaseof** looked up its first argument twice, failing to recognize valid root-base relationships. It now resolves both arguments and consistently returns a boolean, retaining name-based metadata queries.
- Assignments through subclass methods could bypass an inherited field's established class constraint. Validation now uses the field owner's constraint, preserving polymorphism and first-assignment typing for uninitialized **null** fields.
- Assigning **null** to an unset read-only class field prematurely locked it. The field now remains available until its first non-null assignment.
- Parent and subclass methods could independently lock the same inherited read-only field, allowing one access path to replace a value chosen through the other. All access paths now use the field owner's read-only lock.
- Constant creation incorrectly checked whether a name already existed in the LuaEx environment.
- Metatable sealing failed for tables with missing or existing metatables.
- Metatable guard detection used incorrect variables and type checks.
- Guarded metatable inspection now returns copied identity metadata instead of exposing implementation members.
- Metatable wrappers preserve native protection sentinels and reject replacement of registered guarded objects.
- Directory-listing failures could appear as successful empty results.
- Directory-listing pipes now close after iteration or callback failures, with failures returned as **nil** and a reason.
- Windows file enumeration now distinguishes successful empty file lists from listing-process failures.

### Removed
- The **LuaEx.init** entry point and the former framework configuration file.
- The **LuaEx/inc** directory layout.
- Legacy class-based geometry modules and obsolete primitive implementations.
- Deprecated event implementations, backup files, and several unfinished library experiments.
- Superseded example locations and old editor-completion configuration files.

### Known Issues
- The README still documents the previous three-argument initializer and class-load level **6**.
- Several regression tests and examples still reference removed modules, old paths, or the previous initializer signature.

---

## [**v0.61**]

### Added
- **class.haspublicmember**


- QR-code generation support and a QR example.
- **table.readonly** for independent recursive snapshots preserving shared references and cycles.
- **cloner.registerCopy**, **cloneIndependent**, and **registerFactory** for typed-object cloning and independent default-copy traversals.
- Graph-based serialization/restoration of shared tables, cyclic table graphs, Lua closures, and captured upvalue cells, plus registered typed-object restoration.
- Protean callback replacement/toggle locks, link-state queries, and a compatible correctly spelled final-value calculation method.

- **Tree** class with parent/child access, insertion/removal, traversal, and printable hierarchy output.
- String helpers **collapse**, **makefilesafe**, and **tosid**; expanded **string.totable** delimiter handling.
- **table.shadowreadonly** for read-only views of underlying tables, distinct from independent **table.readonly** snapshots.
- ISO timestamp-to-minute conversion utility.

### Changed


- Reworked **Protean** linking, modifiers, bounds, recalculation, callback state, and independent snapshots.
- Reworked **Potentiometer** clamping, revolving and alternating reflection, direction tracking, bounds/rates, and cloning.
- Reworked **enum** definitions, nested collections, immutable metadata, private/public registration, snapshots, restoration, and factory behavior.
- Reworked **struct** fixed-field/type validation, per-instance default copying, enum-keyed fields, read-only bindings, cloning, and serialization.
- Updated **array** bounds/type rules, empty containers, null slots, clearing, cloning, and saved-state restoration.
- Updated **null** indexing, empty iteration/calls, immutable normal writes, operators, and serialization behavior.
- Reworked geometry primitives: point, line, circle, arc, ellipse, and polygon validation, derived geometry, and transformations.
- Updated math helper validation and edge-case behavior; expanded geometry helpers and finite/nonfinite-number checks.
- Updated class default-copy isolation and validated class snapshot restoration; adjusted core initialization and type registration for the revised modules.

- Expanded **Ini** construction from text, tables, or files; ordered section/value access, deletion, typed reads, and inheritance-aware reads/writes.
- Reworked **Grid** delimiter/column handling, named/indexed row access, iteration, and file import validation.
- Updated **io** path and filesystem helpers, and environment-repository default update reporting.
- **BaseLog** constructor now includes an on-log callback slot before the auto-write option; updated timestamp/level formatting and independent per-instance entry storage.

### Fixed

- Windows path splitting losing drive prefixes and directory-existence checks using the wrong suffix.
- Class snapshot restoration accepting unknown fields, replacing methods, mismatched field types, or changed immutable scalar declarations.
- Shared-reference/cycle handling in clone and serialization traversals; independent copied defaults for separate class and struct instances.
- Numeric validation and state handling across Protean and Potentiometer.
- Geometry input validation and polygon boundary/derived-geometry handling.

- **BaseLog** per-level entry indexing incorrectly using the outer entries-table length.
- **Ini** duplicate-value diagnostics and file-construction read/open error handling.

---

## [**v0.60**]

### Added
- CSV class (currently not RFC 4180 compliant).
- New **eventrix** type to manage events.    
- Several **class**-level checks:
    - **class.exists**
    - **class.getbase**
    - **class.getbyname**
    - **class.getchildcount**
    - **class.getchildren**
    - **class.getconstructorvisibility**
    - **class.getname**
    - **class.getparent**
    - **class.haschildren**
    - **class.is**
    - **class.isbase**
    - **class.isbaseof**
    - **class.ischild**
    - **class.ischildorself**
    - **class.isdirectchild**
    - **class.isdirectparent**
    - **class.isinlineage**
    - **class.isinstance**
    - **class.isinstanceof**
    - **class.isparent**
    - **class.isparentorself**    
    - **class.isstaticconstructorrunning**
    - **class.of**    
- Classes now have an *optional* static constructor using the class name as the static method name.

### Changed
- Modifed all type assertion functions in **typehook.lua** to accept an optional, custom error message and an error level modifier value.
- Moved the changelog from README.md to its own file.
- Modified the changelog to be more in line with [keepachangelog.com](https://keepachangelog.com/en/1.1.0/) standards.
- Consolidated the old **class** changelog (*in the module's documentation*) into **LuaEx's** changelog.
- Renamed ***math.longtorgb*** to ***math.inttorgb***.
- Renamed ***math.rgbtolong*** to ***math.rgbtoint***.
- Class type checks were placed within the **type** module. E.g., ***isCreature*** becomes ***type.isCreature***.
- Appropriate class-level check functions now return the class object where intuitively expected but only when the class is in scope, nil otherwise.
- Classes now fully respect polymorphism in assignment operation type checking.
- The class constructor may now be either private, protected or public.
- The **class** module now interally handles all serialization and deserialization via the serializer system.
- **class** static constructor must now accept a string (*authenitication code*) as its second argument to be used with the ***class.isstaticconstructorrunning*** helper function. This can now determine whether the static constructor is currently running (to prevent constructor spoofing where needed inside **class** methods).
- **enum** items now have ***\_\_eq*** and ***\_\_lt*** metamethods.
- Subclassing is now able to be limited to certain subclass types by providing either a blacklist or whitelist.

### Fixed
- Bug in ***math.longtorgb*** (now ***math.inttorgb***) causing it to return incorrect values.
- The **class** static constructor not executing correctly.
- The **class** system not permitting **Lua/LuaEx** keywords to be used as member names when using directives.
- **class** kits not adopting parents' protected and public read-only values.
- **Structfactory** not properly cloning itself.
- **Structs** not properly cloning internal objects.
- Instance returns in parent class were not properly returning child instance when subclassed.

---

## [**v0.50**]

### Added
- ***type.assert.function***

### Changed
- Rewrote and completed the interface system for classes.
- All items in tables are now properly cloned.
- Class tables are now cloned so class instances may now start with clonable objects as default properties.

### Fixed
- An error in ***type.assert.table*** where value type was showing as index type, resulting in false negatives.
- An error in **SortedDictionary** causing malformed returns.
- A fatal bug in the cloner system preventing the cloning of items.

## [**v0.40**]

### Added
- Added several class-level methods.
- Added a static initializer to classes (uses a method of the class name in the static public table).

### Changed
- Subclassing can now be controlled with whitelists or blacklists.
- Updated type setting permissions to honor child class instances.
- Reorganized and added sections and examples to README.
- Restructured module layout and added more examples to the **examples** directory.
- **\_\_AUTO** directive prefix format changed to **\_\_AUTO\_\_**.

### Fixed
- Editing kit visibility table during iteration in **\_\_AUTO\_\_** directive was causing malformed classes.
- Private methods not able to be overriden from within the class.
- Public static members could not be set or retrieved.
- The ***\_\_shr*** metamethod not providing '*other*' parameter to client.
- Various, minor bugs.
- Major bug in class **\_\_AUTO\_\_** directive causing malformed classes.

---

## [**v0.30**]

### Added
- New **Ini.lua** module.
- New **base64.lua** module.
- New **cloner.lua** module. Updated various, existing items to make them clonable.
- New **serializer.lua** module that handles serialization and deserialization.
- Several examples in the **examples** directory for demonstrating usage.
- Completed the interface system.
- Added cloning and serialization capabilities.
- **\_\_FNL** directive allowing for final methods and metamethods.
- **\_\_AUTO** directive allowing automatically created mutator and accessor methods for members.
- **\_\_RO** directive for public static fields.

### Changed
- Rewrote *(and improved)* set, stack and queue classes for new class system.
- Global ***is*** functions are now created for classes upon class creation (e.g., isCreature(vInput)).
- Modified **cloner** to work with custom, user-created objects.
- Modified the serializer to work with custom, user-created objects.
- Modified the cloner to work with custom, user-created objects.
- Modified **init.lua** to provide some user options for class loading.
- Changed all class names to PascalCase to provide clear distinction between class variables and other variables.
- Moved several items in the directory structure for refactor.

### Fixed
- Various, minor bugs.

### Removed
- Old **ini.lua** module.
- Old **base64.lua** module.
- Old **serialize.lua** and **deserialize.lua** modules.

---

## [**v0.20**]

### Changed
- Rewrote the class system again from scratch, avoiding fatal flaw in previous system.
- Set types for factories. (*E.g., print(type(class)); --> classfactory*)
- Class members are now strongly typed.
- ***Temporarily*** disabled compulsory classes until they're refactored for the new class system.
- Cleaned up and reorganized a lot of the files in the **LuaEx** module.
- Renamed ***type.x*** to ***type.ex*** and ***typex*** to ***typeex*** to more clearly indicate that the check refers to **LuaEx** types.

### Removed
- Previous class system as it had a fatal, uncorrectable flaw.
- Static protected members from the class system as using them is, almost always, an anti-pattern.
- ***Temporarily*** removed class interface module until it's rewritten to operate with the new class system.

### Fixed
- Renamed the **\_\_LUAEX\_\_** table reference in the **enum** module that got missed.

---

## [**v0.10**]

### Added
- The class interfaces.

### Changed
- Rewrote the class system from scratch.
- The class system now uses full encapsulation (static protected, static public, private, protected and public fields & methods).
- Teh **luaex** table now contains a **\_VERSION** variable.
- Moved various modules to different directories.
- Renamed **\_\_LUAEX\_\_** global table **luaex**.

---

## [**v0.07**]

### Added
- Several type functions and metamethods to various default types (e.g., boolean, string, number, etc.).
- Serialization to enums.
- The **ini** module.
- The ***string.isnumeric*** function.
- A ***\_\_mod*** metamethod for string which allows for easy interpolation.
- The **null** (or **NULL**) type.
- The **struct** factory module.
- The ***xtype*** function.
- The ***fulltype*** function.

###  Changed
- Enum object functions' syntax is now **.** instead of **:** and automatically input themselves as arguments.
- Enum items' ***next*** and ***previous*** functions *may* now wrap around to the start and end respectively.
- Renamed functions in various modules (*namely hook modules*) to conform with Lua's lowercase naming convention.
- Improved the ***string.totable*** function.
- The ***xtype*** function will now ignore user-defined types but return **LuaEx**'s type names for **classes**, **constants**, **enums**, **structs**, **struct factories** (and **struct_factory_constructor**) and **null** (and **NULL**) as opposed to returning, *"table"*. Note: *Use the **rawtype** function to ignore all **LuaEx** type mechanics*.
- Moved all type items to **types.lua**.
- Renamed the ***string.delimitedtotable*** function to ***string.totable***.

### Fixed
- Corrected several minor bugs in enum library.
- Corrected assertions in stack class.
- The ***set.addset*** method was not adding items.

---

## [**v0.06**]

### Added
- The ***string.trim*** function.
- The ***string.trimleft*** function.
- The ***string.trimright*** function.

### Changed

### Fixed
- Corrected package.path code in init.lua and removed ***import*** function.
- Moved modules into appropriate subdirectories and updated init.lua to find them.
- Appended ***string***, ***math*** & ***table*** module files with "hook" without which they would not load properly.
- Updated ***README.md*** with more information.

### Removed
- The ***string.left*** function as it was an unnecessary and inefficient wrapper of ***string.sub***.
- The ***string.right*** function as it was an unnecessary and inefficient wrapper of ***string.sub***.

---

## [**v0.05**]

### Added
- The ***protect*** function (in ***stdlib***).
- The ***sealmetatable*** function (in ***stdlib***).
- The ***subtype*** function (in ***stdlib***).
- The ***table.lock*** function.
- The ***table.purge*** function.
- The ***table.settype*** function.
- The ***table.setsubtype*** function.
- The ***table.unlock*** function.
- The ***queue*** class.
- The ***set*** class.
- The ***stack*** class.

### Changed
- Classes are no longer automatically added to the global scope when created; rather, they are returned for the calling script to handle.
- **LuaEx** classes and modules are no longer auto-protected and may now be hooked or overwritten. This change does not affect the way constants and enums work in terms of their immutability.
- **enums** values may now be of any non-nil type(previously only **string** and **number** were allowed).
- The **class** constructor method now passes, not only the instance, but a protected, shared (fields and methods) table to parent classes.
- **enums** may now be nested.

### Fixed
- ***table.lock*** was altering the metatable of **enums** when it should not have been.
- ***table.lock*** was not preserving metatable items (where possible).

---

## [**v0.04**]

### Changed
- Enums can now also be non-global.
- The enum created by a call to the enum function is now returned.

### Fixed
- Metavalue causing custom type check to fail to return the proper value.
- Typo that caused global enums to not be put into the global environment.

---

## [**v0.03**]

### Added
- A meta table to ***\_G*** in the **init** module.

### Changed
- The name of the **const** module and function to **constant** for Lua 5.1 - 5.4 compatibility.
- Altered the way constants and enums work by using the new, ***\_G*** metatable to prevent deletion or overwriting.
- Updated several modules.
- Hardened the protected table to prevent accidental tampering.

---

## [**v0.02**]

### Added
- The enum object.

### Changed
- Updated a few modules.

---

## [**v0.01**]

### Added
- Compiled various modules into **LuaEx**.
