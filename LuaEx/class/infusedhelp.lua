local tCH = {};
--TODO create resticted * entry that will return all entries

local function inputHelpIsValid(tInput)
	return true; --TODO complete this
end

local function inputInfoIsValid(tInput)
	return true; --TODO complete this
end

local infusedhelp = setmetatable({},
{
	__call = function(this, tModule, tClassInfo, tHelp)--TODO check input
		--assert(type(tModule) == class, "Error creating help for class. '"..tostring(tModule).."' is not a valid class.")
		--[[
		local mt = getmetatable(object);
		if (mt and type(mt.__class) == "class") then
			return is_derived(mt.__class, base);
		end
		]]

		tCH[tModule] = {
			help 	= {}, --the actual help text
			info 	= {}, --info about the class
			list	= {}, --a list of entries as strings
		};

		--import the class info
		for sIndex, tInfo in pairs(tClassInfo) do
			tCH[tModule].info[sIndex] = {
				desc 	= type(tInfo.desc) 		== "string" and tInfo.desc 		or "",
				title 	= type(tInfo.title) 	== "string" and tInfo.title 	or "",
			};
		end

		--import the help info
		for sIndex, tInfo in pairs(tHelp) do

			--store the help info
			tCH[tModule].help[sIndex] = {
				desc 	= type(tInfo.desc) 		== "string" and tInfo.desc 		or "",
				example = type(tInfo.example) 	== "string" and tInfo.example	or "",
			};

			--add this command to the list of commands for this module
			tCH[tModule].list[#tCH[tModule].list + 1] = sIndex;
		end

		--the actual help function
		return function(sIndex)

			if (tCH[tModule] ~= nil) then

				if (tCH[tModule].help[sIndex] ~= nil) then
					local tHelpInfo = tCH[tModule].help[sIndex];
					print("["..sIndex.."]"..(tHelpInfo.desc ~= "" and "\n"..tHelpInfo.desc or "")..(tHelpInfo.example ~= "" and "\nExample:\n"..tHelpInfo.example or ""));
				else
					local sNoSuchEntry = type(sIndex) ~= "nil" and ("No such entry: '"..tostring(sIndex).."'.\n") or "";

					local sText = sNoSuchEntry.."Below is a complete list of entries for this module:";

					for _, sCommand in pairs(tCH[tModule].list) do
						sText = sText.."\n"..sCommand;
					end

					print(sText);
				end

			else
				print("No such help section: '"..tostring(tModule).."'.");
			end

		end

	end,
});

--create the help for this module
local tClassInfo = {};
local tHelp = {
	infusedhelp = {desc="The constructor for the help function that is returned to the caller."..
						"\nIt accepts three parameters:"..
						"\n\tThe module or class table (table/class)."..
						"\n\t\tThis is the actual table or class (passed by reference)."..
						"\n\tA table containing info about the module (table)."..
						"\n\t\tThis is a numerically-indexed table which has two string keys('title' and 'desc') whose values are strings."..
						"\n\tA table containing the help items to be displayed (table)."..
						"\n\t\tThis is a string-indexed table whose keys are the lookup keyword and which has two string keys('desc' and 'example') whose values are strings.",
					example = "mymodule.help = infusedhelp(mymodule, {title=\"mymodule\", desc=\"A basic, awesome module.\"}, {\"finonaci\" = {desc = \"Description goes here.\"}, example=\"--Code example goes here.\"});",
				},
};

infusedhelp.help = infusedhelp(infusedhelp, tClassInfo, tHelp);

return infusedhelp;
