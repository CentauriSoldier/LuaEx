local directive = {};


--[[
    This processes all .enum files and converts the data within them to enums.
    The data must be formatted in a specific way or the conversion will fail.
    Rules:
    ▓.  File must start with the lower-case word 'enum' (without quotes) followed
        by a space then the name of the enum then another space then an open brace
        ({).
    ▓.  Each enum entry must be on its own line.
    ▓.  Each item (and/or its explicitly-declared value) must be followed
        immidiately by a comma (,).
    ▓.  Enum items must have a variable-compliant name.
    ▓.  If an enum item is to be given an explicit value, the item name and value
        must be separated by an equal sign (=).
    ▓.  There must be a space directly after the item name and the equal sign as
        well as a space before the explicit value.
    ▓.  Enums may be made private by preceeding the word 'enum' by the word
        'private' (each without quotes) and a space between them.
    ▓.  Enums creative by directives cannot be local and are automatically
        global.
    ▓.  Enums may be embedded as shown below. Note: the end, closing brace
        MUST be on its own line indented to the appropriate level and
        followed by a comma.
    ▓.  Enum creation order is not guaranteed; therefore, it is bad practice
        in enums to refer to other enums.

E.g.,
enum CREATURE {
    HUMAN = 205
    ANIMAL = enum {
        CAT = "cat"
        DOG
        FROG = "Ribbit"
    },
}
]]

function directive.enum(pFile)
    local eRet = nil;
    local iLines = io.lines(pFile);

    if (iLines) then
        local tLines = {};
        l = 0;
        for sLine in iLines do
            l = l + 1
            print(tostring(l)..": "..sLine)
        end

    end

    return eRet;
end

--CREATE A xpcall function for errors in loadstring (for values)

--[[get a list of all files within the package path,
    saving all file paths with the .enum extension.]]

--iterate over each file

--parse the file

--create the enum

--profit
--directive.enum("C:\\Users\\CS\\Sync\\Projects\\GitHub\\Supremecratic\\Supremecratic\\CD_Root\\Data\\Mods\\Shipped\\Population.enum");
return directive;
