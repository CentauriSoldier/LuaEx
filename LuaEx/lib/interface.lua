local assert    = assert;
local clone     = clone;
local pairs     = pairs;
local rawtype   = rawtype;
local type      = type;

local _tVisibiliyNames = {
    [1] = "met",
    [2] = "stapub",
    [3] = "pri",
    [4] = "pro",
    [5] = "pub",
};

local _tVisibilityToErrorString = {
    met 	= "metamethods",
    stapub  = "static public",
    pri 	= "private",
    pro     = "protected",
    pub		= "public",
}



local kit = {
    count    = 0,
    repo = {
        byName   = {},
        byObject = {},
    },
};

local interface = {
    repo = {
        byKit    = {},
        byName   = {},
        byObject = {},
    },
};


            --[[
            ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
            ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
            ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗
            ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝
            ██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
            ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝]]


function interface.build(tInterfaceKit)
    local oInterface = {};  --the decoy interface table returned
    local tInterface = {    --the actual interface table
        parent      = tInterfaceKit.parent,
        name 		= tInterfaceKit.name,
        met 	    = clone(tInterfaceKit.met),
        stapub      = clone(tInterfaceKit.stapub),
        pri			= clone(tInterfaceKit.pri),
        pro		    = clone(tInterfaceKit.pro),
        pub			= clone(tInterfaceKit.pub),
    };

    --import all the parent items
    local tParentInterfaceKit = tInterface.parent;

    while (tParentInterfaceKit) do

        --iterate over all the visibility tables
        for _, sVisibility in ipairs(_tVisibiliyNames) do

            --import each method name
            for __, sFunction in pairs(tParentInterfaceKit[sVisibility]) do
                table.insert(tInterface[tVisibility], sFunction);
            end

        end

        --set the next parent to check (or nil)
        tParentInterfaceKit = tParentInterfaceKit.parent;
    end


    --set the metatable for the interface object
    setmetatable(oInterface, {
    --[[    __serialize = function()
            local tData = {
                kit  = tInterfaceKit,
                name = tInterface.name,
            };

            return tData;
        end,]]
        __call = function(self, tClassKit)
            --ensure the class kit is valid

            interface.validateClassKit(tInterface, tClassKit);

            local sKitName = tostring(tClassKit.name);

            --ensure the class kit (or its parents) have each required method
            for _, sVisibility in ipairs(_tVisibiliyNames) do

                for __, sMethod in pairs(tInterface[sVisibility]) do
                    interface.validateMethod(tInterface, tClassKit, sVisibility, sMethod);
                end

            end

       end,
       __tostring = function()
           return sName;
       end,
       __type 	= "interface",
    });


    --TODO store the interface object


    return oInterface;
end



function interface.validateClassKit(tInterface, tClassKit) --TODO simplify this now that callError is localized
    local sKitName = tostring(tClassKit.name);

    local function callError(tInterface, sKit, tKit, sChecking)
        return "Error creating class, ${kit} while validing interface, ${interface}. Input item is not a class kit. Got ${item} (${type}) while checking ${checking}." %
                {kit = tostring(sKit), interface = tInterface.name, item = tostring(tKit), type = type(tKit), checking = sChecking};
    end

    assert(type(tClassKit) 		    == "table", 	callError(tInterface, sKitName, tClassKit, "class kit"));
    assert(type(tClassKit.name) 	== "string", 	callError(tInterface, sKitName, tClassKit, "name"));
    assert(type(tClassKit.met) 	    == "table", 	callError(tInterface, sKitName, tClassKit, "metamethods table"));
    assert(type(tClassKit.stapub)   == "table", 	callError(tInterface, sKitName, tClassKit, "staticpublic table"));
    assert(type(tClassKit.pri) 	    == "table", 	callError(tInterface, sKitName, tClassKit, "private table"));
    assert(type(tClassKit.pro)      == "table", 	callError(tInterface, sKitName, tClassKit, "protected table"));
    assert(type(tClassKit.pub)      == "table", 	callError(tInterface, sKitName, tClassKit, "public table"));
end






