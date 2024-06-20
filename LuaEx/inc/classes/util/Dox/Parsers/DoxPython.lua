return class("DoxPython",
{--metamethods

},
{--static public

},
{--private

},
{--protected

},
{--public
    DoxPython = function(this, cdat, super, sTitle)
        type.assert.string(sTitle, "%S+", "Dox Parser title name must not be blank.");
        local eSyntax = Dox.SYNTAX.PYTHON;
        local tMimeTypes = {
            DoxMime("py"),
        };

        super("DoxPython", sTitle, "!", "!", "@", eSyntax, tMimeTypes);
    end,
    --TODO ability to get sort order
},
Dox,    --extending class
true,   --if the class is final
nil     --interface(s) (either nil, an interface, or a numerically-indexed table of interfaces)
);
