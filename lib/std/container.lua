--[[--
 Container object.

 A container is a @{std.object} with no methods.  It's functionality is
 instead defined by its *meta*methods.

 Where an Object uses the `__index` metatable entry to hold object
 methods, a Container stores its contents using `__index`, preventing
 it from having methods in there too.

 Although there are no actual methods, Containers are free to use
 metamethods (`__index`, `__sub`, etc) and, like Objects, can supply
 module functions by listing them in `_functions`.  Also, since a
 @{std.container} is a @{std.object}, it can be passed to the
 @{std.object} module functions, or anywhere else a @{std.object} is
 expected.

 Container derived objects returned directly from a `require` statement
 may also provide module functions, which can be called only from the
 initial prototype object returned by `require`, but are **not** passed
 on to derived objects during cloning:

      > container = require "std.container"  -- module table
      > Container = container {}             -- prototype object
      > = container:prototype ()
      Object
      > = Container:prototype ()
      stdin:1: attempt to call field 'prototype' (a nil value)
      ...

 To add module functions to your own prototype containers, pass a table
 of those module functions in the `_functions` private field before
 cloning, and they will not be inherited by subsequent clones.

      > Graph = Container {
      >>   _type = "Graph",
      >>   _functions = {
      >>     nodes = function (graph)
      >>       local n = 0
      >>       for _ in pairs (graph) do n = n + 1 end
      >>       return n
      >>     end,
      >>   },
      >> }
      > g = Graph { "node1", "node2" }
      > = Graph.nodes (g)
      2
      > = g.nodes
      nil

 Cloning from the module table itself is somewhat slower than cloning
 derived objects -- due to the time spent skipping over the module
 table's `_function` entries by the clone constructor. You can avoid
 that overhead by creating an explicit *prototype object*:

     local container = require "std.container"  -- module table
     local Container = container {}             -- prototype object

 When making your own prototypes, derive from @{std.container} if you want
 to access the contents of your objects with the `[]` operator, or from
 @{std.object} if you want to access the functionality of your objects with
 named object methods.

 @classmod std.container
]]


local _ARGCHECK = require "std.debug_init"._ARGCHECK

local base = require "std.base"

local argcheck, export, prototype =
      base.argcheck, base.export, base.prototype

