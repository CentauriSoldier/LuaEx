--TODO localization


--[[
    @module Dox
    @name DoxLanguage
]]
return class("DoxLanguage",
{--metamethods

},
{--static public

},
{--private
    name            = "",
    fileTypes       = SortedDictionary(),
    commentOpen     = "",
    commentClose    = "",
    escapeCharacter = "",
},
{--protected

},
{--public
    DoxLanguage = function(this, cdat, sName, tFileTypes, sCommentOpen, sCommentClose, sEscapeCharacter)
        type.assert.string(sName,               "%S+");
        type.assert.table(tFileTypes,           "number", "string", 1);
        type.assert.string(sCommentOpen,        "%S+");
        type.assert.string(sCommentClose,       "[^\n]+");
        type.assert.string(sEscapeCharacter,    "%S+");

        local pri           = cdat.pri;
        pri.name            = sName;
        for _, sType in pairs(tFileTypes) do
            pri.fileTypes.add(sType); --TODO format these strings uniformly
        end
        pri.commentOpen     = sCommentOpen;
        pri.commentClose    = sCommentClose;
        pri.escapeCharacter = sEscapeCharacter;
    end,
    addFileType_FNL = function(this, cdat, sType)
        type.assert.string(sType,    "%S+", "Mime type must not be blank.");
        cdat.pri.fileTypes.add(sType);
    end,
    getFileTypes_FNL = function(this, cdat)--TODO should I clone the set? probably/
        return cdat.pri.fileTypes;
    end,
    getCommentClose = function(this, cdat)
        return cdat.pri.commentClose;
    end,
    getCommentOpen = function(this, cdat)
        return cdat.pri.commentOpen;
    end,
    getEscapeCharater = function(this, cdat)
        return cdat.pri.escapeCharacter;
    end,
    getFileTypes = function(this, cdat)
        return clone(cdat.pri.fileTypes);
    end,
    getName = function(this, cdat)
        return cdat.pri.name;
    end,
},
nil,    --extending class
true,   --if the class is final
nil    --interface(s) (either nil, or interface(s))
);
