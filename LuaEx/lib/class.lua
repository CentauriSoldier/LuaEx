--[[!
@fqxn LuaEx.Class System
@desc
    <h3>Lua's (<i>pseudo</i>) Object Oriented Programming</h3>
    <p>The class module aims to bring a simple-to-use, fully functional, OOP class system to Lua to the extent that such a feat is possible.
    <br>Among other things, It includes encapsulation, inheritence & polymorphism, final, limited and abstract classes, final methods, auto-setter/getter and read-only directives (<b><i>properties</i></b>) as well as interfaces.
    </p>
@features
<h4>Strongly Typed</h4>
<p>Fields that are set in classes remain the type with which they were intialized. The only expection to this is the <a href="#LuaEx.Class System.null">null</a> value. Any field set to null in its declaration can be changed to any other type once. Once the type has been set, it cannot be changed again. This allows field types be to set during contruction or on first mutation.
<br><br>
Fields marked as read-only cannot be modified once set. This, of course, excludes fields initialized as null. They can be set once and only once from the null value to something else.
<br><br>
Class methods cannot be overriden except by subclasses and only if they're not marked as final by the parent class.
</p>
<h4>Encapsulation</h4>
<p>Class tables' access is appropriately restricted to prevent incidental access. Each class method (and metamethod) is infused with two arguments. The first is the class object itself so each method has access to the protected and public fields and methods of the class. The second is the class data table which is indexed by five tables:
<ul>
    <li><b>met</b></li> (class metamethods)
    <li><b>pri</b></li> (class private fields and methods)
    <li><b>pro</b></li> (class protected fields and methods)
    <li><b>pub</b></li> (class public fields and methods)
    <li><b>ins</b></li> (class instances)
</ul>
<b>Note</b>: for obvious reasons, methods in the static public table do not get infused with these instance-specific arguments. The only method in that table that has an argument infused into it is the static inializer <i>(not to be confused with the static constructor)</i> that has the static public table as its first argument to allow it to make changes to the static public tables upon class creation.
<br>
<br>
To facilitate a class's instances accessing and mutating each other (as is common in most other programming laguages), the <b>ins</b> table is provided. This table is indexed by class instance objects whose values are the class data of that instance. This allows other class instances input as arguments into a method to be directly manipulated (incuding private, protected, etc.) by the class method.
<b>Note</b>: as is expected, this works only for instances of the same class. ClassA cannot access class data from an instance of ClassB.
</p>
<h4>Inheritance</h4>
<br><p>Subclasses can be created by declaring the Parent class in the class arguments.</p>
<p>Each subclasses will inherit all protected and public fields and methods from the parent class and may access them as if they were its own.</p>
<p>Parent methods can be overriden by the child class unless they are marked as final in the parent class.
<h5>Restrictions on Inheritance</h5>
<ol>
    <li>Any class with a blacklist or whitelist may or may not allow certain classes to subclass it.</li>
    <li>Classes marked as final cannot be subclassed.</li>
</ol>
</p>
<h4>Polymorphism</h4>
<p>Polymorphism is a key component of the class system and is honored in class fields.
<br>For example, if a class has a Creature class object (whose subclasses are Human and Monster) as a field, the object in that field can be changed to either another Creature, a Human or a Monster since Human and Monster are both subclasses of the Creature class.</p>
@website https://github.com/CentauriSoldier/LuaEx
!]]


--LOCALIZATION

local function classError(sMessage, nLevel)
    error("Error in class.\n"..sMessage, nLevel + 1);
end

local met       = "met";    --the instance's metatable
local stapub    = "stapub"  --the class's static public table
local pri       = "pri";    --the instance's private table
local pro       = "pro";    --the instance's protected table
local pub       = "pub";    --the instance's public table
local ins       = "ins";    --a table containing all the instances

local _tCAINames = {             --primarily used for error messages
    met     = "metamethods",    --the instance's metatable
    stapub  = "static public",  --the class's static public table
    pri     = "private",        --the instance's private table
    pro     = "protected",      --the instance's protected table
    pub     = "public",         --the instance's public table
    ins     = "instances",      --a table containing all the instances
};

local _tSerializerIndices = {"pri", "pro", "pub"};

local assert            = assert;
local getmetatable      = getmetatable;
local pairs             = pairs;
local rawget            = rawget;
local rawgetmetatable   = rawgetmetatable;
local rawset            = rawset;
local rawtype           = rawtype;
local setmetatable      = setmetatable;
local string            = string;
local table             = table;
local type              = type;

--WARNING   changing these values can break the entire system; modify at your own risk
--NOTE      when modifying/adding/removing items in this table, be sure to update them in instance.wrapMetamethods()
local _tMetaNames = { --the value indicates whether the index is allowed
__add 		= true,     __band        = true,     __bnot      = true,
__bor 		= true,     __bxor        = true,	  __call      = true,
__close     = false,    __concat 	  = true,     __div	      = true,
__eq        = true,	    __gc 	      = false,    __idiv	  = true,
__index     = false,    __ipairs      = true,     __le        = true,
__len       = true,	    __lt	      = true,	  __metatable = false,
__mod 		= true,     __mode 		  = false,    __mul 	  = true,
__name 	    = true,	    __newindex    = false,    __pairs     = true,
__pow 		= true,     __shl 		  = true,	  __shr       = true,
__sub 	    = true,	    __tostring	  = true,     __unm 	  = true,
__serialize = true,    __clone       = true,}; --TODO Set serialize to false ocne serializer is done

local function getMetaNamesAsString()
    local sRet              = "";
    local tSortedMetaNames  = {};

    for sName, bAllowed in pairs(_tMetaNames) do

        if (bAllowed) then
            table.insert(tSortedMetaNames, sName);
        end

    end

    table.sort(tSortedMetaNames);

    for _, sName in pairs(tSortedMetaNames) do
        sRet = sRet..sName..", ";
    end

    return sRet:sub(1, #sRet - 2);
end

--these are the types that can be changed when static public
local tMutableStaticPublicTypes = {
    ["boolean"]     = true,
    ["number"]      = true,
    ["string"]      = true,
    ["table"]       = true,
};

local function isMutableStaticPublicType(sType)
    return (tMutableStaticPublicTypes[sType] or false);
end


local _tAuthenticationCodes = {}; --used in static constructors, indexed by class kit
                    --[[
                    ██╗███╗   ██╗██╗████████╗██╗ █████╗ ██╗     ██╗███████╗███████╗██████╗ ███████╗
                    ██║████╗  ██║██║╚══██╔══╝██║██╔══██╗██║     ██║╚══███╔╝██╔════╝██╔══██╗██╔════╝
                    ██║██╔██╗ ██║██║   ██║   ██║███████║██║     ██║  ███╔╝ █████╗  ██████╔╝███████╗
                    ██║██║╚██╗██║██║   ██║   ██║██╔══██║██║     ██║ ███╔╝  ██╔══╝  ██╔══██╗╚════██║
                    ██║██║ ╚████║██║   ██║   ██║██║  ██║███████╗██║███████╗███████╗██║  ██║███████║
                    ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝
                    ]]
--[[!
@fqxn LuaEx.Class System.Initialization
@desc When a class is built, there is an opportunity to call a static initializer, a static constructor or both.
<h3>The Static Initializer</h3>
<p>The static initializer is called by creating a static public method named <b>__INIT</b>. This is called <b><i>before</i></b> the class object is created and is used to modify the static public fields and methods. Items can be added, changed or deleted from the static public table of the class at this point. The only parameter passed to the <b>__INIT</b> method is the static public table.<br><b>Note</b>: Since the class has not yet been built, this cannot access/modify class methods that have yet to be added during the class object's assembly or any other fields declared in the non-static portion of the class declaration.</p>
<h3>The Static Constructor</h3>
<p>The static constructor is called by creating a static public method having the <b><u>exact</u></b> same name as the class itself. This is called <b><i>after</i></b> the class object is created and is used to perform static operations while having access to the fully-built class object. The two parameters passed to the static constructor method are the class object itself and an authentication code for proving (often to parent, static methods) that this class's static constructor is currently running. This can be tested by running the <b>class.isstaticconstructorrunning</b> method inputing the class object and authentication code.
<br><b>Note</b>: the authentication code is destroyed upon the static constructor being run so the test will pass only while the static constructor is running.
<br><b>Note</b>: actions performed using the class object are governed as would any actions on the class object performed outside the static constructor. That is, the static constructor is given no special privileges or access to the class object.
!]]
local _sClassStaticInitializer = "__INIT";



                    --[[
                    ██████╗ ██╗██████╗ ███████╗ ██████╗████████╗██╗██╗   ██╗███████╗███████╗
                    ██╔══██╗██║██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║██║   ██║██╔════╝██╔════╝
                    ██║  ██║██║██████╔╝█████╗  ██║        ██║   ██║██║   ██║█████╗  ███████╗
                    ██║  ██║██║██╔══██╗██╔══╝  ██║        ██║   ██║╚██╗ ██╔╝██╔══╝  ╚════██║
                    ██████╔╝██║██║  ██║███████╗╚██████╗   ██║   ██║ ╚████╔╝ ███████╗███████║
                    ╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝╚══════╝]]
--[[!
@fqxn LuaEx.Class System.Directives
@desc Directives provide a way for classes to set methods as final,
<br>set values as read only and create <a href="#LuaEx.Class System.class.Properties">Properties</a>.
<br><br>
<h3>List of Base Directives</h3>
<ul>
    <li><strong>__AUTO__</strong> The Upper Auto Directive</li>
    <li><strong>__auto__</strong> The Lower Auto Directive</li>
    <li><strong>__FNL</strong> The Final Directive</li>
    <li><strong>__RO</strong> The Read-only Directive</li>
</ul>
<hr>
<h3>Auto Directives</h3>
<p>Auto directives may be applied only to class members that are fields, never methods.
<br>They can be used to create accessor and/or mutator methods for that field.
<br><br>The Upper and Lower Auto Directives behave identically except that when method prefixes are auto-generated,
<br>the Upper Auto makes the first letter of the method uppercase and the Lower Auto makes it lowercase.
<br><br>
The last two characters (__) of the directive can be changed to allow customization of the method(s) and field.
<br><br>
The first of the two underscores refers to the methods to be created.
<ul>
    <li>If an "<strong>A</strong>" is used, only an accessor method will be created for the field.</li>
    <li>If an "<strong>M</strong>" is used, only a mutator method will be created for the field.</li>
    <li>If an "<strong>R</strong>" is used, only an accessor method will be created for the field and the field will be set to read-only.</li>
    <li>If any other character (including an underscore) is used, both an accessor and mutator method will be created for the field.</li>
</ul>
<br><br>
The second of the two underscores refers to the finality of the methods created (whether they can be overriden by subclasses).
<ul>
    <li>If an "<strong>A</strong>" is used, only the accessor method will be set to final.</li>
    <li>If an "<strong>M</strong>" is used, only the mutator method will be set to final.</li>
    <li>If an "<strong>F</strong>" is used, both the accessor and mutator methods will be set to final.</li>
    <li>If any other character (including an underscore) is used, neither method will be set to final.</li>
</ul>
<br>
<br>
<strong>Note</strong>: As with all other fields, directive fields may contain only the types for which they were designed.
<br><strong>Note</strong>: The exception (as with other fields) being, initial null values are permitted.
<br><br>
In addition, if any characters are found after the trailing two underscodes (or letters if applicable), that string will be used for the accessor prefix.
<pre><code class="language-lua">
--this will create an accessor method named 'isEnabled' and a mutator method called 'setEnabled'
Enabled__auto__is = true
--this will create an accessor method named 'getEnabled' and a mutator method called 'setEnabled'
Enabled__auto__ = true
--this will create an accessor method named 'isEnabled' and set the field to read-only.
Enabled__autoR_is = true
</code></pre>
<hr>
</p>
<h3>Final Directive</h3>
<p>
Adding the __FNL directive to the end of a method name prevents it from being overridden by a child class.
<pre><code class="language-lua">
MyMethod__FNL = function() end
</code></pre>
</p>
<h3>Read-only Directive</h3>
<p>
By adding the __RO directive to the end of a field name, it becomes read-only and may not be interally or externally modified.
<pre><code class="language-lua">
MyField__RO = 12,
</code></pre>
</p>
!]]
--[[!
@fqxn LuaEx.Class System.class.Properties
@desc Properties are fields which have accessor/mutator methods auto-created by using <a href="#LuaEx.Class System.Directives">Directives</a>.
!]]
local _sDirectiveAutoUpper          = "__AUTO";
local _sDirectiveAutoLower          = "__auto";
local _sDirectiveFNL                = "__FNL";
local _sDirectiveRO                 = "__RO";

            --[[
                ███╗   ███╗ █████╗ ██╗███╗   ██╗    ████████╗ █████╗ ██████╗ ██╗     ███████╗███████╗
                ████╗ ████║██╔══██╗██║████╗  ██║    ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
                ██╔████╔██║███████║██║██╔██╗ ██║       ██║   ███████║██████╔╝██║     █████╗  ███████╗
                ██║╚██╔╝██║██╔══██║██║██║╚██╗██║       ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
                ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║       ██║   ██║  ██║██████╔╝███████╗███████╗███████║
                ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝       ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝]]

--TODO make sure all these values are being updated or delete if not being used
local class = {
    count       = 0,
    --children    = {},
    --parents     = {},
    repo        = { --updated on kit.build()
        byKit       = {}, --indexed by kit
        byName      = {}, --index by class/kit name
        byObject    = {}, --indexed by class, value is kit
        isFunctions = {}, --indexed by class, value is class "is" function
    },
};


local instance = {
    repo = {
        --TODO do I need these?
        byClass = {}, --indexed by class object
        byKit   = {}, --indexed by kit
        byName  = {}, --index by class/kit name
        byObject= {}, --has info about the instance such as class, kit, etc.
    },
};


local kit = {
    --trackers, repo & other properties
    count  = 0, --keep track of the total number of class kits
    repo   = { --stores all class kits for later use
        byName 		= {}, --indexed by class/kit name | updated on kit.build()
        byObject 	= {}, --index by class object | updated when a class object is created
    },
};

--used to check for child overrides on soon-to-be AUTO properties
_fAutoPlaceHolder = function() end;


                --[[
                ██████╗ ███████╗██╗      █████╗ ████████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗
                ██╔══██╗██╔════╝██║     ██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██║
                ██████╔╝█████╗  ██║     ███████║   ██║   ██║██║   ██║██╔██╗ ██║███████║██║
                ██╔══██╗██╔══╝  ██║     ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║██╔══██║██║
                ██║  ██║███████╗███████╗██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║██║  ██║███████╗
                ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝

                ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
                ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
                █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
                ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
                ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║]]

--[[
--[[!
@fqxn LuaEx.Class System.class.Functions
@desc While there are many local functions in this list, there also several global class helper functions that provide essential utilities for querying and managing class relationships, inheritance structures, and object identification.
<br>They enable checking class existence (exists), retrieving class hierarchy details (getbase, getparent, getchildren), determining relationships (isbaseof, ischild, isparent, etc.), verifying object types (isinstance, of), and ensuring proper class instantiation (isstaticconstructorrunning).
<br>Collectively, these functions support robust type checking, hierarchy traversal, and validation of inheritance and instance properties.
!]]

--TODO use error instead of assert so error level can be set (or can it be on assert?)..assert is slower...]]


-->>>>>WARNING: this function should not be exposed as it is for internal use only
local function getKit(vClass)
    return class.repo.byObject[vClass] or kit.repo.byName[vClass] or nil;
end
--<<<<<<<

--ideas: to add - isinscope, getlineageordinal, issibling (direct sister classes), is relative (connected to any other class that is connected)


--[[!
@fqxn LuaEx.Class System.class.Functions.exists
@desc Determines whether a class exists.
@param string sClass The name of the class.
<br><b>Note</b>, if a class object is passed instead of a string, it returns true as well.
@ret boolean bExists True if the class exists, false otherwise.
!]]
local function exists(vClass)
    return (kit.repo.byName[vClass] or class.repo.byObject[vClass]) ~= nil;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getbase
@desc Gets a class's base class object (if both exist and the base is in scope).
@param class|string vClass The class or name of the class.
@ret class|nil cClass The class's base class object <i>(if both exist, the base is in scope and the class has a base)</i>, or nil otherwise.
!]]
local function getbase(vClass)
    local cRet;
    local tKit = getKit(vClass);

    if tKit and tKit.base and tKit.base.isInScope() then
        cRet = class.repo.byKit[tKit.base];
    end

    return cRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getbyname
