--[[
The MIT License (MIT)

Copyright (c) 2014 Sebastian Schoener

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

https://github.com/sschoener/lua-schema
]]

local schema = {}

-- Checks an object against a schema.
function schema.checkSchema(obj, schem, path)
    if path == nil then
        path = schema.Path.new()
        path:setBase(obj)
    end
    if type(schem) == "function" then
        return schem(obj, path)
    else -- attempt to simply compare the values
        if schem == obj then
            return nil
        end
        return schema.error("Invalid value: "..path.." should be "..tostring(schem), path)
    end
end

function schema.formatOutput(output)
    local format = schema.List()
    for k,v in ipairs(output) do
        format:append(v:format())
    end
    return table.concat(format, "\n")
end

-------------------------------------------------------------------------------
-- Infrastructure
-------------------------------------------------------------------------------

-- Path class. Represents paths to values in a table (the path's *base*).
local Path = {}
function Path.new(...)
    local arg = {...}
    local self = setmetatable({}, Path)
    self.p = {}
    for k,v in ipairs(arg) do
        self.p[k] = v
    end
    return self
end

-- Sets the base of the path, i.e. the table to which the path is relative.
-- Note that this is the actual *table*, not the table's name.
function Path:setBase(base)
    self.base = base
end

-- Gets the base of the path.
function Path:getBase()
    return self.base
end

-- Returns the target of the path or 'nil' if the path is invalid.
function Path:target()
    if self.base == nil then
        error("Path:target() called on a path without a base!")
    end
    local current = self.base
    for k,v in ipairs(self.p) do
        current = current[v]
        if current == nil then
            return nil
        end
    end
    return current
end

-- Pushes an entry to the end of the path.
function Path:push(obj)
    self.p[#self.p + 1] = obj
    return self
end

-- Pops an entry from the end of the path.
function Path:pop()
    local tmp = self.p[#self.p]
    self.p[#self.p] = nil
    return tmp
end

-- Returns the topmost entry of the end of the path.
function Path:top()
    return self.p[#self.p]
end

-- Returns the length of the path.
function Path:length()
    return #self.p
end

-- Returns the element at the specified index.
function Path:get(index)
    return self.p[index]
end

-- Copies the path.
function Path:copy()
    local cp = Path.new()
    cp.base = self.base
    for k,v in ipairs(self) do
        cp.p[k] = v
    end
    return cp
end

Path.__index = Path
Path.__tostring = function(tbl)
    if #tbl.p == 0 then
        return '<val>'
    end
    return table.concat(tbl.p,".")
end
Path.__concat = function(lhs, rhs)
    if type(lhs) == "table" then
        return tostring(lhs)..rhs
    elseif type(rhs) == "table" then
        return lhs..tostring(rhs)
    end
end
Path.__len = function(self)
    return #self.p
end

setmetatable(Path, {
    __call = function (cls, ...)
        return Path.new(...)
    end
})
schema.Path = Path

-- List class
local List = {}
function List.new(...)
    local self = setmetatable({}, List)
    local arg = {...}
    for k,v in ipairs(arg) do
        self[k] = v
    end
    return self
end

function List:add(obj)
    self[#self+1] = obj
    return self
end

function List:append(list)
    for k,v in ipairs(list) do
        self[#self+k] = v
    end
    return self
end

List.__index = List
List.__tostring = function(self)
    local tmp = {}
    for k,v in ipairs(self) do
        tmp[k] = tostring(v)
    end
    return table.concat(tmp, "\n")
end
setmetatable(List, {
    __call = function(cls, ...)
        return List.new(...)
    end
})
schema.List = List

-- Error class. Describes mismatches that occured during the schema-checking.
local Error = {}
function Error.new(msg, path, suberrors)
    local self = setmetatable({}, Error)
    self.message   = msg
    self.path      = path:copy()
    self.suberrors = suberrors
    return self
end

-- Returns a list of strings which represent the error (with indenttation for
-- suberrors).
function Error:format()
    local output = List.new(self.message)
    if self.suberrors ~= nil then
        for k,sub in pairs(self.suberrors) do
            local subout = sub:format()
            for k1,msg in pairs(subout) do
                output = output:add("  "..msg)
            end
        end
    end
    return output
end

Error.__tostring = function(self)
    return table.concat(self:format(), "\n")
end
Error.__index = Error
setmetatable(Error, {
    __call = function(cls, ...)
        return List(Error.new(...))
    end
})
schema.error = Error

-------------------------------------------------------------------------------
-- Schema Building Blocks
-- A schema is a function taking the object to be checked and the path to the
-- current value in the environment.
-- It returns either 'true' if the schema accepted the object or an Error
-- object which describes why it was rejected.
-- The schemata below are just some basic building blocks. Expand them to your
-- liking.
-------------------------------------------------------------------------------

-- Always accepts.
function schema.any(obj, path)
    return nil
end

-- Always fails.
function schema.nothing(obj, path)
    return schema.error("Failure: '"..path.."' will always fail.", path)
end

-- Checks a value against a specific type.
local function TypeSchema(obj, path, typeId)
    if type(obj) ~= typeId then
        return schema.error("Type mismatch: '"..path.."' should be "..typeId..", is "..type(obj), path)
    else
        return nil
    end
end

schema.boolean      = function(obj, path) return TypeSchema(obj, path, "boolean")  end
schema["function"]  = function(obj, path) return TypeSchema(obj, path, "function") end
schema["nil"]       = function(obj, path) return TypeSchema(obj, path, "nil")      end
schema.number       = function(obj, path) return TypeSchema(obj, path, "number")   end
schema.string       = function(obj, path) return TypeSchema(obj, path, "string")   end
schema.table        = function(obj, path) return TypeSchema(obj, path, "table")    end
schema.userData     = function(obj, path) return TypeSchema(obj, path, "userdata") end

-- Checks that some value is a string matching a given pattern.
function schema.pattern(pattern)
    local userPattern = pattern
    if not pattern:match("^^") then
        pattern = "^" .. pattern
    end
    if not pattern:match("$$") then
        pattern = pattern .. "$"
    end
    local function CheckPattern(obj, path)
        local err = schema.String(obj, path)
        if err then
            return err
        end
        if string.match(obj, pattern) then
            return nil
        else
            return schema.error("Invalid value: '"..path.."' must match pattern '"..userPattern.."'", path)
        end
    end
    return CheckPattern
end

-- Checks that some number is an integer.
function schema.integer(obj, path)
    local err = schema.number(obj, path)
    if err then
        return err
    end
    if math.floor(obj) == obj then
        return nil
    end
    return schema.error("Invalid value: '"..path.."' must be an integral number", path)
end

-- Checks that some number is >= 0.
function schema.nonNegativeNumber(obj, path)
    local err = schema.number(obj, path)
    if err then
        return err
    end
    if obj >= 0 then
        return nil
    end
    return schema.error("Invalid value: '"..path.."' must be >= 0", path)
end

-- Checks that some number is > 0.
function schema.positiveNumber(obj, path)
    local err = schema.number(obj, path)
    if err then
        return err
    end
    if obj > 0 then
        return nil
    end
    return schema.error("Invalid value: '"..path.."' must be > 0", path)
end

-- Checks that some value is a number from the interval [lower, upper].
function schema.numberFrom(lower, upper)
    local function CheckNumberFrom(obj, path)
        local err = schema.Number(obj, path)
        if err then
            return err
        end
        if lower <= obj and upper >= obj then
            return nil
        else
            return schema.error("Invalid value: '"..path.."' must be between "..lower.." and "..upper, path)
        end
    end
    return CheckNumberFrom
end

-- Takes schemata and accepts their disjunction.
function schema.oneOf(...)
    local arg = {...}
    local function CheckOneOf(obj, path)
        for k,v in ipairs(arg) do
            local err = schema.checkSchema(obj, v, path)
            if not err then return nil end
        end
        return schema.error("No suitable alternative: No schema matches '"..path.."'", path)
    end
    return CheckOneOf
end

-- Takes a schema and returns an optional schema.
function schema.optional(s)
    return schema.OneOf(s, schema.Nil)
end

-- Takes schemata and accepts their conjuction.
function schema.allOf(...)
    local arg = {...}
    local function CheckAllOf(obj, path)
        local errmsg = nil
        for k,v in ipairs(arg) do
            local err = schema.checkSchema(obj, v, path)
            if err then
                if errmsg == nil then
                    errmsg = err
                else
                    errmsg = errmsg:append(err)
                end
            end
        end
        return errmsg
    end
    return CheckAllOf
end

-- Builds a record type schema, i.e. a table with a fixed set of keys (strings)
-- with corresponding values. Use as in
-- Record({
--  name  = schema,
--  name2 = schema2
--  })
function schema.record(recordschema, additionalValues)
    if additionalValues == nil then
        additionalValues = false
    end
    local function CheckRecord(obj, path)
        if type(obj) ~= "table" then
            return schema.error("Type mismatch: '"..path.."' should be a record (table), is "..type(obj), path)
        end

        local errmsg = nil
        local function AddError(msg)
            if errmsg == nil then
                errmsg = msg
            else
                errmsg = errmsg:append(msg)
            end
        end

        for k,v in pairs(recordschema) do
            path:push(k)
            local err = schema.checkSchema(obj[k], v, path)
            if err then
                AddError(err)
            end
            path:pop()
        end

        for k, v in pairs(obj) do
            path:push(k)
            if type(k) ~= "string" then
                AddError(schema.error("Invalid key: '"..path.."' must be of type 'string'", path))
            end
            if recordschema[k] == nil and not additionalValues then
                AddError(schema.error("Superfluous value: '"..path.."' does not appear in the record schema", path))
            end
            path:pop()
        end
        return errmsg
    end
    return CheckRecord
end

function schema.mixedTable(t_schema, additional_values)
    local function CheckMixedTable(obj, path)
        local obj_t = type(obj)
        if obj_t ~= "table" then
            local msg = ("Type mismatch: '%s' should be a table, is %s"):format(tostring(path), obj_t)
            return schema.error(msg, path)
        end

        local errmsg = nil
        local function AddError(msg)
            if errmsg == nil then
                errmsg = msg
            else
                errmsg = errmsg:append(msg)
            end
        end

        local checked_keys = {}
        for k, v in pairs(t_schema) do
            path:push(k)
            local err = schema.checkSchema(obj[k], v, path)
            if err then
                AddError(err)
            end
            checked_keys[k] = true
            path:pop()
        end

        for k, v in pairs(obj) do
            if not checked_keys[k] then
                path:push(k)
                local k_type = type(k)
                if k_type ~= "string" and k_type ~= "number" then
                    local msg = ("Invalid key: '%s' must be of type 'string' or 'number'"):format(k_type)
                    AddError(schema.error(msg, path))
                end

                local t_schema_v = t_schema[k]
                if t_schema_v then
                    local err = schema.checkSchema(v, t_schema_v, path)
                    if err then
                        AddError(err)
                    end
                else
                    if not additional_values then
                        local msg = ("Superfluous value: '%s' does not appear in the table schema")
                                            :format(tostring(path))
                        AddError(schema.error(msg, path))
                    end
                end
                path:pop()
            end
        end
        return errmsg
    end
    return CheckMixedTable
end

-- Builds a map type schema, i.e. a table with an arbitraty number of
-- entries where both all keys (and all vaules) fit a common schema.
function schema.map(keyschema, valschema)
    local function CheckMap(obj, path)
        if type(obj) ~= "table" then
            return schema.error("Type mismatch: '"..path.."' should be a map (table), is "..type(obj), path)
        end

        local errmsg = nil
        local function AddError(msg)
            if errmsg == nil then
                errmsg = msg
            else
                errmsg = errmsg:append(msg)
            end
        end

        -- aggregate error message
        for k, v in pairs(obj) do
            path:push(k)
            local keyErr = schema.checkSchema(k, keyschema, path)
            if keyErr then
                AddError(schema.error("Invalid map key", path, keyErr))
            end

            local valErr = schema.checkSchema(v, valschema, path)
            if valErr then
                AddError(valErr)
            end
            path:pop()
        end
        return errmsg
    end
    return CheckMap
end

-- Builds a collection type schema, i.e. a table with an arbitrary number of
-- entries where we only care about the type of the values.
function schema.collection(valschema)
    return schema.map(schema.any, valschema)
end

-- Builds a tuple type schema, i.e. a table with a fixed number of entries,
-- each indexed by a number and with a fixed type.
function schema.tuple(...)
    local arg = {...}

    local function CheckTuple(obj, path)
        if type(obj) ~= "table" then
            return schema.error("Type mismatch: '"..path.."' should be a map (tuple), is "..type(obj), path)
        end

        if #obj ~= #arg then
            return schema.error("Invalid length: '"..path.." should have exactly "..#arg.." elements", path)
        end

        local errmsg = nil
        local function AddError(msg)
            if errmsg == nil then
                errmsg = msg
            else
                errmsg = errmsg:append(msg)
            end
        end

        local min = 1
        local max = #arg
        for k, v in pairs(obj) do
            path:push(k)
            local err = schema.Integer(k, path)
            if not err then
                err = schema.checkSchema(v, arg[k], path)
                if err then
                    AddError(err)
                end
            else
                AddError(schema.error("Invalid tuple key", path, err))
            end
            path:pop()
        end
        return errmsg
    end
    return CheckTuple
end

-- Builds a conditional type schema, i.e. a schema that depends on the value of
-- another value. The dependence must be *local*, i.e. defined in the same
-- table. Use as in
--   Case("name", {"Peter", schema1}, {"Mary", schema2}, {OneOf(...), schema3})
-- This will check the field "name" against every schema in the first component
-- and will return the second component of the first match.
function schema.case(relativePath, ...)
    if type(relativePath) ~= "table" then
        relativePath = schema.Path("..", relativePath)
    end
    local cases = {...}
    for k,v in ipairs(cases) do
        if type(v) ~= "table" then
            error("Cases expects inputs of the form {conditionSchema, schema}; argument "..v.." is invalid")
        end
    end

    local function checkCase(obj, path)
        local condPath = path:copy()
        for k=0, #relativePath do
            local s = relativePath:get(k)
            if s == ".." then
                condPath:pop()
            else
                condPath:push(s)
            end
        end

        local errmsg = nil
        local function AddError(msg)
            if errmsg == nil then
                errmsg = msg
            else
                errmsg = errmsg:append(msg)
            end
        end

        local anyCond = false
        local condObj = condPath:target()
        for k,v in ipairs(cases) do
            local condSchema = v[1]
            local valSchema = v[2]
            local condErr = schema.checkSchema(condObj, condSchema, condPath)
            if not condErr then
                anyCond = true
                local err = schema.checkSchema(obj, valSchema, path)
                if err then
                    AddError(schema.error("Case failed: Condition "..k.." of '"..path.."' holds but the consequence does not", path, err))
                end
            end
        end

        if not anyCond then
            AddError(schema.error("Case failed: No condition on '"..path.."' holds"))
        end

        return errmsg
    end
    return CheckCase
end

function schema.test(fn, msg)
    local function CheckTest(obj, path)
        local pok, ok = pcall(fn, obj)
        if pok and ok then
            return nil
        else
            return schema.error("Invalid value: '"..path..(msg and "': "..msg or ""), path)
        end
    end
    return CheckTest
end

return schema
