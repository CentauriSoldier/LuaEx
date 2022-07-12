#WIP--rewriting for clarity and continuity

## 🇹​​​​​🇾​​​​​🇵​​​​​🇪​​​​​ 🇲​​​​​🇪​​​​​🇹​​​​​🇦​​​​​🇲​​​​​🇪​​​​​🇹​​​​​🇭​​​​​🇴​​​​​🇩​​​​​🇸​​​​​

#### Custom Types

Adding a ***__type*** field to any metatable (or by using ***table.settype***) and assigning a string value to it creates a custom object type. In order to achieve this, the Lua function, ***type*** has been hooked.

If you'd like to get the type of something, ignoring ***user-implemented***, custom implementations of **LuaEx's** custom type feature, simply use the ***xtype*** function. This will not affect pre-built, **LuaEx** types such as ***null***, ***enums***, ***classes***, ***constants***, ***struct factories***, etc. and objects of these types will still return their name as defined by **LuaEx**.

If you want the *actual Lua type* of a thing ignoring ***ALL*** **LuaEx** custom type mechanics, use the ***rawtype*** function.

### Subtypes
They work the same as types except the metatable entry is ***__subtype*** and the function to detect the subtype is ***subtype***.

### Fulltype
The **fulltype** function concatenates the results from **__type** and **__subtype**.

### The NULL Type
NULL (also null) is a custom type added to **LuaEx**. It is of type null and has obligatory comparison behavior for null values in many programming languages. The main purpose of this value, as an alternative for ***nil***, is to allow the retention of table keys while still indicating a lack of value for a given key. Of course, you may use this null value however you wish. You can use the ***isnull*** function to determine whether a value is null. Both ***null*** and ***NULL*** are the same value and may be accessed by using either word.

Note: This works only with the ***type*** function. Calling the ***rawtype*** function with ***null*** (or ***NULL***) as an argument will return the value, "table".

Note: Do not localize ***null*** (or ***NULL***)...strange things happen.

### boolean
- __add (+) Boolean arithmetic OR.
- __concat (..) Attempts to concatenate the boolean value - to the other value by converting the boolean to a string.
- __len (#) Returns 1 and 0 for true and false respectively.
- __mul (*) Boolean arithmetic AND.
- __neg (-) Negates the value so true becomes false and false becomes true.
- __tostring Returns "true" and "false" for true and false respectively.

### number
- __tostring Coerces the number to string.
- __len Converts the number to boolean for values 0 and 1 but nil for all other values.

### string
- __mod Allows for string interpolation.
