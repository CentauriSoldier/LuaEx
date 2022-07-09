## 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​

This is used to create classes in **LuaEx**. It allows the client access to many features of Object Oriented Programming (although not all).

It is important to remember that the first two (implicit) arguments to any class constructor (those not passed by the caller) are ***1)*** the instance and ***2)*** a protected, shared table (or nil if the class has no children). This table is used to store non-public fields and methods visible to only to the class, its parents and its children. Each child and parent of a given class instance can access and mutate this table and its elements. This table serves as the "protected" portion of classes' O.O.P.

#### Usage Example
```lua
--used to store protected instance information
local tProtectedRepo = {};

local animal = class "animal" {

	__construct = function(this, protected, sName, bIsBiped)
		--setup the protected table for this instance (or import the given one if it's not nil)
		tProtectedRepo[this] = rawtype(protected) == "table" and protected or {};

		--for readability
		local tProt = tProtectedRepo[this];

		--create the protected properties
		tProt.name 		= type(sName) 		== "string" and sName 		or "";
		tProt.isBiped 	= type(bIsBiped)	== "string" and bIsBiped 	or false;

	end,


};

local dog = class "dog" : extends(animal) {

	__construct = function(this, protected, sName)
		--setup the protected table for this instance (or import the given one if it's not nil)
		tProtectedRepo[this] = rawtype(protected) == "table" and protected or {};

		--for readability
		local tProt = tProtectedRepo[this];

		--call the parent constructor
		this:super(tProt, sName, false);
	end,

	bark = function(this)
		print(tProtectedRepo[this].name.." says, \"Woof!\".");
	end,
};

local spot = dog("Spot");
spot:bark();
```

### [◀ Back](https://centaurisoldier.github.io/LuaEx/)
