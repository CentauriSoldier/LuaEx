--[[
Planned features
AutoGetter/Setter functions


I've written a class system from scratch. It has inheritence, encapsulation, private, protected, public and static fields and methods. While a couple features are still in-progress, it's almost entirely complete. It also comes with interfaces allowing classes to imlpement 0 to many interfaces. Class may be extended by default or may be set to final and disallowed from being extented.

Can you think of any features it could use?
Even more importantly, can you think of ways it can be simplified, optimized or made moer readable? What do y'all think?

Download here.
]]

--[[TODOs, REVIEWs, BUGs, FIXMEs, HACKs, NOTEs, IMPORTANTs, REVIEWs, OPTIMIZEs,
    DEPRECATEDs, DEBUGs, ISSUEs, QUESTIONs, IMPROVEMENTs
--BUG  public static value types are able to be changed to other types

--NOTE

--TODO edit errors adding commas and, class names, quotes, etc.
--TODO check for _FNL duplicates (e.g., MyFunc and MyFunc_FNL)
--TODO fix metahook
--TODO add directives like auto-setter/mutator methods
]]

--constants --TODO get rid of these, just use met, pri, pro, etc.
constant("CLASS_ACCESS_INDEX_METATABLES",  0);
constant("CLASS_ACCESS_INDEX_PRIVATE",     1);
constant("CLASS_ACCESS_INDEX_PROTECTED",   2);
constant("CLASS_ACCESS_INDEX_PUBLIC",      3);
constant("CLASS_ACCESS_INDEX_INSTANCES",   4);

