return class("DoxAutoPlayMediaStudio",
{--metamethods

},
{--static public

},
{--private
    unescapeHTMLEntities = function(this, cdat, sInput)
    local tEntities = {
        ["&quot;"] = '"',
        ["&apos;"] = "'",
        ["&lt;"]   = "<",
        ["&gt;"]   = ">",
        ["&amp;"]  = "&"
    };

    return (sInput:gsub("(&%a+%;)", tEntities));
end
},
{--protected

},
{--public
    DoxAutoPlayMediaStudio = function(this, cdat, super, sTitle)
        type.assert.string(sTitle, "%S+", "Dox documentation title name must not be blank.");
        local eSyntax = Dox.SYNTAX.LUA;
        local tMimeTypes = {
            DoxMime("lua"),
            DoxMime("autoplay", cdat.pri.unescapeHTMLEntities),
        };
        local sPrismCSS = '<link href="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/themes/prism-okaidia.min.css" rel="stylesheet" />';
        local tPrismScripts = {
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/prism.min.js"></script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/components/prism-lua.min.js"></script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/plugins/toolbar/prism-toolbar.min.js"></script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/prism/${stable}/plugins/copy-to-clipboard/prism-copy-to-clipboard.min.js"></script>',
        };
        super("DoxAutoPlayMediaStudio", sTitle, "!", "!", "@", eSyntax, tMimeTypes, sPrismCSS, tPrismScripts);
    end,
    --TODO ability to get sort order
},
Dox,    --extending class
true,   --if the class is final
nil     --interface(s) (either nil, an interface or a numerically-indexed table of interfaces)
);
