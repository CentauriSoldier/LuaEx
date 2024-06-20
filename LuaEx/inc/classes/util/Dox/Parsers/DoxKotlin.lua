return class("DoxKotlin",
{--metamethods

},
{--static public

},
{--private

},
{--protected

},
{--public
    DoxKotlin = function(this, cdat, super, sTitle)
        type.assert.string(sTitle, "%S+", "Dox Parser title name must not be blank.");
        local eSyntax = Dox.SYNTAX.KOTLIN;
        local tMimeTypes = {
            DoxMime("kt"),
        };

        super("DoxKotlin", sTitle, "!", "!", "@", eSyntax, tMimeTypes);
    end,
    --TODO ability to get sort order
},
Dox,    --extending class
true,   --if the class is final
nil     --interface(s) (either nil, an interface, or a numerically-indexed table of interfaces)
);
