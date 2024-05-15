--[[In C#, arrays are fixed-size collections of elements that are of the same type. They behave as follows:

    Fixed Size: Once you create an array with a specific size, you cannot change its size. The length of the array is determined at the time of creation and cannot be modified afterward.

    Contiguous Memory: Array elements are stored in contiguous memory locations. This allows for efficient access to elements using index-based notation.

    Zero-based Indexing: Array indexes start at 0. You access elements of an array using square brackets [] with the index inside, e.g., myArray[0], myArray[1], and so on.

    Type Safety: Arrays are type-safe collections. This means that all elements in an array must be of the same type. When you create an array, you specify the type of elements it will contain.

    Initialization: You can initialize arrays when you declare them or afterward using various syntaxes, such as array initializers or the Array.CreateInstance method.

    Length Property: Arrays have a Length property that returns the total number of elements in the array.

    Bounds Checking: C# performs bounds checking when accessing array elements. If you attempt to access an element outside the bounds of the array, it will result in an IndexOutOfRangeException at runtime.

    Support for Multidimensional Arrays: C# supports multidimensional arrays, including rectangular arrays (arrays of arrays) and jagged arrays (arrays of arrays of varying lengths).

Example of creating and using an array in C#:

csharp

// Declare and initialize an array of integers
int[] myArray = new int[5]; // Creates an array with 5 elements

// Initialize array elements
myArray[0] = 10;
myArray[1] = 20;
myArray[2] = 30;
myArray[3] = 40;
myArray[4] = 50;

// Access array elements
Console.WriteLine(myArray[2]); // Output: 30

// Length property
Console.WriteLine(myArray.Length); // Output: 5

// Iterate over array elements
foreach (int num in myArray)
{
    Console.WriteLine(num);
}

Arrays in C# are fundamental data structures that are widely used for storing and manipulating collections of elements efficiently.]]

local assert        = assert;
local class         = class;
local rawtype       = rawtype;

local sOtherError   = "Error in array class method ${method}: Attempt to operate on non-array value of type ";

-- Array class definition
return class("array",
    { -- Metamethods

    },
    { -- Static public

    },
    { -- Private
        data    = {},
        length  = 0,  -- Represents the current number of elements in the array
        type    = null;
    },
    { -- Protected

    },
    { -- Public
        -- Constructor
        array = function(this, cdat, sType)
            --TODO allow for table input
            --TODO check that this type is valid
            assert(type(type) == "string", "Array type must be a string");
            cdat.pri.type = sType;
        end,

        -- Add item to the array
        --WARNING this should not allow changing the array size; it's possible this method should not exist
        add = function(this, cdat, vItem)
            local bRet = false;

            if (rawtype(vItem) ~= "nil") then
                -- Check if the item type matches the array type
                if rawtype(vItem) == cdat.pri.type then
                    table.insert(cdat.pri.data, vItem);
                    cdat.pri.length = cdat.pri.length + 1;
                    bRet = true;
                else
                    error("Attempt to add item of incorrect type to array");
                end
            end

            return bRet;
        end,

        -- Get item from the array by index
        get = function(this, cdat, nIndex)
            assert(type(nIndex) == "number" and nIndex >= 1 and nIndex <= cdat.pri.length,
                "Error in class, array. Invalid index or index out of bounds.");
            return cdat.pri.data[nIndex];
        end,

        -- Set item in the array by index
        set = function(this, cdat, nIndex, vItem)
            assert(type(nIndex) == "number" and nIndex >= 1 and nIndex <= cdat.pri.length,
                "Error in class, array. Invalid index or index out of bounds.");
            -- Check if the item type matches the array type
            if rawtype(vItem) == cdat.pub.type then
                cdat.pri.data[nIndex] = vItem;
            else
                error("Attempt to set item of incorrect type in array");
            end
        end,

        -- Get the current length of the array
        length = function(this, cdat)
            return cdat.pri.length;
        end,
    },
    nil,    -- Extending class
    nil,    -- Interface(s)
    false   -- If the class is final
);
