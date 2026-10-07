--==============================================================================
--================================ Load LuaEx ==================================
--==============================================================================
local sSourcePath = "";
if not (LUAEX_INIT) then

    function getsourcepath()
        --determine the call location
        local sPath = debug.getinfo(1, "S").source;
        --remove the calling filename
        local sFilenameRAW = sPath:match("^.+"..package.config:sub(1,1).."(.+)$");
        --make a pattern to account for case
        local sFilename = "";
        for x = 1, #sFilenameRAW do
            local sChar = sFilenameRAW:sub(x, x);

            if (sChar:find("[%a]")) then
                sFilename = sFilename.."["..sChar:upper()..sChar:lower().."]";
            else
                sFilename = sFilename..sChar;
            end

        end

        sPath = sPath:gsub("@", ""):gsub(sFilename, "");
        --remove the "/" at the end
        sPath = sPath:sub(1, sPath:len() - 1);

        return sPath;
    end

    --determine the call location
    sSourcePath = getsourcepath();

    --update the package.path (use the main directory to prevent namespace issues)
    package.path = package.path..";"..sSourcePath.."\\..\\?.lua;";

    --load LuaEx
    require("LuaEx.init");
end
--==============================================================================
--==============================^^ Load LuaEx ^^================================
--==============================================================================

--[[NOTE:
Six additional class-system failures, separate from the scope reproduction in
failed tests.lua. Each test runs in its own function so local class identifiers
and variables do not interfere with the other tests. Unique class names avoid
collisions in LuaEx's class registry. Run this file in a fresh Lua process, as
with the other standalone examples.

Expected: all six tests print PASS and Failed expectations: 0.
Current: all six tests print FAIL and Failed expectations: 6.
An unexpected runtime error is printed as ERROR rather than counted as a
reproduced failure. Check the individual observations below each test title.

This file does not fix or modify LuaEx and does not write any files.
Source locations in the notes refer to LuaEx/lib/class.lua when written.
]]

local nFailed = 0;
local nErrors = 0;

local function RunTest(sName, fTest)
    print("\n"..sName);
    local bSuccess, bPassed = pcall(fTest);

    if (not bSuccess) then
        nErrors = nErrors + 1;
        print("ERROR: "..tostring(bPassed));
    elseif (bPassed) then
        print("PASS: "..sName);
    else
        nFailed = nFailed + 1;
        print("FAIL: "..sName);
    end

end

--==============================================================================
--=========================== Public false values ==============================
--==============================================================================
--[[NOTE:
Expected: reading a public field initialized to false returns false.
Current: the same field reads as false through cdat.pub and nil through the
instance object. This loses the distinction between false and no value.
Cause: instance.setMetatable(), line 1569, uses:
    return tClassData.pub[k] or nil;
The 'or nil' expression discards a legitimate false value.
]]
RunTest("Public false remains false through the instance", function()
    local BugPublicFalse = class("BugPublicFalse",
    {--metamethods
    },
    {--public static members
    },
    {--private members
    },
    {--protected members
    },
    {--public members
        Enabled = false,
        BugPublicFalse = function(this, cdat)
        end,
        GetInternalValue = function(this, cdat)
            return cdat.pub.Enabled;
        end,
    });

    local oValue = BugPublicFalse();
    print("Expected public value: false");
    print("Actual public value: "..tostring(oValue.Enabled));
    print("Internal value: "..tostring(oValue.GetInternalValue()));
    return oValue.Enabled == false and oValue.GetInternalValue() == false;
end);

