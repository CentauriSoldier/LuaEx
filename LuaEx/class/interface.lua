local tInterfaceBuilder = {};
local tInterfaceObjects = {};

local assert = assert;
local pairs = pairs;
local type = type;

local tVisibilityToErrorString = {
    met 	= "metamethods",
    stapub  = "static public",
    pri 	= "private",
    pro     = "protected",
    pub		= "public",
}

local function callerror(sKit, tKit, sChecking)
    return "Error creating class, ${kit}. Input item is not a class kit. Got ${item} (${type}) while checking ${checking}." % {kit = tostring(sKit), item = tostring(tKit), type = type(tKit), checking = sChecking};
end

local function visibilitytablehasfunction(tTable, sFunction)
    local bRet = false;

    for k, v in pairs(tTable) do
        --print(k)
        if (type(v) == "function" and k == sFunction) then
            bRet = true;
            break;
        end

    end

    return bRet;
end

local function validatevisibilitytable(sKit, sInterface, tKit, tInterface, sVisibility)

    for sFunction, _ in pairs(tInterface[sVisibility]) do

        assert(visibilitytablehasfunction(	tKit[sVisibility], sFunction),
                                            "Error creating class, ${class}. Class implements interface, ${interface}, but is missing ${visibility} method, '${method}'."
                                            % {class = sKit, interface = sInterface, method = sFunction, visibility = tVisibilityToErrorString[sVisibility]});
    end

end


local function checkinput(tMetamethods, tStaticProtected, tStaticPublic, tPrivate, tProtected, tPublic)

end;

--TODO LEFT OFF HERE Need isA and hasA functions for interfaces and classes
--TODO documentation (document as a class module)
local function extends(sName, iExtendor)
    local bRet = false;

    if (type(iExtendor) == "interface") then
        assert(type(tInterfaceObjects[iExtendor]) == "table", "Error extending interface, ${interface}. Parent interface, ${item}, does not exist. Got (${type}) ${item}."	% {interface = sName, type = type(iExtendor), item = tostring(iExtendor)});
        bRet = true;
    end

    return bRet;
end


local function getparent(sName)
    local tRet 			= nil;
    local tInterface 	= tInterfaceBuilder[sName];

    if (type(tInterface.parent) ~= "nil" and tInterfaceBuilder[tInterface.parent]) then
        tRet = tInterfaceBuilder[tInterface.parent];
    end

    return tRet;
end



local function interface(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic, iExtendor)
    --this is the table returned (interface object)
    local oInterface = {};

    --this is table containing the interface items that
    --are referenced by calls to the oInterface
    local tInterface = {
        met 	= {},
        stapub 	= {},
        pri	    = {},
        pro     = {},
        pub     = {},
    };

    assert(type(sName) == "string" and sName:isvariablecompliant(), "Error creating interface. Name must be a variable-compliant string. Got ${name} (${type})." % {name = tostring(sName), type(sName)});
    assert(type(tInterfaceBuilder[sName]) == "nil", "Error creating interface, ${sName}. Interface already exists.");

    local bExtend = extends(sName, iExtendor);

    tInterfaceBuilder[sName] = {
        children    = {},
        parent      = bExtend and iExtendor or nil,
        name 		= sName,
        met 	    = {},
        stapub      = {},
        pri			= {},
        pro		    = {},
        pub			= {},
    };

    local tVisibilties = {
        met 	= tMetamethods,
        stapub 	= tStaticPublic,
        pri		= tPrivate,
        pro		= tProtected,
        pub		= tPublic,
    };

    --store names in the builder
    for sVisibility, tFunctionNames in pairs(tVisibilties) do

        for _, sFunction in pairs(tFunctionNames) do
            --assert string names here
            assert(type(sFunction) == "string" and sFunction:isvariablecompliant(),
                                    "Error creating interface ${interface}. Method names must be variable compliant strings. Got ${func} (${type})."
                                    % {interface = sName, func = tostring(sFunction), type = type(sFunction)});

            tInterfaceBuilder[sName][sVisibility][sFunction] = true;
        end

    end

    local function importinterfaceitems(tImportFrom, sTableName)

        --import the members
        for sFunction, _ in pairs(tImportFrom[sTableName]) do
            tInterface[sTableName][sFunction] = true;
        end

    end

    --process the parents
    local tParents = {};

    --create the tParents table with top-most classes in descending order
    if (bExtend) then
        local tParent = getparent(tInterfaceObjects[iExtendor].name);
        tParent.children[sName] = tInterfaceBuilder[sName];

        while tParent ~= nil do
            table.insert(tParents, 1, tParent);
            tParent = getparent(tParent.name);
        end

    end

    --import all the parents' items
    for _, tParent in ipairs(tParents) do
        importinterfaceitems(tParent, "met");
        importinterfaceitems(tParent, "stapub");
        importinterfaceitems(tParent, "pri");
        importinterfaceitems(tParent, "pro");
        importinterfaceitems(tParent, "pub");
    end

    --import all the interface items
    importinterfaceitems(tInterfaceBuilder[sName], "met");
    importinterfaceitems(tInterfaceBuilder[sName], "stapub");
    importinterfaceitems(tInterfaceBuilder[sName], "pri");
    importinterfaceitems(tInterfaceBuilder[sName], "pro");
    importinterfaceitems(tInterfaceBuilder[sName], "pub");

    setmetatable(oInterface, {
        __call = function(t, tKit)--TODO LEFT OFF HERE            ;
            local sKitName = tostring(tKit.name);
            --print(sKitName)

            assert(type(tKit) 		    == "table", 	callerror(sKitName, tKit, "class kit"));
            assert(type(tKit.name) 	    == "string", 	callerror(sKitName, tKit, "name"));
            assert(type(tKit.met) 	    == "table", 	callerror(sKitName, tKit, "metamethods table"));
            assert(type(tKit.stapub)    == "table", 	callerror(sKitName, tKit, "staticpublic table"));
            assert(type(tKit.pri) 	    == "table", 	callerror(sKitName, tKit, "private table"));
            assert(type(tKit.pro)       == "table", 	callerror(sKitName, tKit, "protected table"));
            assert(type(tKit.pub)       == "table", 	callerror(sKitName, tKit, "public table"));

            validatevisibilitytable(sKitName, sName, tKit, tInterface, "met");
            validatevisibilitytable(sKitName, sName, tKit, tInterface, "stapub");
            validatevisibilitytable(sKitName, sName, tKit, tInterface, "pri");
            validatevisibilitytable(sKitName, sName, tKit, tInterface, "pro");
            validatevisibilitytable(sKitName, sName, tKit, tInterface, "pub");
       end,
       __tostring = function()
           return sName;
       end,
       __type 	= "interface",
    });

    return oInterface;
end

return interface;