@desc Gets a class object given the class name (if it's in scope).
@param string sClass The name of the class object.
@ret class|nil cClass The class object (if it's in scope), or nil otherwise.
!]]
local function getbyname(sClass)
    local cRet;
    local tKit = getKit(sClass);

    if (tKit and tKit.isInScope()) then
        cRet = class.repo.byKit[tKit];
    end

    return cRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getchildcount
@desc Gets the number of direct children a class has.
@param class|string vClass The class or name of the class.
@ret number nChildren The number of direct children the class has. If an error occurs, -1 is returned.
!]]
local function getchildcount(vClass)
    local tKit = getKit(vClass);

    return  (tKit and tKit.children.count or -1);
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getchildren
@desc Gets all the direct children of a class (those that are in scope).
@param class|string vClass The class or name of the class.
@ret table|nil tChildren A numerically-indexed table whose values are class objects who are direct children of the input class. If the input is bad, the class doesn't exist or there are no direct children of the class that are in scope, nil is returned.
!]]
local function getchildren(vClass)
    local vRet;
    local tKit = getKit(vClass);

    if (tKit and tKit.children.count > 0) then

        for cChild, tChildKit in pairs(tKit.children.direct.byObject) do

            if tChildKit.isInScope() then

                if not (vRet) then
                    vRet = {}; --[[ must be created here (as opposed to
                                    being created before the loop) in case
                                    there are no in-scope children]]
                end

                vRet[#vRet + 1] = cChild;
            end

        end

    end

    return vRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getconstructorvisibility
@desc Gets a class's constructor visiblity.
@param class cClass The class to query.
@ret string|nil sVisibility The visiblity of class's constructor or nil if the input is invalid or the class doesn't exist.
!]]
local function getconstructorvisibility(vClass)
    local vRet;
    local tKit = getKit(vClass);

    if (tKit) then
        vRet = tKit.constructorVisibility;
    end

    return vRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getname
@desc Gets the class name of a class.
@param class cClass The class for which to get the name.
@ret string|nil sClass The name of class or nil if the input is invalid or the class doesn't exist.
!]]
local function getname(vClass)
    local tKit = getKit(vClass);
    return tKit and tKit.name or nil;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.getparent
@desc Gets the parent class object of the input class.
@param class|string vClass The class or name of the class for which to get the parent.
@ret class|nil cClass The parent class or nil if the input is invalid or either class doesn't exist or isn't in scope.
!]]
local function getparent(vClass)
    local vRet;
    local tKit = getKit(vClass);

    if tKit and tKit.parent then

        if (tKit.isInScope() and tKit.parent.isInScope()) then
            vRet = class.repo.byKit[tKit.parent];
        end

    end

    return vRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.haschildren
@desc Determines if a class has children.
@param class|string vClass The class (or class name) to check.
@ret boolean bHasChildren True if it's a class and has children, false otherwise.
!]]
local function haschildren(vClass)
    local tMyKit = getKit(vClass);

    return  ( tMyKit  and
              tMyKit.children.count > 0 );
end


--[[!
@fqxn LuaEx.Class System.class.Functions.is
@desc Determines if something is a class object.
@param any vValue The item to check.
@ret boolean bIsClass True if it's a class object, false otherwise.
!]]
local function is(vClass)
    return (class.repo.byObject[vClass]) ~= nil;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isbase
@desc Determines if a class is a base class.
@param class|string vClass The class to test.
@ret boolean bIsChild True if it's a base class, false otherwise.
!]]
local function isbase(vClass)
    local tKit = getKit(vClass);
    return (tKit and (not tKit.base) );
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isbaseof
@desc Determines if class A is the base class of class B.
@param class|string vClassA The potential base class.
@param class|string vClassB The potential non-base class.
@ret boolean bIsChild True if it's a child, false otherwise.
!]]
local function isbaseof(vClassA, vClassB)
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassA);

    return (    tKitA and tKitB and
                not tKitA.base and tKitB.base and
                (tKitA.children.all.byName[tKitB.name]) ~= nil);
end


--[[!
@fqxn LuaEx.Class System.class.Functions.ischild
@desc Determines if class A is a child (however far removed) of class B.
@param class|string vClassA The potential child class.
@param class|string vClassB The potential parent class.
@ret boolean bIsChild True if it's a child, false otherwise.
!]]
local function ischild(vClassA, vClassB)
    local bRet  = false;
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassB);

    if ( (tKitA and tKitB) and (tKitA ~= tKitB) ) then
        bRet = tKitB.children.all.byName[tKitA.name] ~= nil;
    end

    return bRet;
end

--[[!
@fqxn LuaEx.Class System.class.Functions.ischildorself
@desc Determines if class A is a child of class B or is that class itself.
@param class|string vClassA The potential child (or self) class.
@param class|string vClassB The potential parent (or self) class.
@ret boolean bIsChildOrSelf True if it's a child or self, false otherwise.
!]]
local function ischildorself(vClassA, vClassB)
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassB);

    local bIsChild  = false;
    local bIsSelf   = false;

    if (tKitA and tKitB) then
        bIsChild  = tKitB.children.all.byName[tKitA.name] ~= nil;
        bIsSelf   = tKitA == tKitB;
    end

    return bIsChild or bIsSelf;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isdirectchild
@desc Determines if class A is a direct descendant of class B.
@param class|string The potential child class.
@param class|string The potential parent class.
@ret boolean bIsDirectChild True if it's a direct descendant, false otherwise.
!]]
local function isdirectchild(vClassA, vClassB)
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassB);

    local bIsDirectChild = false;

    if ( (tKitA and tKitB) and (tKitA ~= tKitB) ) then
        bIsDirectChild = tKitB.children.direct.byName[tKitA.name] ~= nil;
    end

    return bIsDirectChild;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isdirectparent
@desc Determines if class A is the direct parent of class B.
@param class|string vClassA The potential parent class.
@param class|string vClassB The potential child class.
@ret boolean bIsDirectParent True if it's the direct parent, false otherwise.
!]]
local function isdirectparent(vClassA, vClassB)
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassB);

    local bIsDirectParent = false;

    if ( (tKitA and tKitB) and (tKitA ~= tKitB) ) then
        bIsDirectParent = (tKitA.children.direct.byObject[vClassB] or tKitA.children.direct.byName[vClassB]) ~= nil;
    end

    return bIsDirectParent;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isinlineage
