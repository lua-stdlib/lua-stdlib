--[[--
 Prototype-based objects.

 This module creates the root prototype object from which every other
 object is descended.  There are no classes as such, rather new objects
 are created by cloning an existing prototype object, and then changing
 or adding to it. Further objects can then be made by cloning the changed
 object, and so on.

 Objects are cloned by simply calling an existing object which then
 serves as a prototype, from which the new object is copied.

 All valid objects contain a field `_init`, which determines the syntax
 required to execute the cloning process:

   1. `_init` can be a list of keys; then the unnamed `init_1` through
      `init_n` values from the argument table are assigned to the
      corresponding keys in `new_object`;

         new_object = prototype {
           init_1, ..., init_m;
           field_1 = value_1,
           ...
           field_n = value_n,
         }

   2. Or it can be a function, in which the arguments passed to the
      prototype during cloning are simply handed to the `_init` function:

        new_object = prototype (value, ...)

 Field names beginning with "_" are *private*, and moved into the object
 metatable during cloning. Unless `new_object` changes the metatable this
 way, then it will share a metatable with `prototype` for efficiency.

 Objects, then, are essentially tables of `field\_n = value\_n` pairs:

   * Access an object field: `object.field`
   * Call an object method: `object:method (...)`
   * Call a "class" method: `Class.method (object, ...)`
   * Add a field: `object.field = x`
   * Add a method: `function object:method (...) ... end`

 @classmod std.object
]]

local base = require "std.base"

-- Return the named entry from x's metatable, if any, else nil.
local function metaentry (x, n)
  local ok, f = pcall (function (x)
                        return getmetatable (x)[n]
                       end,
                       x)
  if not ok then f = nil end
  return f
end


--- Return the extended object type, if any, else primitive type.
--
-- It's conventional to organise similar objects according to a string
-- valued `_type` field, which can then be queried using this function.
--
--     Stack = Object {
--       _type = "Stack",
--
--       __tostring = function (self) ... end,
--
--       __index = {
--         push = function (self) ... end,
--         pop  = function (self) ... end,
--       },
--     }
--     stack = Stack {}
--
--     stack:type () --> "Stack"
--
-- @function type
-- @tparam   std.object o  an object
-- @treturn string         type of the object
local function object_type (o)
  local _type = metaentry (o, "_type")
  if type (o) == "table" and _type ~= nil then
    return _type
  end
  return type (o)
end


--- Clone an object.
--
-- Prototypes are cloned by calling directly as described above, so this
-- `clone` method is rarely used explicitly.
-- @tparam  std.object prototype source object
-- @param              ...       arguments
-- @treturn std.object           a clone of `prototype`, adjusted
-- according to the rules above, and sharing a metatable where possible.
local function clone (prototype, ...)
  local mt = getmetatable (prototype)

  -- Make a shallow copy of prototype.
  local object = {}
  for k, v in pairs (prototype) do
    object[k] = v
  end

  -- Map arguments according to _init metamethod.
  local _init = metaentry (prototype, "_init")
  if type (_init) == "table" then
    base.merge (object, base.clone_rename (_init, ...))
  else
    object = _init (object, ...)
  end

  -- Extract any new fields beginning with "_".
  local object_mt = {}
  for k, v in pairs (object) do
    if type (k) == "string" and k:sub (1, 1) == "_" then
      object_mt[k], object[k] = v, nil
    end
  end

  if next (object_mt) == nil then
    -- Reuse metatable if possible
    object_mt = getmetatable (prototype)
  else

    -- Otherwise copy the prototype metatable...
    local t = {}
    for k, v in pairs (mt) do
      t[k] = v
    end
    -- ...but give preference to "_" prefixed keys from init table
    object_mt = base.merge (t, object_mt)

    -- ...and merge object methods from prototype too.
    if mt then
      if type (object_mt.__index) == "table" and type (mt.__index) == "table" then
        local methods = base.clone (object_mt.__index)
        for k, v in pairs (mt.__index) do
          methods[k] = methods[k] or v
        end
        object_mt.__index = methods
      end
    end
  end

  return setmetatable (object, object_mt)
end


--- Return a stringified version of the contents of object.
--
-- First the object type, and then between { and } a list of the array
-- part of the object table (without numeric keys) followed by the
-- remaining key-value pairs.
--
-- This function doesn't recurse explicity, but relies upon suitable
-- `__tostring` metamethods in contained objects.
--
-- @function tostring
-- @tparam  std.object o  an object
-- @treturn string        stringified object representation
local function stringify (o)
  local totable = getmetatable (o).__totable
  local array = base.clone (totable (o), "nometa")
  local other = base.clone (array, "nometa")
  local s = ""
  if #other > 0 then
    for i in ipairs (other) do other[i] = nil end
  end
  for k in pairs (other) do array[k] = nil end
  for i, v in ipairs (array) do array[i] = tostring (v) end

  local keys, dict = {}, {}
  for k in pairs (other) do table.insert (keys, k) end
  table.sort (keys, function (a, b) return tostring (a) < tostring (b) end)
  for _, k in ipairs (keys) do
    table.insert (dict, tostring (k) .. "=" .. tostring (other[k]))
  end

  if #array > 0 then
    s = s .. table.concat (array, ", ")
    if next (dict) ~= nil then s = s .. "; " end
  end
  if #dict > 0 then
    s = s .. table.concat (dict, ", ")
  end

  return metaentry (o, "_type") .. " {" .. s .. "}"
end


--- Return a new table with a shallow copy of all non-private fields
-- in object.
--
-- Where private fields have keys prefixed with "_".
-- @tparam  std.object o  an object
-- @treturn table         raw (non-object) table of object fields
local function totable (o)
  local t = {}
  for k, v in pairs (o) do
    if type (k) ~= "string" or k:sub (1, 1) ~= "_" then
      t[k] = v
    end
  end
  return t
end


-- Metatable for objects
-- Normally a cloned object will share its metatable with its prototype,
-- unless some new fields for the cloned object begin with '_', in which
-- case they are merged into a copy of the prototype metatable to form
-- a new metatable for the cloned object (and its clones).
local metatable = {
  _type  = "Object",
  _init  = {},

  ------
  -- Return a shallow copy of non-private object fields.
  --
  -- This pseudo-metamethod is used during object cloning to make the
  -- intial new object table, and can be overridden in other objects
  -- for greater control of which fields are considered non-private.
  -- @metamethod __totable
  -- @see totable
  __totable  = totable,

  ------
  -- Return a string representation of *object*.
  -- @metamethod __tostring
  -- @see tostring
  __tostring = stringify,

  --- @export
  __index    = {
    clone    = clone,
    tostring = stringify,
    totable  = totable,
    type     = object_type,
  },

  -- Sugar instance creation
  __call = function (self, ...)
    return self:clone (...)
  end,
}

return setmetatable ({}, metatable)
