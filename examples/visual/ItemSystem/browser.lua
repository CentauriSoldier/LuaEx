local lab = require("examples.visual.ItemSystem.model").new();
function workbench_action(sAction, tData)
    return lab.action(sAction, tData);
end
print("Item-system laboratory: real LuaEx containers, 20 editable instances, actor permissions, tab-wide exclusivity, grid footprints, ownership and shop policy.");
return lab.view();
