---
layout: default
---
# 🅲🅷🅰🅽🅶🅴🆂 🆃🅾 🅻🆄🅰 🛠

#### The Global Environment

***_G*** has been given a metatable that monitors the protected values (such as enums and constants).

**Note:** In order to mitigate any potential slow-down from this added metatable in ***_G***, simply localize every global variable before use in your scripts *(especially tables)*. On the average, this is good practice anyhow.

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

## 🅲🅻🅰🆂🆂🅴🆂 💥

The 🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​ module allows for many OOP features within Lua. Many classes come pre-built with LuaEx such as stack, queue, set, etc.

# 🅼🅾🅳🆄🅻🅴🆂 ⚙
- #### [🇧​​​​​🇦​​​​​🇸​​​​​🇪​​​​​64](./api/base64.md)
- #### [🇨​​​​​🇱​​​​​🇦​​​​​🇸​​​​​🇸​​​​​](./api/class.md)
- #### [🇨​​​​​🇴​​​​​🇳​​​​​🇸​​​​​🇹​​​​​🇦​​​​​🇳​​​​​🇹​​](./api/constant.md)
- #### [🇩​​​​​🇪​​​​​🇸​​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​](./api/deserialize.md)
- #### [🇪​​​​​🇳​​​​​🇺​​​​​🇲​​​​​](./api/enum.md)
- #### [🇮​​​​​🇳​​​​​🇮​​​​​](./api/ini.md)
- #### [🇲​​​​​🇦​​​​​🇹​​​​​🇭​​​​​](./api/math.md)
- #### [🇶​​​​​🇺​​​​​🇪​​​​​🇺​​​​​🇪​​​​​](./api/queue.md)
- #### [🇸​​​​🇪​​​​​🇷​​​​​🇮​​​​​🇦​​​​​🇱​​​​​🇮​​​​​🇿🇪​​​​​](./api/serialize.md)
- #### [🇸​​​​​🇪​​​​​🇹​​​​​](./api/set.md)
- #### [🇸​​​​​🇹​​​​​🇦​​​​​🇨​​​​​🇰​​​​​](./api/stack.md)
- #### [🇸​​​​​🇹​​​​​🇩​​​​​🇱​​​​​🇮​​​​​🇧​​​​​](./api/stdlib.md)
- #### [🇸​​​​​🇹​​​​​🇷​​​​​🇮​​​​​🇳​​​​​🇬​​​​​](./api/string.md)
- #### [🇸​​​​​🇹​​​​​🇷​​​​​🇺​​​​​🇨​​​​​🇹​​​​​](./api/struct.md)
- #### [🇹​​​​​🇦​​​​​🇧​​​​​🇱​​​​​🇪​​​​​](./api/table.md)
