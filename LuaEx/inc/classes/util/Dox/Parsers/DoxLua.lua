return class("DoxLua",
{--metamethods

},
{--static public

},
{--private

},
{--protected

},
{--public
    DoxLua = function(this, cdat, super, sTitle)
        type.assert.string(sTitle, "%S+", "Dox Parser title name must not be blank.");
        local eSyntax = Dox.SYNTAX.LUA;
        local tMimeTypes = {
            DoxMime("lua"),
        };
        local sPrismCSS = '<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/themes/prism-okaidia.min.css" rel="stylesheet" />';
        local tPrismScripts = {
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/components/prism-lua.min.js"></script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/plugins/toolbar/prism-toolbar.min.js"></script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/plugins/copy-to-clipboard/prism-copy-to-clipboard.min.js"></script>',
        };

        super("DoxLua", sTitle, "!", "!", "@", eSyntax, tMimeTypes, sPrismCSS, tPrismScripts);
    end,
    --TODO ability to get sort order
},
Dox,    --extending class
true,   --if the class is final
nil     --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