constant("CLASS_FINAL_MARKER",          "_FNL");
constant("CLASS_FINAL_MARKER_LENGTH",   #CLASS_FINAL_MARKER);
constant("CLASS_CONSTRUCTOR_NAME",      "super");

--localization
local CAI_MET = CLASS_ACCESS_INDEX_METATABLES;
local CAI_PRI = CLASS_ACCESS_INDEX_PRIVATE;
local CAI_PRO = CLASS_ACCESS_INDEX_PROTECTED;
local CAI_PUB = CLASS_ACCESS_INDEX_PUBLIC;
local CAI_INS = CLASS_ACCESS_INDEX_INSTANCES;

local met       = "met"; --the instance's metatable
local stapub    = "stapub"
local pri       = "pri"; --the instance's private table
local pro       = "pro"; --the instance's protected table
local pub       = "pub"; --the instance's public table
local ins       = "ins"; --a table containing all the instances

local tCAINames = {--TODO get rid of these too
    met = "metamethods"; --the instance's metatable
    pri = "private"; --the instance's private table
    pro = "protected"; --the instance's protected table
    pub = "public"; --the instance's public table
    ins = "instances"; --a table containing all the instances
};

--gets the full name of a Class Access Index given the shortname
local function getCAIName(sCAI)
    return tCAINames[sCAI] or "UNKOWN";
end

local CFM   = CLASS_FINAL_MARKER;
local CFML  = CLASS_FINAL_MARKER_LENGTH;
local CCN   = CLASS_CONSTRUCTOR_NAME;

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

--used during instantiation TODO rename these
local tClassDataToWrap = {pri, pro, pub};

local tMetaNames = { --the value indicates whether the index is allowed
__add 		= true,     __band        = true,     __bnot      = true,
__bor 		= true,     __bxor        = true,	  __call      = true,
__close     = false,    __concat 	  = true,     __div	      = true,
__eq        = true,	    __gc 	      = false,    __idiv	  = true,
__index     = false,    __ipairs      = true,     __le        = true,
__len       = true,	    __lt	      = true,	  __metatable = false,
__mod 		= true,     __mode 		  = false,    __mul 	  = true,
__name 	    = true,	    __newindex    = false,    __pairs     = true,
__pow 		= true,     __shl 		  = true,	  __shr       = true,
__sub 	    = true,	    __tostring	  = true,     __unm 	  = true};

local function GetMetaNamesAsString()
    local sRet              = "";
    local tSortedMetaNames  = {};

    for sName, _ in pairs(tMetaNames) do
        table.insert(tSortedMetaNames, sName);
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

local function IsMutableStaticPublicType(sType)
    return (tMutableStaticPublicTypes[sType] or false);
end


local class = {
    count = 0,
	repo  = { --updated on kit.import()
        bykit     = {}, --indexed by kit
		byname    = {}, --index by class/kit name
	},
};


local instance = {
    repo = {
        byclass = {}, --indexed by class object
        bykit   = {}, --indexed by kit
        byname  = {}, --index by class/kit name
    },
};


local kit = {
	--trackers, repo & other properties
	count  = 0, --keep track of the total number of class kits
	repo   = { --stores all class kits for later use
		byname 		= {}, --indexed by class/kit name | updated on kit.import()
		byobject 	= {}, --index by class object | updated when a class object is created
	},
};


                                                --[[
                                                 ________  ___       ________  ________   ________
                                                |\   ____\|\  \     |\   __  \|\   ____\ |\   ____\
                                                \ \  \___|\ \  \    \ \  \|\  \ \  \___|_\ \  \___|_
                                                 \ \  \    \ \  \    \ \   __  \ \_____  \\ \_____  \
                                                  \ \  \____\ \  \____\ \  \ \  \|____|\  \\|____|\  \
                                                   \ \_______\ \_______\ \__\ \__\____\_\  \ ____\_\  \
                                                    \|_______|\|_______|\|__|\|__|\_________\\_________\
                                                                                 \|_________\|_________|]]


--[[!
@module class
@func class.build
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the the kit table. This is called by kit.import().
@ret class A class object.
!]]
function class.build(tKit)
    local oClass    = {}; --this is the class object that gets returned
    local sName     = tKit.name;

    --this is the actual, hidden class table referenced by the returned class object
    local tClass            = table.clone(tKit.staticpublic);   --create the static public members

    local tClassMeta = { --the decoy (returned class object) meta table
        __call      = function(t, ...) --instantiate the class

            --make a list of the parents (if any)
            local tParents          = {};
            local tParentKit        = tKit.parent;

            --order them from top-most, descending
            while (tParentKit) do
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
                --local sParenttext = tMyParent and tMyParent.metadata.kit.name or "NO PARENT";
                --print("\n\nInstantiating "..tParentInfo.kit.name.." with parent "..(sParenttext))
                --instantiate the parent object
                local oParent, tParent = instance.build(tParentInfo.kit, false, tMyParent);

                --store this info for the next iteration
                tParentInfo.decoy   = oParent;
                tParentInfo.actual  = tParent;
            end
            --print("\n\nInstantiating "..tKit.name.." with parent "..tParents[#tParents].actual.metadata.kit.name)
            local oInstance, tInstance = instance.build(tKit, true, tParents[#tParents].actual or nil); --this is the returned instance

            tInstance.pub[sName](...);
            tInstance.constructorcalled = true;
            rawset(tInstance.pub, sName, nil);

            --validate (constructor calls and delete constructors
            local nParents = #tParents;
            for x = nParents, 1, -1 do
                local tParentInfo   = tParents[x];
                local sParent       = tParentInfo.kit.name;

                --local sClass = x == nParents and tKit.name or tParents[x + 1].kit.name;
                --print(tParentInfo.kit.name.." -> "..tParentInfo.actual.constructorcalled)
                if not (tParentInfo.actual.constructorcalled) then
                    --error("Error in class, '${class}'. Failed to call parent constructor for class, '${parent}.'" % {class = sClass, parent = sParent});
                    error("Error in class constructor. Failed to call parent constructor, '${parent}.'" % {parent = sParent});
                end

                rawset(tParentInfo.actual.pub, sParent, nil); --TODO change this index once other types of constructors are permitted

            end

            return oInstance;
        end,
        __index     = function(t, k)
            return tClass[k] or nil;
        end,
        __newindex  = function(t, k, v) --TODO create a param option to silence this (globally and per class object)
            local sType = rawtype(tClass[k]);

            if (sType ~= "nil") then

                if (IsMutableStaticPublicType(sType)) then
                    tClass[k] = v;
                else
                    error("Error in class object, '${class}'. Attempt to modify immutable public static member, '${index},' using value, '${value}.'" % {class = sName, index = tostring(k), value = tostring(v)});
                end

            else
                error("Error in class object, '${class}'. Attempt to modify non-existent public static member, '${index},' using value, '${value}.'" % {class = sName, index = tostring(k), value = tostring(v)});
            end

        end,
        __type = "class",
        __name = sName,
        __lt = function(less, greater) --TODO complete this to check for instances too
            local bRet = false;

            if (type(less) ~= "class" or type(greater) ~= "class") then
                error("Error: attempt to compare non-class type.");--TODO complete this
            end

            local tLessKit      = kit.repo.byobject[less];
            local tGreaterKit   = kit.repo.byobject[greater];

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
        __eq = function(left, right)--TODO COMPLETE
            print(type(left), type(right))
            return "asdasd"
        end
    };

    rawsetmetatable(oClass, tClassMeta);

    --update the repos
    class.repo.bykit[tKit]          = oClass;
    class.repo.byname[tKit.name]    = oClass;

    return oClass;
end


                                        --[[
                                         ___  ________   ________  _________  ________  ________   ________  _______
                                        |\  \|\   ___  \|\   ____\|\___   ___\\   __  \|\   ___  \|\   ____\|\  ___ \
                                        \ \  \ \  \\ \  \ \  \___|\|___ \  \_\ \  \|\  \ \  \\ \  \ \  \___|\ \   __/|
                                         \ \  \ \  \\ \  \ \_____  \   \ \  \ \ \   __  \ \  \\ \  \ \  \    \ \  \_|/__
                                          \ \  \ \  \\ \  \|____|\  \   \ \  \ \ \  \ \  \ \  \\ \  \ \  \____\ \  \_|\ \
                                           \ \__\ \__\\ \__\____\_\  \   \ \__\ \ \__\ \__\ \__\\ \__\ \_______\ \_______\
                                            \|__|\|__| \|__|\_________\   \|__|  \|__|\|__|\|__| \|__|\|_______|\|_______|]]


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function instance.build(tKit, bIsPrimaryCall, tParentActual)
    local oInstance     = {};                       --this is the decoy instance object that gets returned
    local tInstance     = {                         --this is the actual, hidden instance table referenced by the returned decoy, instance object
        met = table.clone(tKit.met), --create the metamethods
        pri = table.clone(tKit.pri), --create the private members
        pro = table.clone(tKit.pro), --etc.
        pub = table.clone(tKit.pub), --TODO should I use clone item or wil this do for cloning custom class types? Shoudl I also force a clone method for this in classes? I could also have attributes in classes that could ask if cloneable...
        ins = tKit.ins,              --TODO should this go here? I think so.....\
        children            = {},    --TODO move to class level or to here? Is there any use for it here?
        constructorcalled   = false, --helps enforce constructor calls
        decoy               = oInstance,            --for internal reference if I need to reach the decoy of a given actual
        metadata            = {                     --info about the instance
            kit = tKit,
        },
        parent              = tParentActual,         --the actual parent (if one exists)
    };

    local tClassDataActual = { --actual class data
        pri = {},
        pro = {},
        pub = {},
        ins = {},
        --parent    = null,
    };

    local tClassData     = {}; --decoy class data (this gets pushed through the wrapped methods)

    rawsetmetatable(tClassData, {
        __index = function(t, k, v)--throw an error if the client access a non-existent Class Data index.
            local vRet = rawget(tClassDataActual, k);

            if (rawtype(vRet) == "nil") then
                local sIndices = "";
                for vIndex, _ in pairs(tClassDataActual) do
                    sIndices = sIndices .. "'"..tostring(vIndex).."', ";
                end
                sIndices = sIndices:sub(1, #sIndices - 2);
                error("Error in class, '${class}'. Attempt to access non-existent class data index, '${index}'.\nValid indices are ${indices}." % {class = tKit.name, index = tostring(k), indices = sIndices});
            end

            return vRet;

        end,
        __newindex = function(t, k, v) --disallows modifications to or deletetions from the tClassData table. TODO make the messsage depending on if event is a change, addition or deletion (for more clarity)
                error("Error in class, '${class}'. Attempt to modify read-only class data." % {class = tKit.name});
        end,
        __metatable = true,
    });

                --TODO instance metatables (use a record-keeping system to determine which meta methods came from which parent so they can call the correct function with one call instead of many)

    --wrap the metamethods
    instance.wrapmetamethods(oInstance, tInstance, tClassData)

    --perform the private, protected and public method wrapping
    for _, sCAI in ipairs(tClassDataToWrap) do
        --local tActive = tClassData[sCAI];

        --wrap the classdata functions
        for k, v in pairs(tInstance[sCAI]) do

            if (rawtype(v) == "function") then

                if (k == tKit.name and tKit.parent) then --deal with the constuctor
                    local tParent = tInstance.parent;
                    --fParentConstructor = tParent[sCAI][tParent.metadata.kit.name] --TODO change the sCAI index when allowing muliple constructors
                    --print("GRABBING "..tParent.metadata.kit.name.." constructor: "..tostring(rawget(tParent[sCAI], tParent.metadata.kit.name)))
                    --local pc = tParent[sCAI][tParent.metadata.kit.name];
                    --local fa = function(...)
                        --tParent[sCAI][tParent.metadata.kit.name] = nil;
                    --    return v(oInstance, tClassData, rawget(tParent[sCAI], tParent.metadata.kit.name), ...);
                    --end
                    --print("Wrapping constructor ".." ("..tostring(fa)..")".." for class "..tKit.name.." and including parent constructor from class "..tParent.metadata.kit.name.." ("..tostring(fParentConstructor)..")")
                    rawset(tInstance[sCAI], k, function(...)
                        --tParent[sCAI][tParent.metadata.kit.name] = nil;
                        local vRet =  v(oInstance, tClassData, rawget(tParent[sCAI], tParent.metadata.kit.name), ...)
                        tParent.constructorcalled = true;
                        --print(tParent.metadata.kit.name.." constructor called: "..tParent.constructorcalled)
                        return vRet;
                    end);
                else --deal with non-constructors
                    local fPC = function(...)
                        return v(oInstance, tClassData, ...);
                    end
                    --print(tInstance.metadata.kit.name..": Wrapping '"..k.."' ("..tostring(fa)..")".." with cdata ID of '"..tostring(tClassData))
                    rawset(tInstance[sCAI], k, fPC);
                end

            end

        end

        local bIsPrivate        = sCAI == pri;
        local bIsProteced       = sCAI == pro;
        local bIsPublic         = sCAI == pub;

        if (bIsPrivate or bIsProteced or bIsPublic) then
            local bAllowUpSearch = bIsProteced or bIsPublic;

            rawsetmetatable(tClassData[sCAI], {
                __index = function(t, k)
                    local vRet          = tInstance[sCAI][k];
                    local zRet          = rawtype(vRet);
                    local tNextParent   = tInstance.parent or nil;

                    --if there's no such public key in the instance, check each parent
                    while (bAllowUpSearch and zRet == "nil" and tNextParent) do
                        vRet        = tNextParent[sCAI][k];
                        local parenttext = "self";
                        if (tNextParent and tNextParent.metadata and tNextParent.metadata.kit and tNextParent.metadata.kit.name) then
                            parenttext = tNextParent.metadata.kit.name;
                        end
                        --print(tInstance.metadata.kit.name.." searching in "..tostring(parenttext).." for index '"..k.."'.", vRet)
                        zRet        = rawtype(vRet);
                        tNextParent = tNextParent.parent or nil;
                    end

                    --if none exists, throw an error
                    --if (rawtype(vRet) == "nil") then
                    if (zRet == "nil") then
                        error("Error in class, '${name}'. Attempt to access ${visibility} member, '${member}', a nil value." % {
                            name = tKit.name, visibility = getCAIName(sCAI), member = tostring(k)});
                    end

                    return vRet;
                end,
                __newindex = function(t, k, v)
                    local tTarget       = tInstance[sCAI];
                    local vVal          = rawget(tTarget, k);
                    local zVal          = rawtype(vVal);
                    local tNextParent   = tInstance.parent or nil;
                    --print(bAllowUpSearch, zVal, tNextParent)
                    --if there's no such public key in the instance, check each parent
                    while (bAllowUpSearch and zVal == "nil" and tNextParent) do
                        tTarget     = tNextParent[sCAI];
                        vVal        = rawget(tTarget, k);
                        zVal        = rawtype(vVal);
                        --print("SEARCHING:........"..tNextParent.metadata.kit.name)
                        tNextParent = tNextParent.parent;
                    end

                    --if none exists, throw an error
                    --if (rawtype(vVal) == "nil") then
                    if (zVal == "nil") then
                        error("Error in class, '${name}'. Attempt to modify ${visibility} member, '${member}', a nil value." % {
                            name = tKit.name, visibility = getCAIName(sCAI), member = tostring(k)});
                    end

                    local sTypeCurrent  = type(tTarget[k]);
                    local sTypeNew      = type(v);

                    if (sTypeNew == "nil") then
                        error("Error in class, '${name}'. Cannot set ${visibility} member, '${member}', to nil." % {
                            name = tKit.name, visibility = getCAIName(sCAI), member = tostring(k)});
                    end

                    if (sTypeCurrent == "function") then --TODO look into this and how, if at all, it would/should work work protected methods
                    --if (bIsPublic and sTypeCurrent == "function") then
                        error("Error in class, '${name}'. Attempt to override ${visibility} class method, '${member}', outside of a subclass context." % {
                            name = tKit.name, visibility = getCAIName(sCAI), member = tostring(k)});
                    end

                    if (sTypeCurrent ~= "null" and sTypeCurrent ~= sTypeNew) then--TODO allow for null values (and keep track of previous type)
                        error("Error in class, '${name}'. Attempt to change type for ${visibility} member, '${member}', from ${typecurrent} to ${typenew}." % {
                            name = tKit.name, visibility = getCAIName(sCAI), visibility = getCAIName(sCAI), member = tostring(k), typecurrent = sTypeCurrent, typenew = sTypeNew});
                    end
                    local te = tNextParent or tInstance;
                --    print("before setting: ", tostring(te.metadata.kit.name), k, rawget(tTarget, k), "-> ", v)
                    rawset(tTarget, k, v);
                    --print("after setting: ", tostring(te.metadata.kit.name), k ,rawget(tTarget, k))
                    --print(tostring(tTarget), rawget(tTarget, k), tTarget[k])
                end,
                __metatable = true,
            });

        end

    end

    --create parents (if any)
    --if (tKit.parent) then

        --instantiate the parent
        --local oParent, tParent = instance.build(tKit.parent, true);
        --log the parent info for later use
        --tInstance.parent = tParent;
                                        --TODO I need to update the children field of each parent (OR do I?)
    --end
    --TODO add serialize missing warrning (or just automatically create the method if it's missing) (or just have base object with methods lie serialize, clone, etc.)
    --create and set the instance metatable
    instance.setmetatable(tKit, oInstance, tInstance, tClassData);
    --instance.setmetatable(tKit, oInstance, tInstance, tClassDataActual);--TODO TESTING LINE (NOT FOR PRODUCTION)

    if not (bIsRecursionCall) then
        ---TODO move to kit.buildclass tKit.instances[oInstance] = tInstance; --store the instance reference (but not its recursively-created, parent instances)

        --call only the bottom-most constructor. Enforce manual parent constructor calls.
        --TODO make sure contrsuctors fire only once then are deleted
        --TODO constructors  (also static initializers for altering static fields ONCE at runtime)
        --print(tInstance.metadata.kit.name)
        --tInstance.pub[tInstance.metadata.kit.name](...);

        --TODO check for the presence of the parent constructor (should have been edeleted after call) Also, TODO delete constructor after call
    end
    --print("\n---->>>>Returning instance for "..tKit.name..".<<<<----\n")
    --print(tInstance.metadata.kit.name..": \n"..table.serialize(tInstance))
    return oInstance, tInstance;
end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function instance.setmetatable(tKit, oInstance, tInstance, tClassData)
    local tMeta         = {}; --actual

    --iterate over all metanames
    for sMetamethod, bAllowed in pairs(tMetaNames) do

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

    tMeta.__index     = function(t, k)
        return tClassData.pub[k] or nil;
    end;

    tMeta.__newindex  = function(t, k, v)
        tClassData.pub[k] = v;
    end;

    tMeta.__type = tKit.name;

    tMeta.__is_luaex_class = true;

    --[[tMetaDecoy = table.clone(tMeta, false);

    local tMetaDecoy    = {--this secures the instance metatable from being modified
        __newindex = function(t, k, v)
            error("Error in class, '${class}'. Attempt to modify read-only instance metatable." % {class = tInstance.metadata.kit.name});
        end,
        __index = function(t, k)
            return tMeta[k] or nil;
        end,
    };]]

    rawsetmetatable(oInstance, tMeta);
end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function instance.wrapmetamethods(oInstance, tInstance, tClassData)

    for sMetamethod, fMetamethod in pairs(tInstance.met) do

        if (sMetamethod == "__add"      or sMetamethod == "__band"      or sMetamethod == "__bor"   or
            sMetamethod == "__bxor"     or sMetamethod == "__concat"    or sMetamethod == "__div"   or
            sMetamethod == "__eq"       or sMetamethod == "__idiv"      or sMetamethod == "__le"    or
            sMetamethod == "__lt"       or sMetamethod == "__mod"       or sMetamethod == "__mul"   or
            sMetamethod == "__pow"      or sMetamethod == "__shl"       or sMetamethod == "__sub"   or
            sMetamethod == "__pairs"    or sMetamethod == "__ipairs")  then

            rawset(tInstance.met, sMetamethod, function(a, b)
                return fMetamethod(a, b, tClassData);
            end);

        elseif (sMetamethod == "__bnot" or sMetamethod == "__len" or sMetamethod == "__shr" or sMetamethod == "__unm" ) then

            rawset(tInstance.met, sMetamethod, function(a)
                return fMetamethod(a, tClassData);
            end);

        elseif (sMetamethod == "__call" or sMetamethod == "__name") then
            rawset(tInstance.met, sMetamethod, function(...)
                return fMetamethod(oInstance, tClassData, ...)
            end);

        elseif (sMetamethod == "__tostring") then

            rawset(tInstance.met, sMetamethod, function(a)
                return fMetamethod(a, tClassData)
            end);

        end

    end

end



--[[
                                                                 ___  __    ___  _________
                                                                |\  \|\  \ |\  \|\___   ___\
                                                                \ \  \/  /|\ \  \|___ \  \_|
                                                                 \ \   ___  \ \  \   \ \  \
                                                                  \ \  \\ \  \ \  \   \ \  \
                                                                   \ \__\\ \__\ \__\   \ \__\
                                                                    \|__| \|__|\|__|    \|__|]]


--functions
--[[!
@module class
@func kit.import
@param string sName The name of the class kit. This must be a unique, variable-compliant name.
@param table tMetamethods A table containing all class metamethods.
@param table tStaticPublic A table containing all static public class members.
@param table tPrivate A table containing all private class members.
@param table tProtected A table containing all protected class members.
@param table tPublic A table containing all public class members.
@param class|nil cExtendor The parent class from which this class derives (if any). If there is no parent class, this argument should be nil.
@param string|table|nil The name (or numerically-indexed table of names) of the interfaces this class implements (or nil, if none).
@param boolean bIsFinal A boolean value indicating whether this class is final.
@scope local
@desc Imports a kit for later use in building class objects
@ret class Class Returns the class returned from the kit.build() tail call.
!]]
function kit.import(_IGNORE_, sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic, cExtendor, vImplements, bIsFinal)

    --validate the input TODO remove any existing metatable from input tables or throw error if can't
    kit.validatename(sName);
    kit.validatetables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic);
    kit.validateinterfaces(vImplements);

    --import/create the elements which will comprise the class kit
    local tKit = {
        --properties
        children		= {
            byname 		= {}, --updated on import
            byobject 	= {}, --updated when a class object is created
        },
        finalmethodnames= {   --this keeps track of methods marked as final to prevent overriding
            pro = {},
            pub = {},
        },
        ins		        = {}, --TODO if not already done, set a metatable so instances can't be altered
        isfinal			= type(bIsFinal) == "boolean" and bIsFinal or false,
        name 			= sName,
        parent			= kit.mayextend(sName, cExtendor) and kit.repo.byobject[cExtendor] or nil, --note the parent kit
        --tables
        met 	        = table.clone(tMetamethods, 	true),--TODO this was recently changed to TRUE since (I think) user-defined metatables should be ignored from input
        stapub 	        = table.clone(tStaticPublic, 	true),
        pri			    = table.clone(tPrivate, 		true),
        pro 		    = table.clone(tProtected, 		true),
        pub      	    = table.clone(tPublic, 			true),
    };

    --note and rename final methods
    kit.processfinalmethods(tKit);

    --check for member shadowing
    kit.shadowcheck(tKit);

    --now that this class kit has been validated, imported & stored, build the class object
    local oClass = class.build(tKit);

    --increment the class kit count
    kit.count = kit.count + 1;

    --store the class kit and class object in the kit repo
    kit.repo.byname[sName]      = tKit;
    kit.repo.byobject[oClass]   = tKit;

    --if this has a parent, update the parent kit's child table
    if (tKit.parent) then
        tKit.parent.children.byname[sName]      = tKit;
        tKit.parent.children.byobject[oClass]   = tKit;
    end

    return oClass;--return the class object;
end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function kit.mayextend(sName, cExtendor)
    local bRet = false;

    --check that the extending class exists
    if (type(cExtendor) == "class") then
        assert(type(kit.repo.byobject[cExtendor]) == "table", "Error creating derived class, '${class}'. Parent class, '${item}', does not exist. Got (${type}) '${item}'."	% {class = sName, type = type(cExtendor), item = tostring(cExtendor)}); --TODO since nil is allowed, this never fires. Why have it here?
        assert(kit.repo.byobject[cExtendor].isfinal == false, "Error creating derived class, '${class}'. Parent class '${parent}' is final and cannot be extended."	% {class = sName, parent = kit.repo.byobject[cExtendor].name})

        bRet = true;
    end

    return bRet;
end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
local tFinalVisibility = {pro, pub};
function kit.processfinalmethods(tKit)
    local sMarker = CLASS_FINAL_MARKER.."$";
    local tChange = {};

    for _, sCAI in pairs(tFinalVisibility) do
        local tVisibility = tKit[sCAI];
        tChange[sCAI] = {};

        for sName, vMethod in pairs(tVisibility) do

            if (rawtype(vMethod) == "function" and sName ~= tKit.name) then --ignores contructors

                if (sName:match(sMarker)) then
                    tChange[sCAI][sName] = vMethod;
                end

            end

        end

    end

    for sCAI, tNames in pairs(tChange) do

        for sName, fMethod in pairs(tNames) do

            --clean the name
            local sNewName = sName:sub(1, #sName - CLASS_FINAL_MARKER_LENGTH);
            --add/delete proper key
            tKit[sCAI][sNewName] = fMethod;
            tKit[sCAI][sName] = nil;

            --log the method as final
            tKit.finalmethodnames[sCAI][sNewName] = true;
        end

    end

end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
local tCheckIndices  = {pro, pub};
function kit.shadowcheck(tKit) --checks for public/protected shadowing
    local tParent   = tKit.parent;

    while (tParent) do

        --iterate over each visibility level
        for _, sCAI in pairs(tCheckIndices) do

            --shadow check each member of the class
            for sKey, vChildValue in pairs(tKit[sCAI]) do
                --print("Kit-"..tKit.name, "sVisibility-"..sCAI, "Parent-"..tParent.name, "Key-"..sKey, "Key Type In Parent-"..type(tParent[sCAI][sKey]))
                local zParentValue          = rawtype(tParent[sCAI][sKey]);
                local zChildValue           = rawtype(vChildValue);
                local bIsFunctionOverride   = (zParentValue == "function" and zChildValue == "function");

                --the same key found in any parent is allowed in the child class only if it's a function override, otherwise throw a shadowing error
                if (zParentValue ~= "nil") then

                    if (bIsFunctionOverride) then

                        if (tParent.finalmethodnames[sCAI][sKey]) then --throw an error if the parent method is final
                            error(  "Error in class, '${name}'. Attempt to override final ${visibility} method, '${member}', in parent class, '${parent}'." % {
                                name = tKit.name, visibility = getCAIName(sCAI), member = tostring(sKey), parent = tParent.name});
                        end

                    else
                        error(  "Error in class, '${name}'. Attempt to shadow existing ${visibility} member, '${member}', in parent class, '${parent}'." % {
                            name = tKit.name, visibility = getCAIName(sCAI), member = tostring(sKey), parent = tParent.name});
                    end

                end

            end

        end

        --check the next parent above this level (if any)
        tParent = tParent.parent;
    end

end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function kit.validateinterfaces(vImplements, tKit)--TODO complete this!!!
    local sImplementsType = type(vImplements);

    if (sImplementsType == "table") then

        for _, iInterface in pairs(vImplements) do

            if (type(iInterface) == "interface") then
                iInterface(tKit);
            end

        end

    elseif (sImplementsType == "interface") then
        vImplements(tKit);
    end

end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function kit.validatename(sName)
    assert(type(sName) 					== "string", 	"Error creating class. Name must be a string.\r\nGot: (${type}) ${item}." 								    % {					type = type(sName), 			item = tostring(sName)});
    assert(sName:isvariablecompliant(),					"Error creating class, '${class}.' Name must be a variable-compliant string.\r\nGot: (${type}) ${item}."	% {class = sName,	type = type(sName), 			item = tostring(sName)});
    assert(type(kit.repo.byname[sName])	== "nil", 		"Error creating class, '${class}.' Class already exists."													% {class = sName});
end


--[[!TODO
@module class
@func kit.
@param table tKit The kit that is to be built.
@scope local
@desc Builds a complete class object given the name of the kit. This is called by kit.import().
@ret class A class object.
!]]
function kit.validatetables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic)
    assert(type(tMetamethods)			== "table", 	"Error creating class, '${class}.' Metamethods values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tMetamethods),		item = tostring(tMetamethods)});
    assert(type(tStaticPublic)			== "table", 	"Error creating class, '${class}.' Static public values table expected.\r\nGot: (${type}) ${item}." 	% {class = sName, 	type = type(tStaticPublic),		item = tostring(tStaticPublic)});
    assert(type(tPrivate) 				== "table", 	"Error creating class, '${class}.' Private values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPrivate), 			item = tostring(tPrivate)});
    assert(type(tProtected) 			== "table", 	"Error creating class, '${class}.' Protected values table expected.\r\nGot: (${type}) ${item}." 		% {class = sName, 	type = type(tProtected), 		item = tostring(tProtected)});
    assert(type(tPublic) 				== "table", 	"Error creating class, '${class}.' Static values table expected.\r\nGot: (${type}) ${item}." 			% {class = sName, 	type = type(tPublic), 			item = tostring(tPublic)});

    local bIsConstructor = false;
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
            assert(rawtype(k) == "string", "Error creating class, '${class}.' All table indices must be of type string. Got: (${type}) ${item} in table, ${table}" % {class = sName, type = type(k), item = tostring(v), table = sTable});
            --TODO consider what visibility constructors must have (no need for private consttructors since static classes are not really needed in Lua?)
            --ensure there's a constructor
            --if ((sTable == "public" or sTable == "protected") and k == sName and rawtype(v) == "function") then
            if ((sTable == pub) and k == sName and rawtype(v) == "function") then

                --make sure there's not already a constructor
                assert(not bIsConstructor, "Error creating class, '${class}.' Redundant constructor detected in ${table} table." % {class = sName, table = sTable});

                --make sure it's in the public table
                --assert(sTable == "public", "Error creating class, ${class}. Constructor must be declared in the 'public' table. Currently declared in the '${table}' table." % {class = sName, table = sTable});

                bIsConstructor = true;
            end

        end

    end


    --validate the metamethods
    for sMetaItem, vMetaItem in pairs(tMetamethods) do
        assert(tMetaNames[sMetaItem],               "Error creating class, '${class}.' Invalid metamethod, '${metaname}.'\nPermitted metamethods are:\n${metanames}"   % {class = sName, metaname = sMetaItem, metanames = GetMetaNamesAsString()});
        assert(rawtype(vMetaItem) == "function",    "Error creating class, '${class}.' Invalid metamethod type for metamethod, '${metaname}.'\nExpected type function, got type ${type}."     % {class = sName, metaname = sMetaItem, type = type(vMetaItem)});
    end

    --TODO import metamethods ONLY if they are legit metanames
    assert(bIsConstructor, "Error creating class, '${class}'. No constructor provided." % {class = sName});
end





                                            --[[ ________  ________  ________  ___  ___  ___  ___      ___ _______
                                                |\   __  \|\   __  \|\   ____\|\  \|\  \|\  \|\  \    /  /|\  ___ \
                                                \ \  \|\  \ \  \|\  \ \  \___|\ \  \\\  \ \  \ \  \  /  / | \   __/|
                                                 \ \   __  \ \   _  _\ \  \    \ \   __  \ \  \ \  \/  / / \ \  \_|/__
                                                  \ \  \ \  \ \  \\  \\ \  \____\ \  \ \  \ \  \ \    / /   \ \  \_|\ \
                                                   \ \__\ \__\ \__\\ _\\ \_______\ \__\ \__\ \__\ \__/ /     \ \_______\
                                                    \|__|\|__|\|__|\|__|\|_______|\|__|\|__|\|__|\|__|/       \|_______|


NOTE This area may contain some useful functions but as of yet they have not been integrated

        	Takes the input tables from a call the class modules and stores the fields
        	& methods for later class construction TODO full description

        --local tClassBuilder		= {};

        	Keeps track of created class objects and their names.
        	The table is indexed by class objects whose value
        	is a table containing the name of the class and a
        	boolean indicating if the class is extendable.
        	Items are put into the table when a class is created
        	and referenced when extending a class at the start of
        	class creation.


function kit.cloneitem = function(vItem)
    local vRet;

    if (type(vItem) == "table") then
        vRet = table.clone(vItem);

    elseif (rawtype(vItem) == "table") then
        local tMeta = rawgetmetatable(vItem);

        if (tMeta and tMeta.__is_luaex_class) then
            vRet = vItem.clone();--TODO what is this?

        else
            vRet = table.clone(vItem);

        end

    else
        vRet = vItem;

    end

    return vRet;
end

function kit.exists = function(vName)
    local tRepo	= type(vName) == "class" and kit.repo.byobject or kit.repo.byname;
    return type(tRepo[vName] ~= "nil");
end

function kit.get = function(vName)
    local tRepo	= type(vName) == "class" and kit.repo.byobject or kit.repo.byname;
    assert(type(tRepo[vName] ~= "nil"), "Error getting class kit, '${name}'. Class does not exist." % {name = tostring(vName)});
    return tRepo[vName];
end

function kit.getparent = function(vName)
    local tRet 	= nil;
    local tKit 	= kit.get(vName);

    if (type(tKit.parent) ~= "nil") then
        tRet = kit.get(tKit.parent);
    end

    return tRet;
end

function kit.prepclassdata(tKit)--TODO this currently not being used
    local tActual = {
        pri = rawsetmetatable({}, {
            __newindex
        }),
        pro = {},
        pub = {},
        ins = {},
    };
    local tDecoy = {};
    rawsetmetatable(tDecoy, {
        __index = function(t, k, v)

            if (rawtype(rawget(tActual, k)) == "nil") then
                error("Error in class, '${class}'. Attempt to access non-existent class data index, '${index}'." % {class = tKit.name, index = tostring(k)});
            end

        end,
        __newindex = function(t, k, v)

            if (rawtype(rawget(tActual, k)) == "nil") then
                error("Error in class, '${class}'. Attempt to modify read-only class data." % {class = tKit.name});
            end

        end,
        __metatable = true,
    });

    return tDecoy;
end
]]



local tClassActual = {
    isderived = function()
        print("This is still in development.")
    end,
};


return rawsetmetatable({}, {
	__call 		= kit.import,
	__len 		= function() return kit.count end,
	__index 	= function(t, k)
		return tClassActual[k] or nil;
	end,
	__newindex 	= function(t, k, v) end,--deadcall function to prevent adding external entries to the class module TODO put error here

});