local M = { "std.container" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


-- Instantiate a new object based on *proto*.
--
-- This is equivalent to:
--
--     table.merge (table.clone (proto), t or {})
--
-- But, not typechecking arguments or checking for metatables, is
-- slightly faster.
-- @tparam table proto base object to copy from
-- @tparam[opt={}] table t additional fields to merge in
-- @treturn table a new table with fields from proto and t merged in.
local function instantiate (proto, t)
  local obj = {}
  for k, v in pairs (proto) do
    obj[k] = v
  end
  for k, v in pairs (t or {}) do
    obj[k] = v
  end
  return obj
end


local ModuleFunction = {
  __tostring = function (self) return tostring (self.call) end,
  __call     = function (self, ...) return self.call (...) end,
}


--- Mark a function not to be copied into clones.
--
-- It responds to `type` with `table`, but otherwise behaves like a
-- regular function.  Marking uncopied module functions in-situ like this
-- (as opposed to doing book keeping in the metatable) means that we
-- don't have to create a new metatable with the book keeping removed for
-- cloned objects, we can just share our existing metatable directly.
-- @func fn a function
-- @treturn functable a callable functable for `fn`
local function modulefunction (fn)
  return setmetatable ({_type = "modulefunction", call = fn}, ModuleFunction)
end



--[[ ================= ]]--
--[[ Container Object. ]]--
--[[ ================= ]]--


--- Return `obj` with references to the fields of `src` merged in.
-- @function mapfields
-- @static
-- @tparam table obj destination object
-- @tparam table src fields to copy into clone
-- @tparam[opt={}] table map `{old_key=new_key, ...}`
-- @treturn table *obj* with non-private fields from *src* merged, and
--   a metatable with private fields (if any) merged, both sets of keys
--   renamed according to *map*
-- @see std.object.mapfields
local mapfields = export (M, "mapfields (table, table|object, table?)",
function (obj, src, map)
  local mt = getmetatable (obj) or {}

  -- Map key pairs.
  -- Copy all pairs when `map == nil`, but discard unmapped src keys
  -- when map is provided (i.e. if `map == {}`, copy nothing).
  if map == nil or next (map) then
    map = map or {}
    for k, v in pairs (src) do
      local key, dst = map[k] or k, obj
      local kind = type (key)
      if kind == "string" and key:sub (1, 1) == "_" then
        dst = mt
      elseif kind == "number" and #dst + 1 < key then
        -- When map is given, but has fewer entries than src, stop copying
        -- fields when map is exhausted.
        break
      end
      dst[key] = v
    end
  end

  -- Quicker to remove this after copying fields than test for it
  -- it on every iteration above.
  mt._functions = nil

  -- Inject module functions.
  for k, v in pairs (src._functions or {}) do
    obj[k] = modulefunction (v)
  end

  -- Only set non-empty metatable.
  if next (mt) then
    setmetatable (obj, mt)
  end
  return obj
end)


--- Return a clone of this container.
-- @function __call
-- @param x a table if prototype `_init` is a table, otherwise first
--   argument for a function type `_init`
-- @param ... any additional arguments for `_init`
-- @treturn std.container a clone of the called container.
-- @see std.object:__call
-- @usage
-- local Container = require "std.container" {} -- not a typo!
-- local new = Container {"init", {"elements"}, 2, "insert"}
local function __call (self, x, ...)
  local mt     = getmetatable (self)
  local obj_mt = mt
  local obj    = {}

  -- This is the slowest part of cloning for any objects that have
  -- a lot of fields to test and copy.  If you need to clone a lot of
  -- objects from a prototype with several module functions, it's much
  -- faster to clone objects from each other than the prototype!
  for k, v in pairs (self) do
    if type (v) ~= "table" or v._type ~= "modulefunction" then
      obj[k] = v
    end
  end

  if type (mt._init) == "function" then
    obj = mt._init (obj, x, ...)
  else
    obj = (self.mapfields or mapfields) (obj, x, mt._init)
  end

  -- If a metatable was set, then merge our fields and use it.
  if next (getmetatable (obj) or {}) then
    obj_mt = instantiate (mt, getmetatable (obj))

    -- Merge object methods.
    if type (obj_mt.__index) == "table" and
      type ((mt or {}).__index) == "table"
    then
      obj_mt.__index = instantiate (mt.__index, obj_mt.__index)
    end
  end

  return setmetatable (obj, obj_mt)
end


if _ARGCHECK then

  local arglen, toomanyarg_fmt = base.arglen, base.toomanyarg_fmt

  M.__call = function (self, x, ...)
    local mt = getmetatable (self)

    -- A function initialised object can be passed arguments of any
    -- type, so only argcheck non-function initialised objects.
    if type (mt._init) ~= "function" then
      local name, argt = mt._type, {...}
      -- Don't count `self` as an argument for error messages, because
      -- it just refers back to the object being called: `Container {"x"}.
      argcheck (name, 1, "table", x)
      if next (argt) then
        error (string.format (toomanyarg_fmt, name, 1, 1 + arglen (argt)), 2)
      end
    end

    return __call (self, x, ...)
  end

else

  M.__call = __call

end


--- Return a string representation of this container.
-- @function __tostring
-- @treturn string stringified container representation
-- @see std.object.__tostring
-- @usage print (acontainer)
function M.__tostring (self)
  local totable = getmetatable (self).__totable
  local array = instantiate (totable (self))
  local other = instantiate (array)
  local s = ""
  if #other > 0 then
    for i in ipairs (other) do other[i] = nil end
  end
  for k in pairs (other) do array[k] = nil end
  for i, v in ipairs (array) do array[i] = tostring (v) end

  local keys, dict = {}, {}
  for k in pairs (other) do keys[#keys + 1] = k end
  table.sort (keys, function (a, b) return tostring (a) < tostring (b) end)
  for _, k in ipairs (keys) do
    dict[#dict + 1] = tostring (k) .. "=" .. tostring (other[k])
  end

  if #array > 0 then
    s = s .. table.concat (array, ", ")
    if next (dict) ~= nil then s = s .. "; " end
  end
  if #dict > 0 then
    s = s .. table.concat (dict, ", ")
  end

  return prototype (self) .. " {" .. s .. "}"
end


--- Return a table representation of this container.
-- @function __totable
-- @treturn table a shallow copy of non-private container fields
-- @see std.object:__totable
-- @usage
-- local tostring = require "std.string".tostring
-- print (totable (acontainer))
function M.__totable (self)
  local t = {}
  for k, v in pairs (self) do
    if type (k) ~= "string" or k:sub (1, 1) ~= "_" then
      t[k] = v
    end
  end
  return t
end


--- Container prototype.
-- @table std.container
-- @string[opt="Container"] _type type of Container, returned by
--   @{std.object.prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, used by @{__call}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
return setmetatable ({

  -- Normally, these are set and wrapped automatically during cloning.
  -- But, we have to bootstrap the first object, so in this one instance
  -- it has to be done manually.

  mapfields = modulefunction (M.mapfields),
  prototype = modulefunction (prototype),
}, {
  _type = "Container",

  __call     = M.__call,
  __tostring = M.__tostring,
  __totable  = M.__totable,
})
