--- Prototype-based objects
-- <ul>
--   <li>Create an object/class:</li>
--   <ul>
--     <li>Either, if the <code>_init</code> field is a list:
--     <ul>
--       <li><code>object/Class = prototype {value, ...; field = value, ...}</code></li>
--       <li>Named values are assigned to the corresponding fields, and unnamed values
--       to the fields given by <code>_init</code>.</li>
--     </ul>
--     <li>Or, if the <code>_init</code> field is a function:
--     <ul>
--       <li><code>object/Class = prototype (value, ...)</code></li>
--       <li>The given values are passed as arguments to the <code>_init</code> function.</li>
--     </ul>
--     <li>An object's metatable is itself.</li>
--     <li>Private fields and methods start with "<code>_</code>".</li>
--   </ul>
--   <li>Access an object field: <code>object.field</code></li>
--   <li>Call an object method: <code>object:method (...)</code></li>
--   <li>Call a class method: <code>Class.method (object, ...)</code></li>
--   <li>Add a field: <code>object.field = x</code></li>
--   <li>Add a method: <code>function object:method (...) ... end</code></li>
-- </li>

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


-- Return the extended object type, if any, else primitive type.
local function object_type (self)
  local _type = metaentry (self, "_type")
  if type (self) == "table" and _type ~= nil then
    return _type
  end
  return type (self)
end


-- Return a new object, cloned from prototype.
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


-- Return a stringified version of the contents of object.
-- First the object type, and then between { and } a list of the array
-- part of the object table (without numeric keys) followed by the
-- remaining key-value pairs.
-- This function doesn't recurse explicity, but relies upon suitable
-- __tostring metamethods in contained objects.
local function stringify (object)
  local totable = getmetatable (object).__totable
  local array = base.clone (totable (object), "nometa")
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

  return metaentry (object, "_type") .. " {" .. s .. "}"
end


-- Return a new table with a shallow copy of all non-private fields
-- in object (private fields have keys prefixed with "_").
local function totable (object)
  local t = {}
  for k, v in pairs (object) do
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

  __totable  = totable,
  __tostring = stringify,

  -- object:method ()
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

--- Root object
-- @class functable
-- @name Object
-- @field _init constructor method or list of fields to be initialised by the
-- constructor
return setmetatable ({}, metatable)
