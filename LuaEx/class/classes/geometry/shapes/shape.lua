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


--localization
local class	= class;

return class("shape",
{--metamethods
},
{--static public
},
{--private
},
{--protected
	area = 0,
},
{--public
	containsPoint = function()
		error("The 'containsPoint' function has not been implemented in the child class.");
	end,
	clone = function()
		error("The 'clone' function has not been implemented in the child class.");
	end,
	getArea = function()
		error("The 'getArea' function has not been implemented in the child class.");
	end,
	getPos = function()
		error("The 'getPos' function has not been implemented in the child class.");
	end,
	shape = function(this, cdat)
	end,
},
nil,
false,
iShape
);
