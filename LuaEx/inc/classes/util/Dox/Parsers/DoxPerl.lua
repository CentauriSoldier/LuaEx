return class("DoxPerl",
{--metamethods

},
{--static public

},
{--private

},
{--protected

},
{--public
    DoxPerl = function(this, cdat, super, sTitle)
        type.assert.string(sTitle, "%S+", "Dox Parser title name must not be blank.");
        local eSyntax = Dox.SYNTAX.PERL;
        local tMimeTypes = {
            DoxMime("pl"),
            DoxMime("pm"), -- Adding "pm" as an example mime type TODO what is this?
        };

        super("DoxPerl", sTitle, "!", "!", "@", eSyntax, tMimeTypes);
    end,
    --TODO ability to get sort order
},
Dox,    --extending class
true,   --if the class is final
nil     --interface(s) (either nil, an interface, or a numerically-indexed table of interfaces)
);
