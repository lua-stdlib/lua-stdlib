--[[--
 Container object.

 A container is a @{std.object} with no methods.  It's functionality is
 instead defined by its *meta*methods.

 Where an Object uses the `\_\_index` metatable entry to hold object
 methods, a Container stores its contents using `\_\_index`, preventing
 it from having methods in there too.

 Although there are no actual methods, Containers are free to use
 metamethods (`\_\_index`, `\_\_sub`, etc) and, like Objects, can supply
 module functions by listing them in `\_functions`.  Also, since a
 @{std.container} is a @{std.object}, it can be passed to the
 @{std.object} module functions, or anywhere else a @{std.object} is
 expected.

 Container derived objects returned directly from a `require` statement
 may also provide module functions, which can be called only from the
 initial prototype object returned by `require`, but are **not** passed
 on to derived objects during cloning:

      > Container = require "std.container"
      > x = Container {}
      > = Container.prototype (x)
      Object
      > = x.prototype (o)
      stdin:1: attempt to call field 'prototype' (a nil value)
      ...

 To add functions like this to your own prototype objects, pass a table
 of the module functions in the `_functions` private field before
 cloning, and those functions will not be inherited by clones.

      > Container = require "std.container"
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

 When making your own prototypes, start from @{std.container} if you
 want to access the contents of your objects with the `[]` operator, or
 @{std.object} if you want to access the functionality of your objects
 with named object methods.

 @classmod std.container
]]


local base = require "std.base"
local func = require "std.functional"


--- Return the named entry from x's metatable.
-- @param x anything
-- @tparam string n name of entry
-- @return value associate with `n` in `x`'s metatable, else nil
local function metaentry (x, n)
  local ok, f = pcall (function (x)
                        return getmetatable (x)[n]
                       end,
                       x)
  if not ok then f = nil end
  return f
end


--- Filter a table with a function.
-- @tparam table t source table
-- @tparam function f a function that takes key and value arguments
--   from calling `pairs` on `t`, and returns non-`nil` for elements
--   that should be in the returned table
-- @treturn table a shallow copy of `t`, with elements removed according
--   to `f`
local function filter (t, f)
  local r = {}
  for k, v in pairs (t) do
    if f (k, v) then
      r[k] = v
    end
  end
  return r
end


local functions = {
  -- Type of this container.
  -- @static
  -- @tparam  std.container o  an container
  -- @treturn string        type of the container
  -- @see std.object.prototype
  prototype = function (o)
    local _type = metaentry (o, "_type")
    if type (o) == "table" and _type ~= nil then
      return _type
    end
    return type (o)
  end,
}


--- Container prototype.
-- @table std.container
-- @string[opt="Container"] _type type of Container, returned by
--   @{std.object.prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, used by @{__call}
-- @tfield nil|table _functions a table of module functions not copied
--   by @{std.object.__call}
local metatable = {
  _type  = "Container",
  _init  = {},
  _functions = functions,


  --- Return a clone of this container.
  -- @function __call
  -- @param ... arguments for `_init`
  -- @treturn std.container a clone of the called container.
  -- @see std.object:__call
  __call = function (self, ...)
    local mt = getmetatable (self)

    -- Make a shallow copy of prototype, skipping metatable
    -- _functions.
    local fn = mt._functions or {}
    local obj = filter (self, function (e) return not fn[e] end)

    -- Map arguments according to _init metamethod.
    local _init = metaentry (self, "_init")
    if type (_init) == "table" then
      base.merge (obj, base.clone_rename (_init, ...))
    else
      obj = _init (obj, ...)
    end

    -- Extract any new fields beginning with "_".
    local obj_mt = {}
    for k, v in pairs (obj) do
      if type (k) == "string" and k:sub (1, 1) == "_" then
        obj_mt[k], obj[k] = v, nil
      end
    end

    -- However, newly passed _functions from _init arguments are
    -- copied as prototype functions into the object.
    func.map (function (k) obj[k] = obj_mt._functions[k] end,
              pairs, obj_mt._functions or {})

    -- _functions is not propagated from prototype to clone.
    if next (obj_mt) == nil and mt._functions == nil then
      -- Reuse metatable if possible
      obj_mt = getmetatable (self)
    else

      -- Otherwise copy the prototype metatable...
      local t = filter (mt, function (e) return e ~= "_functions" end)
      -- ...but give preference to "_" prefixed keys from init table
      obj_mt = base.merge (t, obj_mt)

      -- ...and merge container methods from prototype too.
      if mt then
        if type (obj_mt.__index) == "table" and type (mt.__index) == "table" then
          local methods = base.clone (obj_mt.__index)
          for k, v in pairs (mt.__index) do
            methods[k] = methods[k] or v
          end
          obj_mt.__index = methods
        end
      end
    end

    return setmetatable (obj, obj_mt)
  end,


  --- Return a string representation of this container.
  -- @function __tostring
  -- @treturn string        stringified container representation
  -- @see std.object.__tostring
  __tostring = function (self)
    local totable = getmetatable (self).__totable
    local array = base.clone (totable (self), "nometa")
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

    return metaentry (self, "_type") .. " {" .. s .. "}"
  end,


  --- Return a table representation of this container.
  -- @function __totable
  -- @treturn table a shallow copy of non-private container fields
  -- @see std.object:__totable
  __totable  = function (self)
    return filter (self, function (e)
	                   return type (e) ~= "string" or e:sub (1, 1) ~= "_"
		         end)
  end,
}

return setmetatable (functions, metatable)