--==============================================================================
--============================= Deserialization ================================
--==============================================================================
--[[NOTE:
Expected: the generated static deserialize method accepts a table containing
this class's private, protected and public data, and restores its public value.
Current: a correctly shaped input table is rejected as malformed.
Cause: instance.build(), line 1140, checks tMyVisData before that local variable
is declared at line 1146. At the earlier check it is an unrelated global (nil
in the normal environment). The variable available there is tMyData.
The test constructs the input table explicitly to isolate this check from the
serializer's string formatting and packing behavior.
]]
RunTest("Deserialization accepts correctly shaped class data", function()
    local BugDeserialize = class("BugDeserialize",
    {--metamethods
    },
    {--public static members
    },
    {--private members
    },
    {--protected members
    },
    {--public members
        Value = 0,
        BugDeserialize = function(this, cdat)
        end,
    });

    local bSuccess, vResult = pcall(function()
        return BugDeserialize.deserialize({
            BugDeserialize = {
                pri = {},
                pro = {},
                pub = {Value = 42},
            },
        });
    end);

    print("Expected: an instance with Value = 42");
    print("Deserialization succeeded: "..tostring(bSuccess));

    if (not bSuccess) then
        print("Actual error: "..tostring(vResult));
        return false;
    end

    print("Actual Value: "..tostring(vResult.Value));
    return class.isinstanceof(vResult, BugDeserialize) and vResult.Value == 42;
end);

--==============================================================================
--=========================== Inherited field typing ===========================
--==============================================================================
--[[NOTE:
Expected: a protected field initialized to class A rejects an unrelated class B
whether assignment occurs in a parent method or a child method.
Current: the parent method rejects B, but the child method accepts B for the
same inherited field, changing its class constraint.
Cause: instance.setClassDataMetatable() finds the field in the parent's storage,
but uses the child's isAChecks table. At line 1470 its missing type record is
initialized from the NEW value before validation. At line 1486 the incoming
class is then compared against the constraint just created from itself.
The original field owner's recorded class constraint is not used in that path.
]]
RunTest("Inherited fields preserve their original class constraint", function()
    local BugFieldA = class("BugFieldA", {}, {}, {}, {}, {
        BugFieldA = function(this, cdat)
        end,
    });
    local BugFieldB = class("BugFieldB", {}, {}, {}, {}, {
        BugFieldB = function(this, cdat)
        end,
    });
    local BugFieldParent = class("BugFieldParent",
    {--metamethods
    },
    {--public static members
    },
    {--private members
    },
    {--protected members
        Value = null,
    },
    {--public members
        BugFieldParent = function(this, cdat)
            cdat.pro.Value = BugFieldA();
        end,
        SetFromParent = function(this, cdat, oValue)
            cdat.pro.Value = oValue;
        end,
        GetValueType = function(this, cdat)
            return type(cdat.pro.Value);
        end,
    });
    local BugFieldChild = class("BugFieldChild",
    {--metamethods
    },
    {--public static members
    },
    {--private members
    },
    {--protected members
    },
    {--public members
        BugFieldChild = function(this, cdat, super)
            super();
        end,
        SetFromChild = function(this, cdat, oValue)
            cdat.pro.Value = oValue;
        end,
    }, BugFieldParent);

    local oParentTest = BugFieldChild();
    local oChildTest = BugFieldChild();
    local bParentAccepted = pcall(function()
        oParentTest.SetFromParent(BugFieldB());
    end);
    local bChildAccepted = pcall(function()
        oChildTest.SetFromChild(BugFieldB());
    end);

    print("Expected: both methods reject the unrelated class");
    print("Parent accepted B: "..tostring(bParentAccepted));
    print("Child accepted B: "..tostring(bChildAccepted));
    print("Child test's resulting field type: "..oChildTest.GetValueType());
    return not bParentAccepted and not bChildAccepted and
        oChildTest.GetValueType() == "BugFieldA";
end);

