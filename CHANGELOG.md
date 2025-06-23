<div align="center">
  <img src="https://raw.githubusercontent.com/CentauriSoldier/LuaEx/main/logo.png" alt="LuaEx">
  <h1>🅲🅷🅰🅽🅶🅴🅻🅾🅶</h1>
</div>

## [**v0.92**] (*in progress*)

---

## [**v0.91**]

### Added
- New **eventrix** type to manage events.    
- Several class-level checks:
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
- **Dox** comment blocks can now use internal anchor links (*#*) to other FQXNs.
- **Dox** output back navigation.
- **Dox** now uses **prism.js** for displaying code blocks with syntax highlighting for all available **prism.js** languages.
- "Copy" (to clipboard) button to all user-created code blocks in **Dox** HTML output.
- **Code** ***BlockTag*** to Dox, permitting code examples with any user-specified **prism.js** language.
- **Example** ***BlockTag*** now automatically detects the **prism.js** language based on the **Dox** subclass being used.
- Relevant **prism.js** scripts are automatically added to **Dox's** finalized HTML output based on the languages used in the documentation.
- **Dox** **Parsers** (subclasses) for several new languages.

### Changed
- Moved the changelog from README.md to its own file.
- Modified the changelog to be more in line with [keepachangelog.com](https://keepachangelog.com/en/1.1.0/) standards.
- Consolidated the old **class** changelog (*in the module's documentation*) into **LuaEx's** changelog.
- Appropriate class-level check functions now intuitively return the class object where expected but only when the class is in scope, nil otherwise.
- Classes now fully respect polymorphism in assignment operation type checking.
- The class constructor may now be either private, protected or public.
- The **class** module now interally handles all serialization and deserialization via the serializer system.
- **class** constructor must now accept a string (*authenitication code*) as its second argument to be used with the ***class.isstaticconstructorrunning*** function. This can now determine whether the static constructor is currently running.
- **enum** items now have ***__eq*** and ***__lt*** metamethods.
- **Dox** now auto-combines certain multiple built-in ***BlockTag*** items such as **Param**, **Return**, etc. into a single section.
- ***DoxBlockTags*** can now be set to *combined* which places all items using that tag into one section.
- **Dox** now has an ***@inheritdoc*** tag that allows inheritance of docs from one **fqxn** to another.
- **Dox** Fully Qualified Dox Names (**fqxn**) may now contain spaces.
- **Dox** now allows custom intro page message.
- Subclassing is now able to be limited to certain subclass types by providing either a blacklist or whitelist.
- **DoxBuilderHTML** now places all output into a single HTML file instead of using a separate *.js* file.
- **Dox** CSS redesigned to be more functional, readable and aesthetically pleasing.
- **DoxBlockTag** column wrappers are now defined by each **DoxBuilder** subclass rather than globally.

### Fixed
- The **class** static constructor not executing correctly.
- The **class** system not permitting **Lua/LuaEx** keywords to be used as member names when using directives.
- **CoG** not allowing recursive access to *config* table.
- **Dox** displaying parameters, returns and other combined tags out of order.
- **class** kits not adopting parents' protected and public read-only values.
- **Structfactory** not properly cloning itself.
- **Structs** not properly cloning internal objects.
- Instance returns in parent class were not properly returning child instance when subclassed.

---

## [**v0.90**]

### Added
- Support for code html tags using **prism.js** in **Dox** module.
- Several new features to **Dox** and prepped it for major updates in future releases.
- ***type.assert.function***

### Changed
- Rewrote and completed the interface system for classes.
- All items in tables are now properly cloned.
- Class tables are now cloned so class instances may now start with clonable objects as default properties.

### Fixed
- An error in ***type.assert.table*** where value type was showing as index type, resulting in false negatives.
- An error in **SortedDictionary** causing malformed returns.
- A fatal bug in the cloner system preventing the cloning of items.

## [**v0.83**]

### Added
- Added several class-level methods.
- Added a static initializer to classes (uses a method of the class name in the static public table).

### Changed
- Subclassing can now be controlled with whitelists or blacklists.
- Updated type setting permissions to honor child class instances.
- Reorganized and added sections and examples to README.
- Integrated and rewrote Dox documentation module and added support for other languages.
- Restructured module layout and added more examples to the **examples** directory.
- **\_\_AUTO** directive prefix format changed to **\_\_AUTO\_\_**.

### Fixed
- Editing kit visibility table during iteration in **\_\_AUTO\_\_** directive was causing malformed classes.
- Private methods not able to be overriden from within the class.
- Public static members could not be set or retrieved.
- __shr method not providing 'other' parameter to client.
- Various, minor bugs.
- Major bug in class **\_\_AUTO\_\_** directive causing malformed classes.

---

## [**v0.82**]

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

## [**v0.81**]

### Changed
- Rewrote the class system again from scratch, avoiding fatal flaw in previous system.
- Set types for factories. (*E.g., print(type(class)); --> classfactory*)
- Class members are now strongly typed.
- ***Temporarily*** disabled compulsory classes until they're refactored for the new class system.
- Cleaned up and reorganized a lot of the files in the **LuaEx** module.
- Renamed ***type.x*** to ***type.ex*** and ***typex*** to ***typeex*** to more clearly indicate that the check refers to **LuaEx** types.

### Removed
- Class system from **v0.80** as it had a fatal, uncorrectable flaw.
- Static protected members from the class system as using them is, almost always, an anti-pattern.
- ***Temporarily*** removed class interface module until it's rewritten to operate with the new class system.

### Fixed
- Renamed the **\_\_LUAEX\_\_** table reference in the **enum** module that got missed.

---

## [**v0.80**]

### Added
- The class interfaces.

### Changed
- Rewrote the class system from scratch.
- The class system now uses full encapsulation (static protected, static public, private, protected and public fields & methods).
- Teh **luaex** table now contains a **\_VERSION** variable.
- Moved various modules to different directories.
- Renamed **\_\_LUAEX\_\_** global table **luaex**.

---

## [**v0.70**]

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

## [**v0.60**]

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

## [**v0.50**]

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

## [**v0.40**]

### Changed
- Enums can now also be non-global.
- The enum created by a call to the enum function is now returned.

### Fixed
- Metavalue causing custom type check to fail to return the proper value.
- Typo that caused global enums to not be put into the global environment.

---

## [**v0.30**]

### Added
- A meta table to ***\_G*** in the **init** module.

### Changed
- The name of the **const** module and function to **constant** for Lua 5.1 - 5.4 compatibility.
- Altered the way constants and enums work by using the new, ***\_G*** metatable to prevent deletion or overwriting.
- Updated several modules.
- Hardened the protected table to prevent accidental tampering.

---

## [**v0.20**]

### Added
- The enum object.

### Changed
- Updated a few modules.

---

## [**v0.10**]

### Added
- Compiled various modules into **LuaEx**.
