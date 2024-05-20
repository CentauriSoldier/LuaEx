local t = {
	["stack"] = {
		["ProcessOrder"] = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
			[6] = 6,
			[7] = 7,
			[8] = 8,
			[9] = 9,
			[10] = 10,
			[11] = 11,
			[12] = 12,
		},
		["Blocks"] = {
			[1] = {
				["Description"] = "Creates an iterator function to iterate over the elements of the stack.",
				["File"] = "",
				["Function"] = "__call",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "function An iterator function that returns each element of the stack.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[2] = {
				["Description"] = "Returns the number of elements currently in the stack.",
				["File"] = "",
				["Function"] = "__len",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "number The number of elements in the stack.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[3] = {
				["Description"] = "Returns a string representing the items in the stack.",
				["File"] = "",
				["Function"] = "__tostring",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "string A string representing the items in the stack.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[4] = {
				["Description"] = "Constructs a new stack object.",
				["File"] = "",
				["Function"] = "stack",
				["Example"] = "",
				["Parameters"] = {
					[1] = "table|nil A numerically-indexed table of items to push onto the stack (optional).",
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "stack A new stack object.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[5] = {
				["Description"] = "Removes all elements from the stack.",
				["File"] = "",
				["Function"] = "stack.clear",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "stack The stack object after clearing all items.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[6] = {
				["Description"] = "Deserializes the stack object from a string.",
				["File"] = "",
				["Function"] = "stack.deserialize",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[7] = {
				["Description"] = "Retrieves the next-in-line element from the stack without removing it.",
				["File"] = "",
				["Function"] = "stack.peek",
				["Example"] = "",
				["Parameters"] = {
					[1] = "table cdat The class data table.",
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "any The next-in-line element in the stack, or nil if the stack is empty.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[8] = {
				["Description"] = "Removes and returns the top element of the stack.",
				["File"] = "",
				["Function"] = "stack.pop",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "any The removed element from the stack.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[9] = {
				["Description"] = "Adds a new element to the top of the stack.",
				["File"] = "",
				["Function"] = "stack.push",
				["Example"] = "",
				["Parameters"] = {
					[1] = "any vValue The value to be added to the stack.",
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "stack The stack object after pushing the value.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[10] = {
				["Description"] = "Reverses the order of elements in the stack.",
				["File"] = "",
				["Function"] = "stack.reverse",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "stack The stack object after reversing the elements.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[11] = {
				["Description"] = "Serializes the stack object to a string.",
				["File"] = "",
				["Function"] = "stack.serialize",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "string A string representing the stack object which can be stored and later deserialized.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[12] = {
				["Description"] = "Returns the number of elements in the stack.",
				["File"] = "",
				["Function"] = "stack.size",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "stack",
				["Return"] = {
					[1] = "number The number of elements in the stack.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
		},
		["Info"] = {
			["authors"] = "",
			["description"] = "",
			["features"] = "",
			["copyright"] = "",
			["email"] = "",
			["displayname"] = "",
			["versionhistory"] = "",
			["website"] = "",
			["plannedfeatures"] = "",
			["todo"] = "",
			["license"] = "",
			["usage"] = "",
			["dependencies"] = "",
			["version"] = "",
		},
	},
	["queue"] = {
		["ProcessOrder"] = {
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
			[6] = 7,
			[7] = 8,
			[8] = 6,
			[9] = 9,
			[10] = 10,
			[11] = 11,
			[12] = 12,
		},
		["Blocks"] = {
			[1] = {
				["Description"] = "Creates an iterator function to iterate over the elements of the queue.",
				["File"] = "",
				["Function"] = "__call",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "function An iterator function that returns each element of the queue.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[2] = {
				["Description"] = "Returns the number of elements currently in the queue.",
				["File"] = "",
				["Function"] = "__len",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "number The number of elements in the queue.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[3] = {
				["Description"] = "Returns a string representing the items in the queue.",
				["File"] = "",
				["Function"] = "__tostring",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "string A string representing the items in the queue.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[4] = {
				["Description"] = "Constructs a new queue object.",
				["File"] = "",
				["Function"] = "queue",
				["Example"] = "",
				["Parameters"] = {
					[1] = "table|nil A numerically-indexed table of items to add to enqueue (optional).",
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "queue A new queue object.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[5] = {
				["Description"] = "Removes all items from the queue.\n    ret queue The queue object after clearing all items.",
				["File"] = "",
				["Function"] = "queue.clear",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[6] = {
				["Description"] = "Adds an element to the end of the queue.",
				["File"] = "",
				["Function"] = "queue.enqueue",
				["Example"] = "",
				["Parameters"] = {
					[1] = "any vValue The value to enqueue.",
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "any The queue object after enqueueing the item.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[7] = {
				["Description"] = "Adds an element to the end of the queue.",
				["File"] = "",
				["Function"] = "queue.dequeue",
				["Example"] = "",
				["Parameters"] = {
					[1] = "any vValue The value to dequeue.",
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "any The value dequeue.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[8] = {
				["Description"] = "Deserializes the queue object from a string.",
				["File"] = "",
				["Function"] = "queue.deserialize",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[9] = {
				["Description"] = "Retrieves the next-in-line element from the queue without removing it.",
				["File"] = "",
				["Function"] = "queue.peek",
				["Example"] = "",
				["Parameters"] = {
					[1] = "table cdat The class data table.",
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "any The next-in-line element in the queue, or nil if the queue is empty.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[10] = {
				["Description"] = "Reverses the order of elements in the queue.",
				["File"] = "",
				["Function"] = "queue.reverse",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "queue The queue object after reversing the elements.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[11] = {
				["Description"] = "Serializes the queue object to a string.",
				["File"] = "",
				["Function"] = "queue.serialize",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "string A string representing the queue object which can be stored and later deserialized.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[12] = {
				["Description"] = "Returns the number of elements currently in the queue.",
				["File"] = "",
				["Function"] = "queue.size",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "queue",
				["Return"] = {
					[1] = "number The number of elements in the queue.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
		},
		["Info"] = {
			["authors"] = "",
			["description"] = "",
			["features"] = "",
			["copyright"] = "",
			["email"] = "",
			["displayname"] = "",
			["versionhistory"] = "",
			["website"] = "",
			["plannedfeatures"] = "",
			["todo"] = "",
			["license"] = "",
			["usage"] = "",
			["dependencies"] = "",
			["version"] = "",
		},
	},
	["array"] = {
		["ProcessOrder"] = {
			[1] = 2,
			[2] = 3,
			[3] = 4,
			[4] = 5,
			[5] = 1,
		},
		["Blocks"] = {
			[1] = {
				["Description"] = "Creates an array object.",
				["File"] = "",
				["Function"] = "array",
				["Example"] = "",
				["Parameters"] = {
					[1] = "vInput The input for creating the array, either a number or a numerically-indexed table of like items.",
				},
				["Module"] = "array",
				["Return"] = {
					[1] = "array The created array object.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[2] = {
				["Description"] = "Creates an iterator function to iterate over the elements of the array.",
				["File"] = "",
				["Function"] = "__call",
				["Example"] = "",
				["Parameters"] = {
					[1] = "array The array object.",
				},
				["Module"] = "array",
				["Return"] = {
					[1] = "function An iterator function that returns each index and element of the array respectively.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[3] = {
				["Description"] = "Retrieves an element from the array by index or a method/property by name.",
				["File"] = "",
				["Function"] = "__index",
				["Example"] = "",
				["Parameters"] = {
					[1] = "number|string vIndex The numeric array index or string name of method/property to retrieve.",
				},
				["Module"] = "array",
				["Return"] = {
					[1] = "any The value at the specified index or the method/property.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[4] = {
				["Description"] = "Assigns a value to the array at a specific index.",
				["File"] = "",
				["Function"] = "__newindex",
				["Example"] = "",
				["Parameters"] = {
					[1] = "number nIndex The index to assign.",
					[2] = "any vVal The non-nill/non-null value to assign.",
				},
				["Module"] = "array",
				["Return"] = {
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[5] = {
				["Description"] = "Converts the array object to a string representation.",
				["File"] = "",
				["Function"] = "__tostring",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "array",
				["Return"] = {
					[1] = "string The string representation of the array.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
		},
		["Info"] = {
			["authors"] = "",
			["description"] = "",
			["features"] = "",
			["copyright"] = "",
			["email"] = "",
			["displayname"] = "",
			["versionhistory"] = "",
			["website"] = "",
			["plannedfeatures"] = "",
			["todo"] = "",
			["license"] = "",
			["usage"] = "",
			["dependencies"] = "",
			["version"] = "",
		},
	},
	["class"] = {
		["ProcessOrder"] = {
			[1] = 1,
			[2] = 2,
		},
		["Blocks"] = {
			[1] = {
				["Description"] = "Builds a complete class object given the the kit table. This is called by kit.build().",
				["File"] = "",
				["Function"] = "class.build",
				["Example"] = "",
				["Parameters"] = {
					[1] = "table tKit The kit that is to be built.",
				},
				["Module"] = "class",
				["Return"] = {
					[1] = "class A class object.",
				},
				["Scope"] = "local",
				["Usage"] = "",
			},
			[2] = {
				["Description"] = "Imports a kit for later use in building class objects",
				["File"] = "",
				["Function"] = "kit.build",
				["Example"] = "",
				["Parameters"] = {
					[1] = "string sName The name of the class kit. This must be a unique, variable-compliant name.",
					[2] = "table tMetamethods A table containing all class metamethods.",
					[3] = "table tStaticPublic A table containing all static public class members.",
					[4] = "table tPrivate A table containing all private class members.",
					[5] = "table tProtected A table containing all protected class members.",
					[6] = "table tPublic A table containing all public class members.",
					[7] = "class|nil cExtendor The parent class from which this class derives (if any). If there is no parent class, this argument should be nil.",
					[8] = "interface|table|nil The interface (or numerically-indexed table of interface) this class implements (or nil, if none).",
					[9] = "boolean bIsFinal A boolean value indicating whether this class is final.",
				},
				["Module"] = "class",
				["Return"] = {
					[1] = "class Class Returns the class returned from the kit.build() tail call.",
				},
				["Scope"] = "local",
				["Usage"] = "",
			},
		},
		["Info"] = {
			["authors"] = "",
			["description"] = "\t<h2>class</h2>\n\t<h3>Bringing Object Oriented Programming to Lua</h3>\n\t<p>The class module aims to bring a simple-to-use, fully function OOP class system to Lua.</p>\n    ",
			["features"] = "",
			["copyright"] = "See LuaEx License\n",
			["email"] = "",
			["displayname"] = "class",
			["versionhistory"] = "<ul>\n\t<li>\n        <b>0.7</b>\n        <br>\n        <p>Bugfix: public static members could not be set or retrieved.</p>\n        <p>Bugfix: __shr method not providing \'other\' parameter to client.</p>\n        <p>Feature: added _FNL directive allowing for final methods and metamethods.</p>\n        <p>Feature: added _AUTO directive allowing automatically created mutator and accessor methods for members.</p>\n        <p>Feature: rewrote <em>(and improved)</em> set, stack and queue classes for new class system.</p>\n        <p>Feature: global <strong><em>is</em></strong> functions are now created for classes upon class creation (e.g., isCreature(vInput)).</p>\n        <b>0.6</b>\n        <br>\n        <p>Change: rewrote class system again from the ground up, avoiding the logic error in the second class system.</p>\n        <b>0.5</b>\n        <br>\n        <p>Change: removed new class system as it had a fatal, uncorrectable flaw.</p>\n        <b>0.4</b>\n        <br>\n        <p>Feature: added interfaces.</p>\n        <b>0.3</b>\n        <br>\n        <p>Change: removed current class system.</p>\n        <p>Change: rewrote class system from scratch.</p>\n        <b>0.2</b>\n        <br>\n        <p>Feature: added several features to the existing class system.</p>\n\t\t<b>0.1</b>\n\t\t<br>\n\t\t<p>Imported <a href=\"https://github.com/Imagine-Programming/\" target=\"_blank\">Bas Groothedde\'s</a> class module.</p>\n\t</li>\n</ul>\n",
			["website"] = "https://github.com/CentauriSoldier/Dox\n",
			["plannedfeatures"] = "",
			["todo"] = "",
			["license"] = "<p>Same as LuaEx license.</p>\n",
			["usage"] = "",
			["dependencies"] = "",
			["version"] = "0.7\n",
		},
	},
	["arrayfactory"] = {
		["ProcessOrder"] = {
			[1] = 1,
		},
		["Blocks"] = {
			[1] = {
				["Description"] = "A deadcall method to prevents modification of the array factory.",
				["File"] = "",
				["Function"] = "__newindex",
				["Example"] = "",
				["Parameters"] = {
					[1] = "string sName The name of the method or property to retrieve.",
				},
				["Module"] = "arrayfactory",
				["Return"] = {
					[1] = "any The method or property.\n!   ]]\n    __index = function(t, k)\n        return rawget(tArray, k) or nil;\n    end,\n\n\n    --[[!",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
		},
		["Info"] = {
			["authors"] = "",
			["description"] = "",
			["features"] = "",
			["copyright"] = "",
			["email"] = "",
			["displayname"] = "",
			["versionhistory"] = "",
			["website"] = "",
			["plannedfeatures"] = "",
			["todo"] = "",
			["license"] = "",
			["usage"] = "",
			["dependencies"] = "",
			["version"] = "",
		},
	},
	["set"] = {
		["ProcessOrder"] = {
			[1] = 3,
			[2] = 4,
			[3] = 5,
			[4] = 6,
			[5] = 7,
			[6] = 8,
			[7] = 1,
			[8] = 2,
			[9] = 9,
			[10] = 10,
			[11] = 11,
			[12] = 12,
			[13] = 13,
			[14] = 14,
			[15] = 15,
			[16] = 16,
			[17] = 17,
			[18] = 19,
			[19] = 18,
			[20] = 20,
			[21] = 21,
		},
		["Blocks"] = {
			[1] = {
				["Description"] = "Adds an item to the set.",
				["File"] = "",
				["Function"] = "additem",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set oSet The set upon which to operate.",
					[2] = "table cdat The instance class data table.",
					[3] = "any vItem The item to add to the set.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "boolean True if the item was added successfully, false otherwise.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[2] = {
				["Description"] = "Removes an item from the set.",
				["File"] = "",
				["Function"] = "removeitem",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set oSet The set upon which to operate.",
					[2] = "table cdat The instance class data table.",
					[3] = "any vItem The item to remove from the set.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "boolean True if the item was removed successfully, false otherwise.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[3] = {
				["Description"] = "Returns the union of this set with another set (A + B).",
				["File"] = "",
				["Function"] = "__add",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set other The other set with which to form the union.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set A new set containing items that are the union of this set and the other.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[4] = {
				["Description"] = "Creates an iterator function to iterate over the elements of the set.",
				["File"] = "",
				["Function"] = "__call",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "function An iterator function that returns each element of the set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[5] = {
				["Description"] = "Determines of the two sets are equal.",
				["File"] = "",
				["Function"] = "__eq",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "boolean True if the two sets are equal, false otherwise.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[6] = {
				["Description"] = "Returns the number of elements currently in the set.",
				["File"] = "",
				["Function"] = "__len",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "number The number of elements in the set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[7] = {
				["Description"] = "Returns the relative complement of this set with repeect to another set (A - B).",
				["File"] = "",
				["Function"] = "__sub",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set other The other set with which to find the relative complement.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set A new set containting values that are in this set but not in the other set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[8] = {
				["Description"] = "Converts the set into a string representation.",
				["File"] = "",
				["Function"] = "__tostring",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "string A string representation of the set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[9] = {
				["Description"] = "Constructs a new set object.",
				["File"] = "",
				["Function"] = "set",
				["Example"] = "",
				["Parameters"] = {
					[1] = "table|nil A table of items to add to the set (optional).",
				},
				["Module"] = "set",
				["Return"] = {
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[10] = {
				["Description"] = "Adds an item to the set.",
				["File"] = "",
				["Function"] = "set.add",
				["Example"] = "",
				["Parameters"] = {
					[1] = "any vItem The item to add to the set.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set The set object after adding the item.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[11] = {
				["Description"] = "Removes all items from the set.",
				["File"] = "",
				["Function"] = "set.clear",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set The set object after adding the item.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[12] = {
				["Description"] = "Checks if the set contains a specific item.",
				["File"] = "",
				["Function"] = "set.contains",
				["Example"] = "",
				["Parameters"] = {
					[1] = "any vItem The item to check for.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "boolean Returns true if the set contains the item, false otherwise.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[13] = {
				["Description"] = "Deserializes the set object from a string.",
				["File"] = "",
				["Function"] = "set.deserialize",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[14] = {
				["Description"] = "Adds all items from another set to this set.",
				["File"] = "",
				["Function"] = "set.importset",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set oOther The other set containing items to add.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set This set object after adding the items found in the other set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[15] = {
				["Description"] = "Returns the intersection of this set with another set.",
				["File"] = "",
				["Function"] = "set.intersection",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set other The other set with which to find the intersection.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set A new set containting values that intersect with this set and the other set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[16] = {
				["Description"] = "Checks if the set is empty.",
				["File"] = "",
				["Function"] = "set.isempty",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "boolean Returns true if the set is empty, false otherwise.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[17] = {
				["Description"] = "Checks if the input set a subset of this set.",
				["File"] = "",
				["Function"] = "set.issubset",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set other The other set to detemine subsetness.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "boolean Returns true if the other set is a subset of this set, false otherwise.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[18] = {
				["Description"] = "Removes an item from the set if it exists.",
				["File"] = "",
				["Function"] = "set.remove",
				["Example"] = "",
				["Parameters"] = {
					[1] = "any vItem The item to remove from the set.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set Returns the set object after removing the item.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[19] = {
				["Description"] = "Removes all items from this set that are present in another set.",
				["File"] = "",
				["Function"] = "set.purgeset",
				["Example"] = "",
				["Parameters"] = {
					[1] = "set other The other set containing items to remove.",
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "set This set object after removing items found in the other set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[20] = {
				["Description"] = "Serializes the set object to a string.",
				["File"] = "",
				["Function"] = "set.serialize",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "string A string representing the set object which can be stored and later deserialized.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
			[21] = {
				["Description"] = "Returns the number of items in the set (Same as #MySet).",
				["File"] = "",
				["Function"] = "set.size",
				["Example"] = "",
				["Parameters"] = {
				},
				["Module"] = "set",
				["Return"] = {
					[1] = "number The number of items in the set.",
				},
				["Scope"] = "global",
				["Usage"] = "",
			},
		},
		["Info"] = {
			["authors"] = "",
			["description"] = "",
			["features"] = "",
			["copyright"] = "",
			["email"] = "",
			["displayname"] = "",
			["versionhistory"] = "",
			["website"] = "",
			["plannedfeatures"] = "",
			["todo"] = "",
			["license"] = "",
			["usage"] = "",
			["dependencies"] = "",
			["version"] = "",
		},
	},
}
