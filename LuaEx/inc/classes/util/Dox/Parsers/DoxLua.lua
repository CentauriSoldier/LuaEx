return class("DoxLua",
{--metamethods

},
{--static public

},
{--private
    preprocessDocumentation = function(this, cdat, docString)
        -- Define a table to hold the escaped Lua special items and their unescaped counterparts
        local escapeMap = {
            ["\\%["] = "[",
            ["\\%]"] = "]",
            --["\\%("] = "(",
            --["\\%)"] = ")",
            --["\\%."] = ".",
            --["\\%%"] = "%",
            --["\\%+"] = "+",
            --["\\%-"] = "-",
            --["\\%*"] = "*",
            --["\\%?"] = "?",
            --["\\%^"] = "^",
            --["\\%$"] = "$",
            --["\\%("] = "(",
            --["\\%)"] = ")",
            --["\\%{"] = "{",
            --["\\%}"] = "}",
            --["\\%|"] = "|",
            --["\\%_"] = "_",
            --["\\%/"] = "/",
            --["\\%\\"] = "\\"
        }

        -- Iterate over the escapeMap and replace escaped items in the docString
        for escaped, unescaped in pairs(escapeMap) do
            docString = docString:gsub(escaped, unescaped)
        end

        return docString
    end
},
{--protected

},
{--public
    DoxLua = function(this, cdat, super, sTitle)
        type.assert.string(sTitle, "%S+", "Dox Parser title name must not be blank.");
        local eSyntax = Dox.SYNTAX.LUA;
        local tMimeTypes = {
            DoxMime("lua", cdat.pri.preprocessDocumentation),
        };

        super("DoxLua", sTitle, "!", "!", "@", eSyntax, tMimeTypes);
    end,
    --TODO ability to get sort order
},
Dox,    --extending class
true,   --if the class is final
nil     --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