@desc Determines if class A is in the lineage <i>(parent, child or self)</i> of class B.
@param class|string vClassA The potential relative class.
@param class|string vClassB The lineage class.
@ret boolean bIsInLineage True if the two classes are in the same lineage, false otherwise.
!]]
local function isinlineage(vClassA, vClassB)
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassB);

    local bIsSelf       = false;
    local bAIsChildOfB  = false;
    local bAIsParentOfB = false;

    if (tKitA and tKitB) then
        bIsSelf = tKitA == tKitB;

        if not (bIsSelf) then
            bAIsChildOfB = tKitB.children.all.byName[tKitA.name] ~= nil;

            if not (bAIsChildOfB) then
                bAIsParentOfB   = tKitA.children.all.byName[tKitB.name] ~= nil;
            end

        end

    end

    return bIsSelf or bAIsChildOfB or bAIsParentOfB;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isinstance
@desc Determines if something is an instance object of any class.
@param any vValue The item to check.
@ret boolean bIsInstance True if it's an instance of a class, false otherwise.
!]]
local function isinstance(vInstance)
    return instance.repo.byObject[vInstance] ~= nil;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isinstanceof
@desc Determines if something is an instance of a specific class.
@param object oInstance The instance object to check.
@param class|string vClass the class or the name of the class in question.
@ret boolean bIsInstanceOf True if it's an instance of the specified class, false otherwise.
!]]
local function isinstanceof(vInstance, vClass)
    local bRet      = false;
    local tInstance = instance.repo.byObject[vInstance];

    if (tInstance) then
        local tClassKit = getKit(vClass);

        if (tClassKit) then
            bRet = tInstance.kit.name == tClassKit.name;
        end

    end

    return bRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isparent
@desc Determines if class A is a parent (however far removed) of class B.
@param class|string vClassA The potential parent class.
@param class|string vClassB The potential child class.
@ret boolean bIsParent True if it's a parent, false otherwise.
!]]
local function isparent(vClassA, vClassB)
    local tKitA = getKit(vClassA);
    local tKitB = getKit(vClassB);

    local bIsParent = false;

    if ( (tKitA and tKitB) and (tKitA ~= tKitB) ) then
        bIsParent = (tKitA.children.all.byName[tKitB.name]) ~= nil;
    end

    return bIsParent;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isparentorself
@desc Determines if class A is a parent of class B or is that class itself.
@param class|string vClassA The potential parent (or self) class.
@param class|string vClassB The potential child (or self) class.
@ret boolean bIsParentOrSelf True if it's a parent or self, false otherwise.
!]]
local function isparentorself(vClassA, vClassB)
    local tKitA    = getKit(vClassA);
    local tKitB    = getKit(vClassB);

    local bIsParent = false;
    local bIsSelf   = false;

    if (tKitA and tKitB) then
        bIsSelf   = tKitA == tKitB;
        bIsParent = (tKitA.children.all.byObject[vClassB] or tKitA.children.all.byName[vClassB]) ~= nil;
    end

    return bIsParent or bIsSelf;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.isstaticconstructorrunning
@desc Determines if the static constructor of a class is being executed by validating it though the autentication code passed to it.
@param class|string vCaller The calling class (or name of calling class) to check.
@param string sAuthCode The authentication code (that is passed to each class's static constructor).
@ret boolean bIsRunning True if the code is being executed inside a class's static constructor, false otherwise.
!]]
local function isstaticconstructorrunning(vClass, sAuthCode)
    local bRet = false;
    local tKit = getKit(vClass);

    if (tKit and type(sAuthCode) == "string" and _tAuthenticationCodes[tKit]) then
        bRet = _tAuthenticationCodes[tKit] == sAuthCode;
    end

    return bRet;
end


--[[!
@fqxn LuaEx.Class System.class.Functions.of
@desc Gets the class object of an instance object.
@param instance oInstance The instance object for which to find the class.
@ret class|nil cClass The class object that produced the instance object or nil if the input is invalid or the class is not in scope.
!]]
local function of(vInstance)
    local vRet;
    local tInstance = instance.repo.byObject[vInstance];

    if (tInstance) then
        local cClass    = tInstance.class;
        local tKit      = kit.repo.byObject[cClass];

        if (tKit and tKit.isInScope()) then
            vRet = cClass;
        end

    end

    return vRet;
end


--TODO go through and set error levels on every error (test each one)
--TODO abstract methods (no static public allowed obviously, throw error in such case)
--TODO forbid type names (string, boolean, etc)
                            --[[ ██████╗██╗      █████╗ ███████╗███████╗
                                ██╔════╝██║     ██╔══██╗██╔════╝██╔════╝
                                ██║     ██║     ███████║███████╗███████╗
                                ██║     ██║     ██╔══██║╚════██║╚════██║
                                ╚██████╗███████╗██║  ██║███████║███████║
                                ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝]]
                                --[[!
                                @fqxn LuaEx.Class System.class
                                @desc The table containing the class functions and data.
                                !]]

