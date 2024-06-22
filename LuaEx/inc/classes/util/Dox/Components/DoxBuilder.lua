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

},
{--PUBLIC
    DoxBuilder = function(this, cdat, eMime)
        type.assert.custom(eMime, "DoxBuilder.MIME");
        cdat.pri.mime = eMime;
    end,
    build = function(this, cdat)
        error("Error in DoxBuilder. The 'build' method has not been defined", 4);
    end,
    getMime = function(this, cdat)
        return cdat.pri.mime;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
