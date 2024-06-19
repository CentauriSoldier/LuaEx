return class("DoxMime",
{--METAMETHODS

},
{--STATIC PUBLIC

},
{--PRIVATE
    name        = "",
    preProcessor  = null,
},
{--PROTECTED

},
{--PUBLIC
    DoxMime = function(this, cdat, sName, fPreProcessor)
        type.assert.string(sName, "%S+");
        local pri = cdat.pri;
        
        pri.preProcessor = type(fPreProcessor) == "function" and fPreProcessor or
                         function(sInput) return sInput end;
        pri.name       = sName:gsub("^%.", ""):lower();
    end,
    getName = function(this, cdat)
        return cdat.pri.name;
    end,
    getPreProcessor = function(this, cdat)
        return cdat.pri.preProcessor;
    end,
    setPreProcessor = function(this, cdat, fPreProcessor)
        type.assert["function"](fPreProcessor);
        pri.preProcessor = fPreProcessor;
    end,
},
nil,   --extending class
false, --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