--==============================================================================
--========================= Read-only null initialization ======================
--==============================================================================
--[[NOTE:
Expected: a read-only field declared as null can receive its first non-null
value. Assigning null while it is still null must not consume that opportunity.
Current: the null-to-null assignment succeeds but permanently locks the field;
its subsequent first non-null assignment is rejected as a read-only mutation.
Cause: instance.setClassDataMetatable(), lines 1509-1510, sets fixed = true
without checking whether the newly assigned value is still null.
]]
RunTest("Read-only null remains available for its first real value", function()
    local BugReadOnlyNull = class("BugReadOnlyNull",
    {--metamethods
    },
    {--public static members
    },
    {--private members
        Value__RO = null,
    },
    {--protected members
    },
    {--public members
        BugReadOnlyNull = function(this, cdat)
        end,
        SetValue = function(this, cdat, vValue)
            cdat.pri.Value = vValue;
        end,
        GetValue = function(this, cdat)
            return cdat.pri.Value;
        end,
    });

    local oValue = BugReadOnlyNull();
    local bNullAccepted = pcall(function()
        oValue.SetValue(null);
    end);
    local bValueAccepted, vError = pcall(function()
        oValue.SetValue(42);
    end);

    print("Expected: null assignment followed by 42 both succeed");
    print("Null assignment accepted: "..tostring(bNullAccepted));
    print("First real value accepted: "..tostring(bValueAccepted));

    if (not bValueAccepted) then
        print("Actual error: "..tostring(vError));
    end

    return bNullAccepted and bValueAccepted and oValue.GetValue() == 42;
end);

--==============================================================================
--=============================== Base-of query ================================
--==============================================================================
--[[NOTE:
Expected: class.isbaseof(Base, Child) returns true for a root class and its child.
Current: it returns nil, while class.isparent(Base, Child) correctly returns true.
Cause: class.isbaseof(), line 557, resolves tKitB from vClassA instead of vClassB.
Consequently both variables refer to the same kit, and the test requires that
same kit both lack a base and have a base.
]]
RunTest("The base-of query recognizes a real base and child", function()
    local BugQueryBase = class("BugQueryBase", {}, {}, {}, {}, {
        BugQueryBase = function(this, cdat)
        end,
    });
    local BugQueryChild = class("BugQueryChild", {}, {}, {}, {}, {
        BugQueryChild = function(this, cdat, super)
            super();
        end,
    }, BugQueryBase);

    local bIsBase = class.isbaseof(BugQueryBase, BugQueryChild);
    print("Expected base-of result: true");
    print("Actual base-of result: "..tostring(bIsBase));
    print("Parent query control: "..tostring(class.isparent(BugQueryBase, BugQueryChild)));
    return bIsBase == true;
end);

--==============================================================================
--========================== Callable instance arguments =======================
--==============================================================================
--[[NOTE:
Expected: calling oValue("argument") passes this, cdat, then "argument" to the
class's __call declaration. Its remaining argument count should be one.
Current: it passes this, cdat, the instance again, then "argument". User arguments
are shifted by one because the original implicit instance argument is retained.
Cause: instance.wrapMetamethods(), line 1619, calls:
    fMetamethod(oInstance, tClassData, ...)
Lua already passes the callable instance as the first argument in that '...'.
The wrapper injects this and cdat without consuming that implicit instance.
]]
RunTest("Callable instances receive user arguments without a duplicate instance", function()
    local BugCallArguments = class("BugCallArguments",
    {--metamethods
        __call = function(this, cdat, ...)
            return select("#", ...), ...;
        end,
    },
    {--public static members
    },
    {--private members
    },
    {--protected members
    },
    {--public members
        BugCallArguments = function(this, cdat)
        end,
    });

    local oValue = BugCallArguments();
    local nArguments, vFirst, vSecond = oValue("argument");
    print("Expected: one user argument, the string 'argument'");
    print("Actual remaining argument count: "..tostring(nArguments));
    print("First argument type: "..type(vFirst));
    print("First argument is the instance again: "..tostring(vFirst == oValue));
    print("Second argument: "..tostring(vSecond));
    return nArguments == 1 and vFirst == "argument";
end);

print("\nFailed expectations: "..tostring(nFailed));
print("Unexpected test errors: "..tostring(nErrors));