--TODO ERROR BUG FIX interfaces are throwing an error for missing metamethods even though parents have them
--[[!
@fqxn LuaEx.Class System.class.Functions.build
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the <a href="#LuaEx.Class System.kit">kit</a> table. This is called by kit.build().
<br>For info on class initializers and constructors, see <a href="#LuaEx.Class System.Initialization">Initialization</a>.
@ret class A class object.
!]]
function class.build(tKit)
    local oClass    = {}; --this is the class object that gets returned
    local sName     = tKit.name;

    --this is the actual, hidden class table referenced by the returned class object
    local tClass    = clone(tKit.stapub);   --create the static public members

    --execute then delete the static initializer (if it exists)
    if (rawtype(tClass[_sClassStaticInitializer]) == "function") then
        tClass[_sClassStaticInitializer](tClass);
        rawset(tClass, _sClassStaticInitializer, nil);
    end

    --used to build instances of the class (used as __call alias as well as for deserialization)
    local function buildInstance(_, ...)
        local oInstance = {};
        local tDataMeta = rawgetmetatable(_);
        local tData     = ( tDataMeta                                       and
                            tDataMeta.__deserialmarker                      and
                            tDataMeta.__deserialmarker == "serializeddata") and _ or nil;
        local bIsNormalCall = (tData == nil) and true or false;
        local bReturnInstanceTable = not bIsNormalCall;


        --make a list of the parents (if any)
        local tParents          = {};
        local tParentKit        = tKit.parent;
        local bHasParent        = false;

        --order them from top-most, descending
        while (tParentKit) do
            bHasParent = true;

            table.insert(tParents, 1, {
                kit     = tParentKit,
                decoy   = nil,
                actual  = nil,
                }
            );

            tParentKit = tParentKit.parent;
        end

        --instantiate each parent
        for nIndex, tParentInfo in ipairs(tParents) do
            local tMyParent = nil;

            if nIndex > 1 then
                tMyParent = tParents[nIndex - 1].actual;
            end

            local sParenttext = tMyParent and tMyParent.metadata.kit.name or "NO PARENT"; --TODO QUESTION is this ever used?

            --instantiate the parent object
            local tParent = instance.build(oInstance, tData, tParentInfo.kit, tMyParent);--, sName);

            --store this info for the next iteration
            tParentInfo.decoy   = oParent;
            tParentInfo.actual  = tParent;
        end

        local tInstance = instance.build(oInstance, tData, tKit, bHasParent and tParents[#tParents].actual or nil); --this is the returned instance

        --get the visibility of the construtor
        --local sConstructorVisibility = tKit.constructorVisibility;

        --make sure this class has a public constructor
        if not (tKit.constructorVisibility == "pub") then
            local sVisibility = tKit.constructorVisibility;
            --[[this auth code existence check permits
                non-public constructors to run within
                the static constructor (as they should
                be able to do)]]
            if (_tAuthenticationCodes[tKit]) then

                if (bIsNormalCall) then --don't run during deserialization, only during normal call
                    tInstance[sVisibility][sName](...);
                    tInstance.constructorcalled = true;
                end

                rawset(tInstance[sVisibility], sName, nil);
            else
                error("Error instantiating class, '${class}'. Contructor is ${visibility}." % {class = sName, visibility = _tCAINames[sVisibility]}, 3);
            end

        else

            if (bIsNormalCall) then --don't run during deserialization, only during normal call
                tInstance.pub[sName](...);
                tInstance.constructorcalled = true;
            end

            rawset(tInstance.pub, sName, nil);
        end

        --validate (constructor calls and delete constructors
        local nParents = #tParents;

        for x = nParents, 1, -1 do
            local tParentInfo   = tParents[x];
            local tParentKit    = tParentInfo.kit;
            local sParent       = tParentKit.name;
            local sClass        = x == nParents and tKit.name or tParents[x + 1].kit.name;

            if (bIsNormalCall and not tParentInfo.actual.constructorcalled) then
                error("Error in class, '${class}'. Failed to call parent constructor for class, '${parent}'." % {class = sClass, parent = sParent}, 2);--TODO should i set a third argument for the errors?
            end

            --rawset(tParentInfo.actual.met, "__type", tKit.name);
            --rawset(tParentInfo.actual[tParentKit.constructorVisibility], sParent, nil);--TODO should this deletion be moved to right after it gets called?
        end

        return oInstance;--, (bReturnInstanceTable and tInstance or nil);
    end

    --create and set (or overwrite) the static public deserialize function
    local function fDeserialize(tData)
        rawsetmetatable(tData, {__deserialmarker = "serializeddata"});
        local oInstance = buildInstance(tData);
        return oInstance;
    end
    rawset(tClass, "deserialize", fDeserialize);

    --build the class metatable
    local tClassMeta = { --the decoy's (returned class object's) meta table
        __call      = buildInstance,--function(t, ...) --instantiate the class --end,
        __eq = function(left, right)--TODO COMPLETE
            local bRet          = false;
            local tClassRepo    = class.repo.byObject;

            if (left and right) then
                local cLeft     = tClassRepo[left];
                local cRight    = tClassRepo[right];
                bRet = cLeft and cRight and cLeft.name == cRight.name;
            end

            return bRet;
        end,
        __index     = function(t, k)

            if (rawtype(tClass[k]) == "nil") then
                error("Error in class object, '${class}'. Attempt to access non-existent public static member, '${index}'." % {class = sName, index = tostring(k)}, 2);
            end

            return tClass[k];
        end,
        __lt = function(less, greater) --TODO complete this to check for instances too
            local bRet = false;

            if (type(less) ~= "class" or type(greater) ~= "class") then
                error("Error: attempt to compare non-class type.");--TODO complete this
            end

            local tLessKit      = kit.repo.byObject[less];
            local tGreaterKit   = kit.repo.byObject[greater];

            local tLesserParentKit = tLessKit.parent;

            while (tLesserParentKit) do

                if (tLesserParentKit == tGreaterKit) then
                    bRet = true;
                    break;
                end

                tLesserParentKit = tLesserParentKit.parent;
            end

            return bRet;
        end,
        __name = sName,
        __newindex  = function(t, k, v)
            local sType = rawtype(tClass[k]);

            if (sType ~= "nil") then

                if (isMutableStaticPublicType(sType)) then
                    local tROField = tKit.readOnlyFields.stapub[k];
                    local bROFieldIsFixed = tROField and tROField.fixed or false;

                    if (bROFieldIsFixed) then
                        error("Error in class object, '${class}'. Attempt to modify read-only static public field, '${index}'." % {class = sName, index = tostring(k)});
                    end

                    if (sType == type(v)) then
                        tClass[k] = v;
                    elseif (tROField and not bROFieldIsFixed) then
                        tClass[k] = v;
                        tROField.fixed = true;
                    else
                        error("Error in class object, '${class}'. Attempt to change static public value type for '${index}', from ${typecurrent} to ${typenew} using value, '${value}'." % {class = sName, index = tostring(k), typecurrent = sType, typenew = type(v), value = tostring(v)});
                    end

                else
                    error("Error in class object, '${class}'. Attempt to modify immutable static public member, '${index},' using value, '${value}'." % {class = sName, index = tostring(k), value = tostring(v)});
                end

            else
                error("Error in class object, '${class}'. Attempt to modify non-existent static public member, '${index},' using value, '${value}'." % {class = sName, index = tostring(k), value = tostring(v)});
            end

        end,
        __serialize = function()
            return sName;
        end,
        __tostring = function()
            return sName;
        end,
        __type = "class",
    };

    rawsetmetatable(oClass, tClassMeta);

    --update the repos
    class.repo.byKit[tKit]          = oClass;
    class.repo.byName[tKit.name]    = oClass;
    class.repo.byObject[oClass]     = tKit;

    local function classis(vVal)
        local sType         = type(vVal)
        local sTargetType   = tKit.name;
        local bIs           = sType == sTargetType;
        local tRepo         = instance.repo.byObject[vVal] or nil;

        if (not(bIs) and tRepo) then
            local tActiveKit = tRepo.kit or nil;

            if ((not bIs) and tActiveKit) then
                local tParent = tActiveKit.parent or nil;

                while ((not bIs) and tParent) do
                    bIs     = tParent.name == sTargetType;
                    tParent = tParent.parent or nil;
                end

            end
        end

        return bIs;
    end
    --create the 'is' function (e.g., isCreature(vVal))
    rawset(type, "is" .. tKit.name, classis);

    --store the is function for later use in relational functions
    class.repo.isFunctions[oClass] = classis;

    --create the class static constructor launcer that will be executed by kit.build (if a static constructor exists)
    local fLauncher;

    if (rawtype(tClass[sName]) == "function") then

        fLauncher = function()
            --create and store the static constructor authentication code
            local sAuthCode = string.uuid();
            _tAuthenticationCodes[tKit] = sAuthCode;
            --run the static contructor
            tClass[sName](oClass, sAuthCode);
            --destroy the static constructor
            rawset(tClass, sName, nil);
            --destroy the static constructor authentication code
            _tAuthenticationCodes[tKit] = nil;
        end

    end

    return oClass, fLauncher;
end


                --[[██╗███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗ ██████╗███████╗
                    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║██╔════╝██╔════╝
                    ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║██║     █████╗
                    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║██║     ██╔══╝
                    ██║██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║╚██████╗███████╗
                    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝]]
                    --[[!
                        @fqxn LuaEx.Class System.instance
                        @desc The table containing all functions and data relating to and dealing with instantiation.
                    !]]

--[[!
@fqxn LuaEx.Class System.instance.Functions.build
@param table tKit The kit from which the instance is to be built.
@param table tData The data used for deserializing or nil if this is a normal instantiation call.
@param table tParentActual The (actual) parent instance table (if any).
@scope local
@desc Builds an instance of an object given the name of the kit.
@ret object|table oInstance|tInstance The instance object (decoy) and the instance table (actual).
!]]
function instance.build(oInstance, tData, tKit, tParentActual, sType)
    --local oInstance     = {};                       --this is the decoy instance object that gets returned
    local tInstance     = {                         --this is the actual, hidden instance table referenced by the returned decoy, instance object
        met = clone(tKit.met), --create the metamethods
        pri = clone(tKit.pri), --create the private members
        pro = clone(tKit.pro), --etc.
        pub = clone(tKit.pub), --TODO should I use clone item or will this do for cloning custom class types? Shoudl I also force a clone method for this in classes? I could also have attributes in classes that could ask if cloneable...
        --children            = {},    --TODO move to class level or to here? Is there any use for it here? IS THIS EVER USED AT ALL? Perhaps for class-level funtions?
        constructorcalled   = false, --helps enforce constructor calls
        decoy               = oInstance,            --for internal reference if I need to reach the decoy of a given actual
        isAChecks           = clone(tKit.isAChecks),
        metadata            = {                     --info about the instance
            kit = tKit,
        },
        parent              = tParentActual,         --the actual parent (if one exists)
        readOnlyFields      = clone(tKit.readOnlyFields),
    };

    --import deserialize data (if any exists)
    if (tData) then
        local sKitName = tInstance.metadata.kit.name;
        local tMyData = tData[sKitName];

        if not (tMyVisData) then
            error("Error deserializing data for instance object in class, '${name}'. Data is malformed." % {name = sKitName}, 2);
        end

        for _, sVisibility in pairs(_tSerializerIndices) do
            local tVisibility   = tData[sKitName];
            local tMyVisData    = tMyData[sVisibility];

            if not (tMyVisData) then
                error("Error deserializing data for instance object in class, '${name}' in ${table} table. Data is malformed." % {name = sKitName, table = sVisibility}, 2);
            end

            for sField, vField in pairs(tMyVisData) do
                tInstance[sVisibility][sField] = vField;
            end

        end

    end

    --create and set the serialize method for the instance
    local fSerialize = instance.buildSerializer(tInstance);
    rawset(tInstance.met, "__serialize", fSerialize);

    --get the class data (decoy) table
    local tClassData = instance.prepClassData(tInstance);

    --set the metatable for class data so there are no undue alterations or any erroneous access
    instance.setClassDataMetatable(tInstance, tClassData);

    --wrap the metamethods
    instance.wrapMetamethods(tInstance, tClassData)

    --wrap the private, protected and public methods
    instance.wrapMethods(tInstance, tClassData)

    --process the class directives
    instance.processDirectives(tInstance, tClassData);

    --create and set the instance metatable
    instance.setMetatable(tInstance, tClassData);--, sType);

    --TODO I need to update the children field of each parent (OR do I?)
    --TODO add serialize missing warrning (or just automatically create the method if it's missing) (or just have base object with methods lie serialize, clone, etc.)
    --TODO move to kit.buildclass tKit.instances[oInstance] = tInstance; --store the instance reference (but not its recursively-created, parent instances)

    --store the class data so it can be used interally by classes to access other object cdat.
    rawset(tKit.ins, oInstance, tClassData);

    --store it in the instance repo too
    --instance.repo.byClass[]
    --instance.repo.byKit[]
    --instance.repo.byName[]
    instance.repo.byObject[oInstance] = {
        actual  = tInstance,
        kit     = tKit,
        class   = class.repo.byKit[tKit],
    };

    return tInstance;
end

--TODO add optional hash value for data integrity checks
--TODO handle self-refences
--[[!
@fqxn LuaEx.Class System.instance.Functions.buildSerializer
@param table tInstance The (actual) instance table.
@scope local
@desc Creates and prepares the serialization function for the instance.
<br>Serializtion includes all serializable fields from pri, pro, and pub.
@ret function fSerializer The serializer function.
!]]
function instance.buildSerializer(tInstance)
    --local sHash = "";
    local tCDats    = {};
    local tParent = tInstance.parent;

    while tParent do
        tCDats[tParent.metadata.kit.name] = {
            pri     = tParent.pri,
            pro     = tParent.pro,
            pub     = tParent.pub,
            kit     = tParent.metadata.kit;
        };

        tParent = tParent.parent;
    end

    tCDats[tInstance.metadata.kit.name] = {
        pri     = tInstance.pri,
        pro     = tInstance.pro,
        pub     = tInstance.pub,
        kit     = tInstance.metadata.kit;
    };

    return function()
        local tRet = {};

        for sKitName, tCDat in pairs(tCDats) do
            --local nIndex = #tRet + 1;
            tRet[sKitName] = {};
            local tMyKit = tCDat.kit;

            for __, sVisibility in pairs(_tSerializerIndices) do
                tRet[sKitName][sVisibility] = {};

                for sField, vField in pairs(tCDat[sVisibility]) do

                    if (rawtype(vField) == "function") then
                        local bIsInKit  = rawtype(tMyKit[sVisibility][sField]) == "function";

                        if not (bIsInKit) then --serialize ONLY functions that are not baked into the kit
                            tRet[sKitName][sVisibility][sField] = vField;
                        end

                    else
                        tRet[sKitName][sVisibility][sField] = vField; --QUESTION clone value?
                    end

                end

            end

        end

        return serialize(tRet);
    end

end


--[[!
@fqxn LuaEx.Class System.instance.Functions.prepClassData
@param table tInstance The (actual) instance table.
@scope local
@desc Creates and prepares the decoy and actual class data tables for use by the instance input.
@ret table tClassData The decoy class data table.
!]]
function instance.prepClassData(tInstance)
    local tKit = tInstance.metadata.kit;
    local tClassData        = {};   --decoy class data (this gets pushed through the wrapped methods)
    local tClassDataActual  = {     --actual class data
        pri = {},
        pro = {},
        pub = {},
        ins = tKit.ins,
        --parent    = null,
    };

    rawsetmetatable(tClassData, {
        __index = function(t, k, v)--throw an error if the client access a non-existent Class Data index.
            local vRet = rawget(tClassDataActual, k);

            if (rawtype(vRet) == "nil") then
                local sIndices = "";
                for vIndex, _ in pairs(tClassDataActual) do
                    sIndices = sIndices .. "'"..tostring(vIndex).."', ";
                end
                sIndices = sIndices:sub(1, #sIndices - 2);
                error("Error in class, '${class}'. Attempt to access non-existent class data index, '${index}'.\nValid indices are ${indices}." % {class = tKit.name, index = tostring(k), indices = sIndices}, 3);
            end

            return vRet;

        end,
        __newindex = function(t, k, v) --disallows modifications to or deletetions from the tClassData table. TODO make the messsage depending on if event is a change, addition or deletion (for more clarity)
                error("Error in class, '${class}'. Attempt to modify read-only class data." % {class = tKit.name});
        end,
        --__metatable = true,
        __type = "classdata",
    });

    return tClassData;
end


--[[
directive table reference (as set in kit.processDirectives())
keyRaw          = sKeyRaw,
isFinal         = bIsFinal,
isReadOnly      = bIsReadOnly,
getter          = vGetter,
getterIsFinal   = bGetterFinal,
setter          = vSetter,
setterIsFinal   = bSetterFinal,
]]
function instance.processDirectives(tInstance, tClassData)
    local tKit      = tInstance.metadata.kit;
    local oInstance = tInstance.decoy;

    for sCAI, tKeys in pairs(tKit.directives) do

        for sKey, tDirective in pairs(tKeys) do
            --local tKitCAI = tKit[sCAI];
            --local sKeyRaw = tDirective.keyRaw;

            --set the new key name/value and delete the old key
            --tKitCAI[sKey]       = tKitCAI[sKeyRaw];
        --    tKitCAI[sKeyRaw]    = nil;

            --create and getters/setters
            if (tDirective.getter) then

                --overwrite the placeholder
                tInstance.pub[tDirective.getter] = function()
                    return tInstance[sCAI][sKey];
                end

            end

            if (tDirective.setter) then

                --overwrite the placeholder
                tInstance.pub[tDirective.setter] = function(vVal)
                    tClassData[sCAI][sKey] = vVal;
                    return oInstance;
                end

            end

            --TODO finals


            --set other directive items
            --TODO LEFT OFF HERE
        end

    end

end


--[[!
@fqxn LuaEx.Class System.instance.Functions.setClassDataMetatable
@param table tInstance The (actual) instance table.
@param table tClassData The (decoy) class data table.
@scope local
@desc Creates and sets the instance's class data metatable, helping prevent incidental, erroneous acces and alteration of the class data.
!]]
function instance.setClassDataMetatable(tInstance, tClassData)
    local tClassDataIndices = {pri, pro, pub};
    local sName             = tInstance.metadata.kit.name;

    for _, sCAI in pairs(tClassDataIndices) do
        local bIsPrivate        = sCAI == pri;
        local bIsProteced       = sCAI == pro;
        local bIsPublic         = sCAI == pub;
        local bAllowUpSearch    = bIsProteced or bIsPublic;

        rawsetmetatable(tClassData[sCAI], {
            __index = function(t, k)
                local vRet          = tInstance[sCAI][k];
                local zRet          = rawtype(vRet);
                local tNextParent   = tInstance.parent or nil;

                --if there's no such public key in the instance, check each parent
                while (bAllowUpSearch and zRet == "nil" and tNextParent) do
                    vRet        = tNextParent[sCAI][k];
                    local parenttext = "self";
                    if (tNextParent                    and
                        tNextParent.metadata           and
                        tNextParent.metadata.kit       and
                        tNextParent.metadata.kit.name) then

                        parenttext = tNextParent.metadata.kit.name;
                    end

                    zRet        = rawtype(vRet);
                    tNextParent = tNextParent.parent or nil;
                end

                --if none exists, throw an error
                if (zRet == "nil") then
                    error("Error in class, '${name}'. Attempt to access ${visibility} member, '${member}', a nil value." % {
                        name = sName, visibility = _tCAINames[sCAI], member = tostring(k)}, 3);
                end

                return vRet;
            end,
            __newindex = function(t, k, v)
                local tTarget       = tInstance[sCAI];
                local vVal          = rawget(tTarget, k);
                local zVal          = rawtype(vVal);
                local tNextParent   = tInstance.parent or nil;

                --if there's no such public key in the instance, check each parent
                while (bAllowUpSearch and zVal == "nil" and tNextParent) do
                    tTarget     = tNextParent[sCAI];
                    vVal        = rawget(tTarget, k);
                    zVal        = rawtype(vVal);

                    tNextParent = tNextParent.parent;
                end

                --TODO DIRECTIVE TEST FINISH LEFT OFF HERE
               --ensure this isn't a read-only field
                local tROField      = tInstance.readOnlyFields[sCAI] and
                                      tInstance.readOnlyFields[sCAI][k];
                local bSetROFixed   = tROField and not tROField.fixed;

                if (tROField) then

                    if (tROField.fixed) then
                        error("Error in class, '${name}'. Attempt to modify ${visibility} member, '${member}', a read-only value." % {
                        name = sName, visibility = _tCAINames[sCAI], member = tostring(k)}, 3);
                    end

                end

                --if none exists, throw an error
                --if (rawtype(vVal) == "nil") then
                if (zVal == "nil") then
                    error("Error in class, '${name}'. Attempt to modify ${visibility} member, '${member}', a nil value." % {
                        name = sName, visibility = _tCAINames[sCAI], member = tostring(k)}, 3);
                end

                local sTypeCurrent  = type(tTarget[k]);
                local sTypeNew      = type(v);

                if (sTypeNew == "nil") then
                    error("Error in class, '${name}'. Cannot set ${visibility} member, '${member}', to nil." % {
                        name = sName, visibility = _tCAINames[sCAI], member = tostring(k)}, 3);
                end

                if (sCAI ~= "pri" and sTypeCurrent == "function") then --TODO look into this and how, if at all, it would/should work work protected methods
                    error("Error in class, '${name}'. Attempt to override ${visibility} class method, '${member}', outside of a subclass context." % {
                        name = sName, visibility = _tCAINames[sCAI], member = tostring(k)}, 3);
                end

                --update the isAChecks (if needed) if the initial value was null
                if (not tInstance.isAChecks[sCAI][k] and isinstance(v)) then
                    tInstance.isAChecks[sCAI][k] = {
                        class   = of(v),
                        type    = sTypeNew,
                        value   = v,
                    };
                end

                if (sTypeCurrent ~= "null" and sTypeCurrent ~= sTypeNew) then--TODO allow for null values (and keep track of previous type)
                    local bAllow = false;
                    --TODO QUESTION Should I allow interfaces too? Check POLA on C#
                    --allow type->type setting as well as polymorphism, otherwise throw an error
                    if (tInstance.isAChecks[sCAI][k]) then
                        local sNewClass = of(v);

                        if (sNewClass) then
                            local sOriginalClass = tInstance.isAChecks[sCAI][k].class;

                            --allow if the class type is the same as the original
                            bAllow = kit.repo.byObject[sOriginalClass].name ==
                                     kit.repo.byObject[sNewClass].name      or
                                     ischild(sNewClass, sOriginalClass);

                            --if not (bAllow) then--check for a derived class and allow if so
                                --bAllow = ischild(sNewClass, sOriginalClass);
                            --end

                        end

                    end

                    if not (bAllow) then
                        error("Error in class, '${name}'. Attempt to change type for ${visibility} member, '${member}', from ${typecurrent} to ${typenew}." % {
                            name = sName, visibility = _tCAINames[sCAI], visibility = _tCAINames[sCAI], member = tostring(k), typecurrent = sTypeCurrent, typenew = sTypeNew}, 3);
                    end

                end

                --mark the read-only field as now being fixed
                if (bSetROFixed) then
                    tROField.fixed = true;
                end

                rawset(tTarget, k, v);
            end,
            --__metatable = true,--TODO WARNING is it better to have this type available (and for what) or have the metatable protcted (same with the parent table)?
            __type = _tCAINames[sCAI].."classdata",
        });

    end

end


--[[!
@fqxn LuaEx.Class System.instance.Functions.setMetatable
@param table tInstance The (actual) instance table.
@param table tClassData The (decoy) class data table.
@scope local
@desc Creates and sets the instance's metatable.
!]]
function instance.setMetatable(tInstance, tClassData)--, sType)
    local tMeta     = {}; --actual
    local tKit      = tInstance.metadata.kit;
    local oInstance = tInstance.decoy;

    --iterate over all metanames
    for sMetamethod, bAllowed in pairs(_tMetaNames) do

        if (bAllowed) then --only add if it's allowed
            local fMetamethod = tInstance.met[sMetamethod] or nil; --check if the metamethod exists in this class

            if (fMetamethod) then
                tMeta[sMetamethod] = fMetamethod;

            else --if it does not exist, try to add one from a parent instance
                local tNextParent = tInstance.parent;

                while (tNextParent) do
                    local fParentMetamethod = tNextParent.met[sMetamethod] or nil; --check if the metamethod exists in this class

                    if (fParentMetamethod) then
                        tMeta[sMetamethod] = fParentMetamethod;
                        tNextParent = nil; --indicate that we're done searching
                    else
                        tNextParent = tNextParent.parent or nil; --continue the search
                    end

                end

            end

        end

    end

    --[[leave these for last to ensure overwright if they exist
        (if they weren't filtered out already)]]
    tMeta.__index     = function(t, k)
        return tClassData.pub[k] or nil;
    end;

    tMeta.__newindex  = function(t, k, v)
        tClassData.pub[k] = v;
    end;

    tMeta.__type = tKit.name;--(sType ~= nil) and sType or tKit.name;

    tMeta.__is_luaex_class = true;

    rawsetmetatable(oInstance, tMeta);
end


--[[!
@fqxn LuaEx.Class System.instance.Functions.wrapMetamethods
@param table tInstance The (actual) instance table.
@param table tClassData The (decoy) class data table.
@desc Wraps all the instance metamethods so they have access to the instance object (decoy) and the class data.
!]]
function instance.wrapMetamethods(tInstance, tClassData)--TODO double check these
    local oInstance = tInstance.decoy;

    for sMetamethod, fMetamethod in pairs(tInstance.met) do

        if (sMetamethod == "__add"      or sMetamethod == "__band"      or sMetamethod == "__bor"   or
            sMetamethod == "__bxor"     or sMetamethod == "__concat"    or sMetamethod == "__div"   or
            sMetamethod == "__eq"       or sMetamethod == "__idiv"      or sMetamethod == "__le"    or
            sMetamethod == "__lt"       or sMetamethod == "__mod"       or sMetamethod == "__mul"   or
            sMetamethod == "__pow"      or sMetamethod == "__shl"       or sMetamethod == "__shr"   or
            sMetamethod == "__sub")  then

            rawset(tInstance.met, sMetamethod, function(a, b)
                return fMetamethod(a, b, tClassData);
            end);

        elseif (   sMetamethod == "__bnot"  or sMetamethod == "__len"
                or sMetamethod == "__unm"   or sMetamethod == "__tostring") then--TODO can these be moved...[XSE]

            rawset(tInstance.met, sMetamethod, function(a)
                return fMetamethod(a, tClassData);
            end);

        elseif (   sMetamethod == "__call"      or sMetamethod == "__name"--TODO [XSE]..to here
                --or sMetamethod == "__serialize" or sMetamethod == "__clone"
                or sMetamethod == "__clone"
                or sMetamethod == "__ipairs"    or sMetamethod == "__pairs") then

            rawset(tInstance.met, sMetamethod, function(...)
                return fMetamethod(oInstance, tClassData, ...)
            end);

        --elseif (sMetamethod == "__tostring") then

        --    rawset(tInstance.met, sMetamethod, function(a)
        --        return fMetamethod(a, tClassData)
        --    end);

        end

    end

end


--[[!
@fqxn LuaEx.Class System.instance.Functions.wrapMethods
@param table tInstance The (actual) instance table.
@param table tClassData The (decoy) class data table.
@scope local
@desc Wraps all the instance methods so they have access to the instance object (decoy) and the class data.
!]]
function instance.wrapMethods(tInstance, tClassData)
    local tKit              = tInstance.metadata.kit;
    local oInstance         = tInstance.decoy;
    local tClassDataIndices = {pri, pro, pub};

    for _, sCAI in ipairs(tClassDataIndices) do

        --wrap the classdata functions
        for k, fWrapped in pairs(tInstance[sCAI]) do

            if (rawtype(fWrapped) == "function") then

                if (k == tKit.name) then --wrap constructors
                    local tParent = tInstance.parent;

                    if (tParent) then
                        rawset(tInstance[sCAI], k, function(...)
                            local tParentKit                    = tParent.metadata.kit;
                            local sParentName                   = tParentKit.name;
                            local sParentConstructorVisibility  = tParentKit.constructorVisibility;

                            --delete the parent constructor to prevent multiple calls (TODO NEW LINE HERE; MOVED FORM CLASS.BUILD. TEST TO ENSURE IT'S WORKING)
                            local fParentConstructor = function(...)

                                if not (tParent[sParentConstructorVisibility][sParentName]) then
                                        error("Error in class, '${class}'.\nAttempt to call parent constructor for class, '${parent}', more than once." % {class = tKit.name, parent = sParentName}, 3);
                                end

                                tParent[sParentConstructorVisibility][sParentName](...);
                                tParent[sParentConstructorVisibility][sParentName] = nil;
                            end

                            fWrapped(oInstance,
                                     tClassData,
                                     fParentConstructor,
                                     ...);

                            tInstance.constructorcalled = true;
                        end);

                    else
                        rawset(tInstance[sCAI], k, function(...)
                            fWrapped(oInstance, tClassData, ...);

                            tInstance.constructorcalled = true;
                        end);

                    end

                else --wrap non-constructors
                    rawset(tInstance[sCAI], k, function(...)
                        return fWrapped(oInstance, tClassData, ...);
                    end);
                end

            end

        end

    end

end


                                        --[[██╗  ██╗██╗████████╗
                                            ██║ ██╔╝██║╚══██╔══╝
                                            █████╔╝ ██║   ██║
                                            ██╔═██╗ ██║   ██║
                                            ██║  ██╗██║   ██║
                                            ╚═╝  ╚═╝╚═╝   ╚═╝ ]]
                                        --[[!
                                            @fqxn LuaEx.Class System.kit
                                            @desc The table containing all the functions and data relating to and dealing with class kits.
                                            <br>
                                            <h1>Kits</h1>
                                            Kits are used in the class building process. When a class is created by the user, the parameters of that class are stored in a kit. The class is then constructed from the kit and any parent kits.
                                            <br>This approach facilitates inheritance while mitigating any issues with shared tables that shouldn't be shared. It also permits classes to retain private methods and still properly function within scope when that class is extended.
                                            <br>Essentially, kits solve the problems that arise from inheritance in Lua. Kits are the building blocks of all classes and are where all class data is stored.
                                            <br>
                                            <strong>Note</strong>: the class data stored in kits is strictly managed and controlled to prevent incidental access and modification out of scope.

                                            <h1>Kit Usage</h1>
                                            Kits are first created by a call to <a href="#LuaEx.Class System.kit.Functions.build">kit.build</a>. The globally-available alias to this function is <strong>class</strong>.

                                            Once a call to class has been made, the class building process begins.
                                            Below is the order in which events occur.

                                            <ol>
                                                <li>The class name is validated by <a href="#LuaEx.Class System.kit.Functions.validateName">kit.validateName</a> to ensure it's variable-safe and doesn't already exist.</li>
                                                <li>The <a href="#LuaEx.Class System.kit.Functions.validateTables">kit.validateTables</a> check the validity of the tables containing the metamethods as well as the static public, private, protected, and public class members.</li>
                                                <li><a href="#LuaEx.Class System.kit.Functions.validateInterfaces">kit.validateInterfaces</a></li>
                                                <li><a href="#LuaEx.Class System.kit.Functions.validateName"></a></li>
                                                <li><a href="#LuaEx.Class System.kit.Functions.validateName"></a></li>
                                                <li><a href="#LuaEx.Class System.kit.Functions.validateName"></a></li>
                                                <li><a href="#LuaEx.Class System.kit.Functions.validateName"></a></li>

                                                (sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic);
                                                kit.validateInterfaces(sName, tInterfaces);
                                            </ol>
                                        !]]

--[[!
@fqxn LuaEx.Class System.kit.Functions.build
@param string sName The name of the class kit. This must be a unique, variable-compliant name.
@param table tMetamethods A table containing all class metamethods.
@param table tStaticPublic A table containing all static public class members.
@param table tPrivate A table containing all private class members.
@param table tProtected A table containing all protected class members.
@param table tPublic A table containing all public class members.
@param class|nil cExtendor The parent class from which this class ischild (if any). If there is no parent class, this argument should be nil.
@param boolean|table|nil vLimitationsOrFinal A boolean value indicating whether this class is final, nil indicating false, or a numerically-indexed table of strings whose values are class names to which subclasses should be limited.
@param interface|nil The interface(s) this class implements (or nil, if none). This is a cararg table, so many or none may be entered.
@scope local
@desc Imports a kit for later use in building class objects.
@ret class Class Returns the class returned from the kit.build() tail call.
!]]
function kit.build(_IGNORE_, sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vFinality, ...)
    local tInterfaces = {...} or arg;
    --validate the input TODO remove any existing metatable from input tables or throw error if can't

    kit.validateName(sName);
    kit.validateTables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic);
    kit.validateInterfaces(sName, tInterfaces);

    --TODO check each member against the static members?
    --import/create the elements which will comprise the class kit
    local tKit = {
        base = nil,
        --properties
        --auto            = {},       --these are the auto getter/setter methods to build on instantiation
        directives      = {
            met     = {},
            stapub  = {},
            pri     = {},
            pro     = {},
            pub     = {},
        },
        children		= {
            all     = {
                byName 		= {},   --updated on build
                byObject 	= {},   --updated when a class object is created (during build)
            },
            count = 0,              --applies to direct children
            direct  = {
                byName 		= {},   --updated on build
                byObject 	= {},   --updated when a class object is created (during build)
            },
        },
        constructorVisibility = "", --gets set in kit.processConstructor
        finalMethodNames= {         --this keeps track of methods marked as final to prevent overriding
            met = {},
            pro = {},
            pub = {},
        },
        hasParent = false,
        --initializerCalled = false, --tracks whether the static inializer for this class kit has been called QUESTION do i need this since it executes only once anyway?
        ins		        = rawsetmetatable({},
            {
                __newindex = function(t, k, v)
                    error("Error in class, '${class}'. Attempt to modify read-only class data." % {class = sName}, 2);
                end
            }
        ),
        interfaces      = {},
        isAChecks = { --used for respecting polymorphism during assignment    TODO FIX DO I NEED MORE subtables? What about the other items? Perhaps stapub but not met
            pri = {},
            pro = {},
            pub = {},
        },
        isFinal			= false, --whether the classis final (processed below)
        isInScope       = load("return "..sName..' ~= nil;'), --this gets run when checking if the final class object is visible within a given scope.
        --hasBlacklist    = false, --whether the class has a blacklist (processed below)
        --hasWhitelist    = false, --whether the class has a whitelist (processed below)
        blacklist       = nil,   --which class(es) may NOT subclass this one (processed below)
        whitelist       = nil,   --which class(es) may subclass this one (processed below)
        name 			= sName,
        parent			= nil, --set in kit.mayExtend() (if it does)
        --tables
        met 	        = clone(tMetamethods, 	true),
        stapub 	        = clone(tStaticPublic, 	true),
        pri			    = clone(tPrivate, 		true),
        pro 		    = clone(tProtected, 	true),
        pub      	    = clone(tPublic, 		true),
        readOnlyFields  = {
            stapub  = {},
            pri     = {},
            pro     = {},
            pub     = {},
        },
    };

    --execute then delete the static constructor (if it exists)
    --local sStaticFieldMaker = "__"..sName;
    --if (rawtype(tClass[sStaticFieldMaker]) == "function") then
--        tClass[sStaticFieldMaker](tClass);
        --rawset(tClass, sStaticFieldMaker, nil);
    --end

    --determine whether the class is final or limited (and, if so, set limitations)
    kit.processFinality(tKit, vFinality);

    --validate the constructor and record its visibility
    kit.processConstructor(tKit);

    --if this class is attempting to extend a class, validate it can
    kit.setParent(tKit, cExtendor);

    --process the class directives
    kit.processDirectives(tKit);

    --check for member shadowing
    kit.shadowCheck(tKit);

    --log original values for later assignment checks in the instances
    kit.processInitialIsAChecks(tKit);

    --enforce (any) implemented interfaces
    kit.processInterfaces(tKit, tInterfaces);

    --now that this class kit has been validated, imported & stored, build the class object
    local oClass, fLauncher = class.build(tKit);

    --increment the class kit count
    kit.count = kit.count + 1;

    --store the class kit and class object in the kit repo
    kit.repo.byName[sName]      = tKit;
    kit.repo.byObject[oClass]   = tKit;

    --if this has a parent, update the parent kit's child table and set this kit's base
    local tParent = tKit.parent;

    if (tParent) then
        --inducate the kit has a parent
        tKit.hasParent = true;

        --update the kit's base
        tKit.base = tParent.base or tParent;

        local tAll      = tParent.children.all;
        local tDirect   = tParent.children.direct;

        tAll.byName[sName]          = tKit;
        tAll.byObject[oClass]       = tKit;

        tDirect.byName[sName]       = tKit;
        tDirect.byObject[oClass]    = tKit;

        --update the child count
        tParent.children.count = tParent.children.count + 1;

        --print("Updating child "..sName.." for parent "..tParent.name)
        tParent                     = tParent.parent;

        while (tParent) do
            tAll                    = tParent.children.all;
            tAll.byName[sName]      = tKit;
            tAll.byObject[oClass]   = tKit;
            --print("Updating child "..sName.." for parent "..tParent.name)

            tParent                 = tParent.parent;
        end

    end

    --execute then delete the class's static constructor (if it exists)
    if (fLauncher) then
        fLauncher();
        --delete the launcher too
        fLauncher = nil;
    end

    return oClass;--return the class object;
end


--[[!
@fqxn LuaEx.Class System.kit.Functions.getDirectiveInfo
@param string sCAI The visibility name.
@param string sKey The key as it was written in the class.
@param any vItem The item associated with the class member key.
@scope local
@desc Gets info about any directives set for this class member.
@ret string sKey The key as rewritted without the directive tags.
@ret boolean bIsFinal Whether the method has been set to final (applies to methods only).
@ret boolean bIsReadOnly Whether the value is a read only (applies to fields only).
@ret string|nil sGetter The name of the getter method or nil if no getter method should be created.
@ret string|nil sSetter The name of the setter method or nil if no setter method should be created.
@ret boolean bGetterFinal Whether the setter method (if present) is final.
@ret boolean bSetterFinal Whether the setter method (if present) is final.
!]]
function kit.getDirectiveInfo(tKit, sCAI, sKey, vItem)--TODO FINISH pretty errors
    --TODO move these string into vars above
    local sGetter, sSetter;
    local bUpperCase = false;
    local bGetter, bSetter, bGetterFinal, bSetterFinal = false, false, false, false;
    local bHasDirective     = false;
    local bHasAutoDirective = false;

    local bFinal = sKey:find(_sDirectiveFNL) ~= nil;
    if (bFinal) then
        bHasDirective = true;
        sKey = sKey:gsub(_sDirectiveFNL, "");
    end

    local bReadOnly = sKey:find(_sDirectiveRO) ~= nil;
    if (bReadOnly) then
        bHasDirective = true;
        sKey = sKey:gsub(_sDirectiveRO, "");
    end

    local nBaseStart    = 0;
    local nBaseEnd      = -1;
    local sGetPrefix    = "";

    -- Look for __AUTO or __auto
    local nStart, nEnd = sKey:find(_sDirectiveAutoUpper);

    if not nStart then
        nStart, nEnd = sKey:find(_sDirectiveAutoLower);

        if nStart then
            bUpperCase = false;
        end

    else
        bUpperCase = true;
    end

    -- Default values if no directive is found
    if nStart then

        --ensure there's text before the directive
        if (nStart == 1) then
            error("Cannot create directive without field name.", 5);
        end

        local sRemainder = sKey:sub(nStart);

        -- Validate length of directive
        if (#sRemainder < 8) then --TODO move this 8 local const
            error("Malformed __AUTO__ directive in class '"..tKit.name.."' and Key '"..sKey.."'.", 5);
        end

        --make sure there's not a RO directive appended
        if (bHasAutoDirective) then
            error("The read only (__RO) directive cannot be explicitly applied with properties.\nUse the proper AUTO property token to make property value read only.", 5);
        end

        bHasDirective       = true;
        bHasAutoDirective   = true;

        local nCharIndex        = nStart + 6;--TODO move this 6 local const
        local sAutoToken        = sKey:sub(nCharIndex, nCharIndex);
              nCharIndex        = nStart + 7;--TODO move this 7 local const
        local sFinalToken       = sKey:sub(nCharIndex, nCharIndex);

        --determine the auto type
        local bTypeIsGetter         = sAutoToken == "A";
        local bTypeIsSetter         = sAutoToken == "M";
        local bTypeIsReadOnlyGetter = sAutoToken == "R";
        local bTypeIsBoth           = not (bTypeIsGetter or bTypeIsSetter or bTypeIsReadOnlyGetter)
        bReadOnly                   = bTypeIsReadOnlyGetter;

        bGetter         = bTypeIsGetter or bTypeIsBoth or bTypeIsReadOnlyGetter;
        bSetter         = bTypeIsSetter or bTypeIsBoth;
        bGetterFinal    = bGetter and (sFinalToken == "A" or sFinalToken == "F");
        bSetterFinal    = bSetter and (sFinalToken == "M" or sFinalToken == "F");


        if (bGetter) then
            local sPrefix = sKey:sub(nCharIndex + 1);
            sGetter = (#sPrefix > 0 and sPrefix or (bUpperCase and "Get" or "get"))..sKey:sub(1, nStart - 1);
        end

        --clean up the key
        sKey = sKey:sub(1, nStart - 1);

        if (bSetter) then
            sSetter = (bUpperCase and "Set" or "set")..sKey;
        end
        --print(sKey, sGetter, sSetter)


    end


    --Check for malformed/maldesigned directives

    -- Ensure that there is something before the auto directive
    if bHasDirective and (sKey == "" or not sKey:isvariablecompliant(true)) then
        error("There must be text before a directive declaration and the final result must be a variable-compliant string. Got '${key}'" % {key = sKey}, 5);
    end

    local sType         = type(vItem);--TODO can i get this as a parameter?
    local bIsNull       = sType == "null";
    local bIsFunction   = sType == "function";

    --if (bHasDirective and bIsNull) then --TODO DIRECTIVE TEST
        --error("Items using directives cannot be null.", 5);
    --end

    --check _RO application
    if (bReadOnly) then

        if (bIsFunction) then
            error("__RO directives can be applied only to fields and cannot be null.", 5);
        end

        if not (tKit.readOnlyFields[sCAI]) then
            error("__RO directive cannot be applied to fields in the ${visibility} table." % {visibility = _tCAINames[sCAI]}, 5);
        end

    end

    --check __FNL application
    if (bFinal) then

        if not (bIsFunction) then
            error("__FNL directive can be applied only to methods (and properties optionally and implciitly using the proper AUTO property token) and cannot be null.", 5);
        end

        if not (tKit.finalMethodNames[sCAI]) then
            error("__FNL directive cannot be applied to methods in the ${visibility} table." % {visibility = _tCAINames[sCAI]}, 5);
        end

        if (sCAI == "stapub") then
            error("Application of __FNL directive to public static methods is redundant.", 5);
        end

    end

    --if (bReadOnly and sSetter) then
    --    error("Cannot apply read only (__RO) directive to a field queued to become a mutator property.");
    --end

    --NOTE: since everything in the met table is guaranteed to be a function, we needn't validate further

    if (bHasAutoDirective) then

        if (bIsFunction) then
            error("__AUTO directives can be applied only to fields.", 5);
        end

        if (sCAI == "pub" or sCAI == "stapub") then
            error("__AUTO directives cannot be applied to ${visibility} fields." % {visibility = _tCAINames[sCAI]}, 5);
        end

    end


    if sKey == "X" or sKey == "Y" then
        --print(sKey, bFinal, bReadOnly, sGetter, sSetter, bGetterFinal, bSetterFinal)
    end
    -- Return the processed names and flags

    --if sKey == "X" or sKey == "Y" then
    --print(sKey, bFinal, bReadOnly, sGetter, sSetter, bGetterFinal, bSetterFinal) end
    return sKey, bFinal, bReadOnly, sGetter, sSetter, bGetterFinal, bSetterFinal;
end


--[[!
@fqxn LuaEx.Class System.kit.Functions.processConstructor
@param table tKit The kit upon which to operate.
@scope local
@desc Configures and validates the kit's constructor method.
!]]
function kit.processConstructor(tKit)
    local sName                    = tKit.name;
    local bConstructorFound        = false;
    local tConstructorVisibilities = {"pri", "pro", "pub"};

    --iterate over vibilities where the constructor may exist
    for _, sVisibility in ipairs(tConstructorVisibilities) do

        --iterate over all class members in the current vibility table
        for sMemberName, vMember in pairs(tKit[sVisibility]) do

            --check for a constructor
            if (sMemberName == sName) then

                --throw an error if a non-function member with the class name exists
                if (rawtype(vMember) ~= "function") then
                    error(  "Error creating class, '${class}'. Constructor must be of type function.\nType given: ${type} in ${table} table." % {class = sName, type = rawtype(vMember), table = sTable});
                end

                --make sure there's not already a constructor
                if (bConstructorFound) then
                    error(  "Error creating class, '${class}'. Constructor already exists in ${table} table." %
                            {class = sName, table = tKit.constructorVisibility});
                end

                --mark the constructor found and record it's location
                bConstructorFound = true;
                tKit.constructorVisibility = sVisibility;

                --continue looking for (potential) redundant constructors or class-named values
            end

        end

    end

    --make sure a constructor was found
    if not (bConstructorFound) then
        error( "Error creating class, '${class}'. No constructor provided." % {class = sName}, 3);
    end

end


--[[!
@fqxn LuaEx.Class System.kit.Functions.processDirectives
@param table tKit The kit upon which to operate.
@scope local
@desc Prepares all directives dictated by the class.
!]]
local _tDirectiveVisibilites        = {"met", "stapub", "pri", "pro", "pub"};
local _tReadOnlyFieldVisibilites    = {"pro", "pub"};
function kit.processDirectives(tKit)

    for _, sCAI in pairs(_tDirectiveVisibilites) do

        for sKeyRaw, vItem in pairs(tKit[sCAI]) do
            local   sKey, bIsFinal, bIsReadOnly,
                    vGetter, vSetter,
                    bGetterFinal, bSetterFinal =
                    kit.getDirectiveInfo(tKit, sCAI, sKeyRaw, vItem);

            if (bIsFinal or bIsReadOnly or vGetter or vSetter) then
                tKit.directives[sCAI][sKey] = {
                    keyRaw          = sKeyRaw,
                    isFinal         = bIsFinal,
                    isReadOnly      = bIsReadOnly,
                    getter          = vGetter,
                    getterIsFinal   = bGetterFinal,
                    setter          = vSetter,
                    setterIsFinal   = bSetterFinal,
                };
                --print(sKey, bIsFinal, bIsReadOnly, vGetter, vSetter, bGetterFinal, bSetterFinal);

            end
--[[
            print(  string.format("Key: %s, Final: %s, Read Only: %s, Getter: %s, Setter: %s, Getter Final: %s, Setter Final: %s,",
                    sKey,
                    tostring(bIsFinal),
                    tostring(bIsReadOnly),
                    vGetter or "",
                    vSetter or "",
                    tostring(bGetterFinal),
                    tostring(bSetterFinal)
                ))]]
            --TODO FINISH check for naming conflicts!
            --sKeyRaw

        end

    end

    --adopt parents' read-only fields
    local tParent = tKit.parent;

    while (tParent) do

        for sCAI, tReadOnlyFields in pairs(tParent.readOnlyFields) do

            for sKey, tData in pairs(tReadOnlyFields) do
                --print(sCAI, sKey, tData.fixed)
                tKit.readOnlyFields[sCAI][sKey] = tData;
            end

        end

        tParent = tParent.parent
    end


    for sCAI, tKeys in pairs(tKit.directives) do

        for sKey, tDirective in pairs(tKeys) do
            local tVisibility   = tKit[sCAI];
            local sKeyRaw       = tDirective.keyRaw;
            local vValue        = tVisibility[sKeyRaw];

            --check if the key already exists
            if (tVisibility[sKey]) then
                error("Error in class, '${name}'. Attempt to overwrite existing ${visibility} member, '${member}', using AUTO directive of the same name." % {
                    name = tKit.name, visibility = _tCAINames[sCAI], member = tostring(sKey)}, 2);
            end

            --set the new key name/value and delete the old key
            tVisibility[sKey]       = vValue;
            tVisibility[sKeyRaw]    = nil;
            --print(sKeyRaw, sKey, sCAI.." = "..serialize(tKit[sCAI]), vValue)

            if (tDirective.isReadOnly) then
                tKit.readOnlyFields[sCAI][sKey] = {fixed = not (type(vValue) == "null")};
            end

            if (tDirective.isFinal) then
                tKit.finalMethodNames[sCAI][sKey] = true;
            end

            if (tDirective.getter) then
                --set the placeholder
                tKit.pub[tDirective.getter] = _fAutoPlaceHolder;

                --set the method as final (or not)
                if (tDirective.getterIsFinal) then
                    tKit.finalMethodNames.pub[tDirective.getter] = true;
                end

            end

            if (tDirective.setter) then
                --set the placeholder
                tKit.pub[tDirective.setter] = _fAutoPlaceHolder;
--TODO LEFT OFF HERE ...create an else where we set a finalmethodeven if there is no setter but setter is final...
                --set the method as final (or not)
                if (tDirective.setterIsFinal) then
                    tKit.finalMethodNames.pub[tDirective.setter] = true;
                end

            end

        end

    end

end


--[[!
@fqxn LuaEx.Class System.kit.Functions.processFinality
@param table tKit The kit to check.
@scope local
@desc Determines whether the class is final or limited and, if so, sets the limitations or finality.
!]]
function kit.processFinality(tKit, vFinality)
    local sType = type(vFinality);

    if (sType == "boolean") then
        tKit.isFinal = vFinality;

    elseif (sType == "table" and #vFinality > 0) then
        local   sName = tKit.name;
        local   sList, tList, sIndicator, bIsBlacklistItem,
                sKeyType, sValType, sFinalItem;

        for k, v in pairs(vFinality) do
            sKeyType = type(k);
            sValType = type(v);

            if (sKeyType ~= "number" or sValType ~= "string") then
                error("Error in class, '${name}'. Subclass limitation list table must be numerically-indexed with string values." % {name = sName}, 2);
            end

            sIndicator        = v:sub(1, 1);
            bIsBlacklistItem  = sIndicator == "!";

            --set the list type if not already set
            if not (sList) then
                sList = bIsBlacklistItem and "blacklist" or "whitelist";
                tKit[sList] = {};
                tList = tKit[sList];
            end

            --check for combined list items
            if ( (sList == "blacklist" and not   bIsBlacklistItem)  or
                 (sList == "whitelist" and       bIsBlacklistItem)) then
                error("Error in class, '${name}'. Cannot create both a subclass Blacklist and Whitelist for the same class." % {name = sName}, 2);
            end

            sFinalItem = bIsBlacklistItem and v:gsub("^!", "") or v;
            tList[sFinalItem] = true;
        end

    end

end


--[[!
@fqxn LuaEx.Class System.kit.Functions.processInitialIsAChecks
@param table tKit The kit to check.
@scope local
@desc Sets up the kit's isAChecks table with initial values (of potential class items)
<br>which will be updated by the instance for initial null values.
!]]
function kit.processInitialIsAChecks(tKit)

    for sCAI, tValues in pairs(tKit.isAChecks) do

        for sKey, vValue in pairs(tKit[sCAI]) do

            if (isinstance(vValue)) then
                tKit.isAChecks[sCAI][sKey] = {
                    class   = of(vValue),
                    type    = type(vValue),
                    value   = vValue,
                };
            end

        end

    end

end


--[[!
@fqxn LuaEx.Class System.kit.Functions.processInterfaces
@param table tKit The kit for which the interfaces should be processed.
@param table tInterfaces The table of interfaces to enforce.
Note: must be at least an entry table.
@scope local
@desc Stores and enforces each interface.
!]]
function kit.processInterfaces(tKit, tInterfaces)

    for nIndex, iInterface in ipairs(tInterfaces) do
        --store the interface
        tKit.interfaces[nIndex] = iInterface;
        --enforce the interface
        iInterface(tKit);
    end

end


--[[!
@fqxn LuaEx.Class System.kit.Functions.setParent
@param table tKit The kit to check.
@scope local
@desc Checks whether a class kit is allowed to be extended and sets the kit's parent if so.
!]]
function kit.setParent(tKit, cExtendor)
    local sName = tKit.name;

    --check that the extending class exists
    if (type(cExtendor) == "class") then
        --assert(type(kit.repo.byObject[cExtendor]) == "table", "Error creating derived class, '${class}'. Parent class, '${item}', does not exist. Got (${type}) '${item}'."	% {class = sName, type = type(cExtendor), item = tostring(cExtendor)}); --TODO since nil is allowed, this never fires. Why have it here?

        --if the 'cExtendor' input is a real class
        if (kit.repo.byObject[cExtendor]) then
            local tParentKit = kit.repo.byObject[cExtendor];

            --enure the parent class isn't final
            if (tParentKit.isFinal) then
                error("Error creating child class, '${class}'.\nParent class, '${parent}', is final and cannot be extended."	% {class = sName, parent = tParentKit.name}, 3);
            end

            local bHasBlackList = tParentKit.blacklist;

            --ensure, if the parent class is limited, that this one is permitted to subclass
            if ( (bHasBlackList         and tParentKit.blacklist[sName] ~= nil) or
                 (tParentKit.whitelist  and tParentKit.whitelist[sName] == nil) ) then
                local tList       = bHasBlackList and tParentKit.blacklist or tParentKit.whitelist;
                local sSubclasses = "";
                local sPermission = bHasBlackList and "Restricted" or "Permitted";

                for k, v in pairs(tList) do
                    sSubclasses = sSubclasses..k.."\n";
                end

                error("Error creating child class, '${class}'.\nParent class, '${parent}', is limited and cannot be extended by this subclass.\n${permission} subclass types are:\n${list}"	% {class = sName, parent = tParentKit.name, permission = sPermission, list = sSubclasses}, 3);
            end

            --ensure the parent class doesn't have a private constructor
            if (tParentKit.constructorVisibility == "pri") then
                error("Error creating child class, '${class}'.\nParent class, '${parent}', has a private constructor and cannot be extended."	% {class = sName, parent = tParentKit.name}, 3);
            end

            tKit.parent = tParentKit; --note the parent kit
        end

    end

    return bRet;
end


--[[!
@fqxn LuaEx.Class System.kit.Functions.shadowCheck
@param table tKit The kit the check for member shadowing.
@scope local
@desc Ensures there is no member shadowing happening in the class.
!]]
local tCheckIndices  = {met, pro, pub};
function kit.shadowCheck(tKit) --checks for public/protected shadowing
    local tParent   = tKit.parent;

    while (tParent) do

        --iterate over each visibility level
        for _, sCAI in pairs(tCheckIndices) do

            --shadow check each member of the class
            for sKey, vChildValue in pairs(tKit[sCAI]) do
                local zParentValue          = rawtype(tParent[sCAI][sKey]);
                local zChildValue           = rawtype(vChildValue);
                local bIsFunctionOverride   = (zParentValue == "function" and zChildValue == "function");

                --the same key found in any parent is allowed in the child class only if it's a function override, otherwise throw a shadowing error
                if (zParentValue ~= "nil") then

                    if (bIsFunctionOverride) then

                        if (tParent.finalMethodNames[sCAI][sKey]) then --throw an error if the parent method is final
                            error(  "Error in class, '${name}'. Attempt to override final ${visibility} method, '${member}', in parent class, '${parent}'." % {
                                name = tKit.name, visibility = _tCAINames[sCAI], member = tostring(sKey), parent = tParent.name});
                        end

                    else
                        error(  "Error in class, '${name}'. Attempt to shadow existing ${visibility} member, '${member}', in parent class, '${parent}'." % {
                            name = tKit.name, visibility = _tCAINames[sCAI], member = tostring(sKey), parent = tParent.name});
                    end

                end

            end

        end

        --check the next parent above this level (if any)
        tParent = tParent.parent;
    end

end


--[[!
@fqxn LuaEx.Class System.kit.Functions.validateInterfaces
@param table The varargs table.
@scope local
@desc Checks to see if the args input are all valid interfaces.
!]]
function kit.validateInterfaces(sKit, tVarArgs)

    for nIndex, vVarArg in ipairs(tVarArgs) do
        assert( type(vVarArg) == "interface",
                "Error creating class, '${class}'. Vararg index #{index} must be of type interface.\nGot type ${type}."
                % {class = sKit, type = type(vVarArg), index = nIndex});
    end



end


--[[!
@fqxn LuaEx.Class System.kit.Functions.validateName
@param string sName The name to be checked.
@scope local
@desc Ensure the class name is a variable-compliant string.
!]]
function kit.validateName(sName)
    assert(type(sName) 					== "string", 	"Error creating class. Name must be a string.\nGot: (${type}) ${item}." 								    % {					type = type(sName), 			item = tostring(sName)});
    assert(sName:isvariablecompliant(),					"Error creating class, '${class}'. Name must be a variable-compliant string.\nGot: (${type}) ${item}."	% {class = sName,	type = type(sName), 			item = tostring(sName)});
    assert(type(kit.repo.byName[sName])	== "nil", 		"Error creating class, '${class}'. Class already exists."													% {class = sName});
end


--[[!
@fqxn LuaEx.Class System.kit.Functions.validateTables
@param string sName The class name.
@param table tMetamethods The metamethods input table.
@param table tStaticPublic The static public input table.
@param table tPrivate The private input table.
@param table tProtected The protected input table.
@param table tPublic The public input table.
@scope local
@desc Validates all class input tables.
!]]
function kit.validateTables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic)
    assert(type(tMetamethods)			== "table", 	"Error creating class, '${class}'. Metamethods values table expected.\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tMetamethods),		item = tostring(tMetamethods)});
    assert(type(tStaticPublic)			== "table", 	"Error creating class, '${class}'. Static public values table expected.\nGot: (${type}) ${item}." 	% {class = sName, 	type = type(tStaticPublic),		item = tostring(tStaticPublic)});
    assert(type(tPrivate) 				== "table", 	"Error creating class, '${class}'. Private values table expected.\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPrivate), 			item = tostring(tPrivate)});
    assert(type(tProtected) 			== "table", 	"Error creating class, '${class}'. Protected values table expected.\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tProtected), 		item = tostring(tProtected)});
    assert(type(tPublic) 				== "table", 	"Error creating class, '${class}'. Static values table expected.\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPublic), 			item = tostring(tPublic)});

    local tTables = {
        met 	= tMetamethods,
        stapub 	= tStaticPublic,
        pri 	= tPrivate,
        pro		= tProtected,
        pub 	= tPublic,
    };

    --check that each item is named using a string!
    for sTable, tTable in pairs(tTables) do

        for k, v in pairs(tTable) do
            assert(rawtype(k) == "string", "Error creating class, '${class}'. All table indices must be of type string. Got: (${type}) ${item} in ${table} table." % {class = sName, type = type(k), item = tostring(v), table = _tCAINames[sTable]});
        end

    end

    --validate the metamethods
    for sMetaItem, vMetaItem in pairs(tMetamethods) do
        local sMetaname = sMetaItem:gsub(_sDirectiveFNL, '');--TODO form string above forloop using constant
        --print(sMetaItem, sMetaname)
        assert(_tMetaNames[sMetaname],
                "Error creating class, '${class}'. Invalid metamethod, '${metaname}'.\nPermitted metamethods are:\n${metanames}" %
                {class = sName, metaname = sMetaname, metanames = getMetaNamesAsString()});

        assert(rawtype(vMetaItem) == "function",
                "Error creating class, '${class}'. Invalid metamethod type for metamethod, '${metaname}'.\nExpected type function, got type ${type}." %
                {class = sName, metaname = sMetaname, type = type(sMetaItem)});
    end

end

                            --[[
                            ██████╗ ███████╗████████╗██╗   ██╗██████╗ ███╗   ██╗
                            ██╔══██╗██╔════╝╚══██╔══╝██║   ██║██╔══██╗████╗  ██║
                            ██████╔╝█████╗     ██║   ██║   ██║██████╔╝██╔██╗ ██║
                            ██╔══██╗██╔══╝     ██║   ██║   ██║██╔══██╗██║╚██╗██║
                            ██║  ██║███████╗   ██║   ╚██████╔╝██║  ██║██║ ╚████║
                            ╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
                            --]]


local tClassActual = {
    exists                      = exists,
    getbase                     = getbase,
    getbyname                   = getbyname,
    getchildcount               = getchildcount,
    getchildren                 = getchildren,
    getconstructorvisibility    = getconstructorvisibility,
    getname                     = getname,
    getparent                   = getparent,
    haschildren                 = haschildren,
    is                          = is,
    isbase                      = isbase,
    isbaseof                    = isbaseof,
    ischild                     = ischild,
    ischildorself               = ischildorself,
    isdirectchild               = isdirectchild,
    isdirectparent              = isdirectparent,
    isinlineage                 = isinlineage,
    isinstance                  = isinstance,
    isinstanceof                = isinstanceof,
    isparent                    = isparent,
    isparentorself              = isparentorself,
    isstaticconstructorrunning  = isstaticconstructorrunning,
    of                          = of,
};


return rawsetmetatable({}, {
    --[[!
    @fqxn LuaEx.Class System.class.Functions.class
    @param string sClass The name of the class. Note: this must be a unique, variable-compliant string.
    @param table tMetamethods A table containing the class metamethods. Note: undeclared metamethods in this class, if present in a parent class, are automatically inherited.
    @param table tStaticPublic A table containing static public class members.
    @param table tPrivate A table containing the private class members.
    @param table tProtected A table containing the protected class members.
    @param table tPublic A table containing the public class members.
    @param class cExtendor The parent class (if any) from which this class is derived.
    @param interface|table|nil The interface (or numerically-indexed table of interface) this class implements (or nil, if none).
    @param boolean bIsFinal Whether this class is final.
    @scope global
    @desc Builds a class.<br>Note: every method within the static public, private, protected and public tables must accept the instance object and class data table as their first and second arguments respectively.<br>Note: all metamethod within the metamethods table also accept the class instance and cdat table but may also accept a second item depending on if the metamethod is using binary operators such as +, %, etc.<br>Note: The class data table is indexed my pri (private members), pro (protected members), pub (public members) and ins (for all class instances of this class type) and each grants access to the items in that table.<br>Note: to prevent fatal conflicts within the code, all class members are strongly typed. No member's type may be changed with the exception of the null type. Types may be set to and from null; however, items which begin as null, once set to another type, cannot be changed from that type to another non-null type. Items that begins as a type and are then set to null, may be changed back to that original type only. In addition, no class member may be set to nil.<br>Class methods cannot be changed to other methods but may be overridden by methods of the same name within child classes. The one exception to this is methods which have the __FNL suffix added to their name. These methods are final and may not be overridden. Note: though the __FNL suffix appears within the method name in the class table, that suffix is removed during class creation. That is, a method such as, MyMethod_FNL will be called as MyMethod(), leaving off the __FNL suffix during calls to that method. __FNL (and other such suffixes that may be added in the future) can be thought of as a directive to the class building code which, after it renames the method to remove the suffix, marks it as final within the class code to prevent overrides.
    @ret class The class object.
    !]]
    __call 		= kit.build,
    __len 		= function() return kit.count end,
    __index 	= function(t, k)
        return tClassActual[k] or nil;
    end,
    __newindex 	= function(t, k, v) end,--deadcall function to prevent adding external entries to the class module TODO put error here
    __serialize = function()
        return "class";
    end,
    __tostring = function()
        return "classfactory"
    end,
    __type = "classfactory",

});
