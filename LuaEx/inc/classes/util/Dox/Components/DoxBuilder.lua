return class("DoxBuilder",
{--METAMETHODS

},
{--STATIC PUBLIC
    MIME = enum("DoxBuilder.MIME", {"HTML", "MARKDOWN", "TXT"}, {"html", "MD", "txt"}, true),
},
{--PRIVATE
    mime = null,
},
{--PROTECTED
    blockWrapper = {
        open = "",
        close = "",
    },
    exampleWrapper = {
        open = "",
        close = "",
    },
},
{--PUBLIC
    DoxBuilder = function(this, cdat, eMime)
        type.assert.custom(eMime, "DoxBuilder.MIME");
        local pri = cdat.pri;
        local pro = cdat.pro;
        pri.mime = eMime;
    end,
    build = function(this, cdat)
        error("Error in DoxBuilder. The 'build' method has not been defined", 4);
    end,
    getBlockWrapper = function(this, cdat)
        return clone(cdat.pro.blockWrapper);
    end,
    getMime = function(this, cdat)
        return cdat.pri.mime;
    end,
    getExampleWrapper = function(this, cdat, eSyntax)
        type.assert.custom(eSyntax, "Dox.SYNTAX");
        return clone(cdat.pro.exampleWrapper);
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
