## 🇸​​​​​🇹​​​​​🇷​​​​​🇮​​​​​🇳​​​​​🇬​​​​​

Adds several string function to the Lua library.

- **string.cap(*string*, *boolean* or *nil*)** Capatalizes the first letter of the input. If the second argument is true, it also lowers all letters after the first (*string*).
- **string.capall(*string*)** Capatalizes the first letter of each word of the input. The delimiter of a "word" in this context is a space character (*string*).
- **string.totable(*string*, *string*)** Takes a string input and returns a table. The table is split by the provided string delimiter (*table*). ***[Credit & Source](https://www.codegrepper.com/code-examples/lua/lua+split+string+into+table)***
- **string.getfuncname(*function*)** Takes a function as input and returns the name in string form (*string*).
- **string.iskeyword(*string*)** Determines whether the input string is a keyword (*string*).
- **string.isnumeric(*string*)** Determines whether the input is a numeric string (*string*).
- **string.isvariablecompliant(*string*, *boolean* or *nil*)** Determines whether a given string is a valid Lua variable name. If the second argument is false or nil, the function will check a list of Lua (and **LuaEx**) keywords for validation; if not, it will ignore keyword violations (*string*).
- **string.trim(*string*)** Trims the whitespace from the beginning and end of the input string (*string*). ***[Credit & Source](http://snippets.bentasker.co.uk/page-1706031030-Trim-whitespace-from-string-LUA.html)***
- **string.trimright(*string*)** Trims the whitespace from the end of the input string (*string*). ***[Credit & Source](http://snippets.bentasker.co.uk/page-1705231409-Trim-whitespace-from-end-of-string-LUA.html)***
- **string.trimleft(*string*)** Trims the whitespace from the beginning of the input string (*string*). ***[Credit & Source](http://snippets.bentasker.co.uk/page-1706031025-Trim-whitespace-from-beginning-of-string-LUA.html)***
- **string.uuid(*string* or *nil*, *string* or *nil*)** Generates a Universally Unique Identifier string (*string*). *Note: this function does not generate entropy. The client is responsible for having sufficient randomness.*
- **__mod(*string*, *table*)** The **%** metamethod applies to all strings and allows for easy interpolation using a provided table whose keys refer to sections of the string with declared variables ***{$myvar}*** and whose values are strings ***{myvar="string stuff here"}*** (*string*).

#### Usage Example
```lua
--interpolation
local sMyString = "This string has several variables embedded {$var1} it and can be {$mod} much easier than changing the {$et}." % {var1="within", mod="modified", et="entire string"};

print(sMyString);
```

### [◀ Back](https://centaurisoldie
