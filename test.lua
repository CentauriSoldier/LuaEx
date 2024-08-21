-- Print a message
print("Hello, Lua!")

-- Define some variables
local name = "James"
local age = 30

-- Print the variables
print("Name: " .. name)
print("Age: " .. age)

-- Define a function
local function greet(person)
    return "Hello, " .. person .. "!"
end

-- Call the function and print the result
local greeting = greet(name)
print(greeting)

-- Perform some arithmetic
local num1 = 10
local num2 = 5
local sum = num1 + num2
local product = num1 * num2

-- Print arithmetic results
print("Sum of " .. num1 .. " and " .. num2 .. " is " .. sum)
print("Product of " .. num1 .. " and " .. num2 .. " is " .. product)

-- Iterate over a table
local fruits = {"apple", "banana", "cherry"}

print("Fruits:")
for i, fruit in ipairs(fruits) do
    print(i .. ": " .. fruit)
end

-- Simple conditional statement
if age > 18 then
    print(name .. " is an adult.")
else
    print(name .. " is a minor.")
end