function interface.validateMethod(tInterface, tClassKit, sVisibility, sMethod)
    local bMethodFound = false;
    local tCurrentClassKit = tClassKit;

    while (-bMethodFound and tCurrentClassKit) do

        for sItem, vItem in pairs(tCurrentClassKit[sVisibility]) do

            if (sItem == sMethod and type(vItem) == "function") then
                bMethodFound = true;
                break;
            end

        end

        tCurrentClassKit = tCurrentClassKit.parent;
    end

    assert(bMethodFound,
        "Error creating class, '${class}'. Class implements interface, '${interface}', but is missing '${method}' method in ${visibility} table."
        % {class = tClassKit.name, interface = tInterface.name, method = sMethod, visibility = _tVisibilityToErrorString[sVisibility]});
end

                                    --[[
                                    ██╗  ██╗██╗████████╗
                                    ██║ ██╔╝██║╚══██╔══╝
                                    █████╔╝ ██║   ██║
                                    ██╔═██╗ ██║   ██║
                                    ██║  ██╗██║   ██║
                                    ╚═╝  ╚═╝╚═╝   ╚═╝   ]]

function kit.build(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic, iExtendor)
    kit.validateName(sName);
    kit.validateTables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic);
    local bHasParent = kit.hasParent(sName, iExtendor);

    --tInterfaceBuilder[sName][sVisibility][sFunction] = true;
    --this is the table returned (interface object)
    --local oInterface = {};

    local tKit = {
        met 	= clone(tMetamethods,  true),
        stapub 	= clone(tStaticPublic, true),
        pri	    = clone(tPrivate,      true),
        pro     = clone(tProtected,    true),
        pub     = clone(tPublic,       true),
        name    = sName,
        parent	= bHasParent and kit.repo.byobject[iExtendor] or nil, --note the parent kit
    };

    --now that this interface kit has been validated, imported & stored, build the interface object
    local oInterface = interface.build(tKit);

    --increment the interface kit count
    kit.count = kit.count + 1;

    --store the interface kit and interface object in the kit repo
    kit.repo.byName[sName]          = tKit;
    kit.repo.byObject[oInterface]   = tKit;

    return oInterface;--return the interface object;
end



--[[!
@fqxn LuaEx.interface.kit.Functions.hasParent
@param table The varargs table.
@scope local
@desc Checks to see if the input is a valid interface.
!]]
function kit.hasParent(sKit, iExtendor)
    local bRet = false;

    if (iExtendor) then
        assert( type(iExtendor) == "interface",
                "Error creating interface, '${interface}'. Expected type interface.\nGot type ${type}."
                % {interface = sKit, type = type(iExtendor)});

        assert( type(interface.repo[sName]) ~= "nil",
                "Error creating interface, '${name}'. Interface do not exist." %
                {name = sName});

        bRet = true;
    end

    return bRet;
end



function kit.validateName(sName)
    assert( type(sName) == "string" and sName:isvariablecompliant(),
            "Error creating interface. Name must be a variable-compliant string. Got ${name} (${type})." %
            {name = tostring(sName), type(sName)});

    assert( type(interface.repo[sName]) == "nil",
            "Error creating interface, '${name}'. Interface already exists." %
            {name = sName});
end


function kit.validateTables(sName, tMetamethods, tStaticPublic, tPrivate, tProtected, tPublic)
    local tVisibilties = {
        met 	= tMetamethods,
        stapub 	= tStaticPublic,
        pri		= tPrivate,
        pro		= tProtected,
        pub		= tPublic,
    };

    --check for erroneous metatables and ensure variable-compliant strings
    for sVisibility, tFunctionNames in pairs(tVisibilties) do
        assert( rawgetmetatable(tFunctionNames) ~= "nil", --make sure none of these tables have metatables
                "Error creating interface, '${interface}'. The ${visibility} table is malformed, having a metatable." %
                {interface = sName, visibility = _tVisibilityToErrorString[sVisibility]});

        for _, sFunction in pairs(tFunctionNames) do
            --assert string names
            assert( type(sFunction) == "string" and sFunction:isvariablecompliant(),
                    "Error creating interface , '${interface}'. Method names must be variable compliant strings. Got ${func} (${type})."
                    % {interface = sName, func = tostring(sFunction), type = type(sFunction)});
        end

    end

end


return kit.build;--TODO FINISH
