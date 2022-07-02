









local function defaultplaceholder() end

local function setMeta(tActual)

	local tMeta = {
		__index 	= function(t, k)
			return tActual[k] or nil;
		end,
		__newindex 	= function(t, k, v)

		end,
	};

end

local function struct(vInput)
	local tActual = {};

	if (type(vInput) == "table") then--DO NOT USE RAWTYPE, otherwise custom types will be erroneously overwritten

		for k, v in pairs(vInput) do

			if (type(k) == "string") then
				local sValType = type(v);

				if (sValType == "table") then
					tActual[k] = struct(v);
				else
					tActual[k] = {
						type 			= sValType,
						defaultvalue 	= v or null,
					};
				end

			end

		end

	end

	return setMeta({}, tActual);
end

return struct;
