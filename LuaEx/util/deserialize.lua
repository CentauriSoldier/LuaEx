local deserialize = {};
--TODO add these to their type metatables or create functions within the types themselves...just make sure to remove them from here
function deserialize.boolean(sFlag)
	return (sFlag == "true") and true or false;
end

function deserialize.number(sNumber)
	return tonumber(sNumber);
end

--TODO make this do all resitricted charas too
function deserialize.string(sString)
	return sString:sub(2):sub(1, -2);
end


function deserialize.table(sTable)
	return loadstring("return "..sTable)();
end


return deserialize;
