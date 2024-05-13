--[[

Definitions:
    [ Class Kit (kit) ]
    A kit can be thought of as an Erector set, Lego set, gun parts kit, etc. in that it's merely a collection of components used to build an object, not an object itself. The purpose of kits is handling inheritance. Due to the nature of Lua, parts must be reused (and references to those parts) when building class objects and their children. Kits facilitate the correct association of data in inheritance allowing children to be created and to interact properly with their parent(s). Note that each kit is used to create a single class object though parent kits are referenced when creating class children (that functionality being the entire purpose of kits). In addition, a kit stores metadata about the resulting class.
    [ Details and Rules of Class Objects ]

Process of class creation:

1. A class is created using the 'class' function where class details are declared.
    a.  The 'class' function calls the 'kit.build' function that takes the class-related tables (metamethods, private, public, extends, etc.) as parameters and creates a class build kit.
        i.  The 'kit.build' function takes all the class parameters (sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vImplements, bIsFinal).
        ii. It then validates the class name.
            A.  Name must be a variable-compliant string and one which, obviously, has not been used already to create a class.
        iii.   Then, it validates the class tables using the 'kit.validatetables' function.
        iv.    Then, it validates all (if any) input interfaces using the 'kit.validateinterfaces' function.
        v.     A table (tKit) is created where, among other things, the  input class tables are cloned. This kit table keeps all info about the class for later use in building class objects. It also tracks metadata about the kit and its relatives, instances, etc. Note: this is a class kit, not a class object.
        vi.    The kit is added to the kit repository.
        vii.   A parent is checked for and, if it exists, its 'children' subtable is updated to show the new child kit.
        viii.  The 'class.build' function is called and the named class is built from the proper kit(s).
            A.  The class object
    b.  After the kit has been built, the class function calls the 'kit.toclass' function and returns the resulting class object.

2. The class object (e.g., Animal) is used by calling the name of the class with the required (and optional) parameters.
    a.  The returned result of that call is an instance of the class.

3. The class instance is used as described and designed in the class file created by the end user.


Notes on Visibility
1. Static members are always Public as the behavior of Private Static visibility is emulated using the "local" keyword in Lua and Protected Static members are almost always the result of a design error in a class that can easily create serious problems with state continuity.


Notes on differences to other languages.
          STIRKE -> Protected values are multidirectional. That is, as expected, child classes can see/modify parent protected values but also, parent classes can see/modify child protected values.
Protected, non-function values are located in only a single class. Any calls or changes to these values are facilitated through the use of the __index metamethod in the protected class table.
Protected, function values are able to be overridden by child classes but are otherwise access through the same means as protected, non-function values.
Public and protected, non-function values are strongly-typed.

Working Thoughts, Notes and Questions
Rethinking public and protected access.

1. Should parent constructors be auto-called if not explicitly called?


class Creature
protected nHP = 10;

function GetHP
    return nHP
end

class Human extends Creature

function AdjustHP(nVal)
    return nHP + nVal;
end

class Dog extends Creature
]]
