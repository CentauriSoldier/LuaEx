--[[*
@authors Centauri Soldier
@copyright Public Domain
@description
    <h2>rectangle</h2>
    <p></p>
@license <p>The Unlicense<br>
<br>
@moduleid shape
@version 1.1
@versionhistory
<ul>
    <li>
        <b>1.1</b>
        <br>
        <p>Updated to work with new LuaEx class system.</p>
    </li>
    <li>
        <b>1.0</b>
        <br>
        <p>Created the module.</p>
    </li>
</ul>
@website https://github.com/CentauriSoldier
*]]

abstractMethod = function()
    error("Theis method has not been implemented in the child class.");
end

--localization
local class = class;
local type  = type;
local rawtype  = rawtype;

return class("shape",
{--metamethods
},
{
},
{--private
},
{--protected    
},
{--public
    containsPoint = function()
        error("The 'containsPoint' method has not been implemented in the child class.");
    end,
    clone = function()
        error("The 'clone' method has not been implemented in the child class.");
    end,
    getArea = function()
        error("The 'getArea' method has not been implemented in the child class.");
    end,
    getPos = function()
        error("The 'getPos' method has not been implemented in the child class.");
    end,
    shape = function(this, cdat)
    end,
},
nil,
false,
iShape
);
