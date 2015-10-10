--[[--
 Container prototype.

 This module supplies the root prototype object from which every other
 object is descended.  There are no classes as such, rather new objects
 are created by cloning an existing object, and then changing or adding
 to the clone. Further objects can then be made by cloning the changed
 object, and so on.

 The functionality of a container based object is entirely defined by its
 *meta*methods. However, since we can store *any* object in a container,
 we cannot rely on the `__index` metamethod, because it is only a
 fallback for when that key is not already in the container itself. Of
 course that does not entirely preclude the use of `__index` with
 containers, so long as this limitation is observed.

 When making your own prototypes, derive from @{std.container.prototype}
 if you want to access the contents of your containers with the `[]`
 operator, otherwise from @{std.object.prototype} if you want to access
 the functionality of your objects with named object methods.

 Prototype Chain
 ---------------

      table
       `-> Container

 @prototype std.container
]]

local getmetatable	= getmetatable
local next		= next
local select		= select
local setmetatable	= setmetatable
local type		= type

local string_find	= string.find
local string_sub	= string.sub
local table_concat	= table.concat


local _ = {
  debug_init		= require "std.debug_init",
  std			= require "std.base",
  strict		= require "std.strict",
  typing		= require "std.typing",
}

local Module		= _.std.object.Module

local _DEBUG		= _.debug_init._DEBUG
local argcheck		= _.typing.argcheck
local argscheck		= _.typing.argscheck
local argerror		= _.typing.argerror
local copy		= _.std.base.copy
local extramsg_toomany	= _.typing.extramsg_toomany
local mapfields		= _.std.object.mapfields
local pickle		= _.std.string.pickle
local render		= _.std.string.render
local sortkeys		= _.std.base.sortkeys

local _, _ENV		= nil, _.strict {}



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Instantiate a new object based on *proto*.
--
-- This is equivalent to:
--
--     table.merge (table.clone (proto), t or {})
--
-- Except that, by not typechecking arguments or checking for metatables,
-- it is slightly faster.
-- @tparam table proto base object to copy from
-- @tparam[opt={}] table t additional fields to merge in
-- @treturn table a new table with fields from proto and t merged in.
local function instantiate (proto, t)
  local obj = {}
  local k, v = next (proto)
  while k do
    obj[k] = v
    k, v = next (proto, k)
  end

  t = t or {}
  k, v = next (t)
  while k do
    obj[k] = v
    k, v = next (t, k)
  end
  return obj
end


local tostring_vtable = {
  pair = function (x, kp, vp, k, v, kstr, vstr)
    if k == 1 or type (k) == "number" and k -1 == kp then return vstr end
    return kstr .. "=" .. vstr
  end,

  sep = function (x, kp, vp, kn, vn)
    if kp == nil or kn == nil then return "" end
    if type (kp) == "number" and kn ~= kp + 1 then return "; " end
    return ", "
  end,

  sort = sortkeys,
}



--[[ ================= ]]--
--[[ Container Object. ]]--
--[[ ================= ]]--


--- Container prototype.
-- @object prototype
-- @string[opt="Container"] _type object name
-- @tfield[opt] table|function _init object initialisation
-- @usage
-- local Container = require "std.container".prototype
-- local Graph = Container { _type = "Graph" }
-- local function nodes (graph)
--   local n = 0
--   for _ in std.pairs (graph) do n = n + 1 end
--   return n
-- end
-- local g = Graph { "node1", "node2" }
-- assert (nodes (g) == 2)
local prototype = {
  _module = "std.container",		-- for pickle()
  _type = "Container",			-- for tostring() and type()

  --- Metamethods
  -- @section metamethods

  --- Return a clone of this container and its metatable.
  --
  -- Like any Lua table, a container is essentially a collection of
  -- `field_n = value_n` pairs, except that field names beginning with
  -- an underscore `_` are usually kept in that container's metatable
  -- where they define the behaviour of a container object rather than
  -- being part of its actual contents.  In general, cloned objects
  -- also clone the behaviour of the object they cloned, unless...
  --
  -- When calling @{std.container.prototype}, you pass a single table
  -- argument with additional fields (and values) to be merged into the
  -- clone. Any field names beginning with an underscore `_` are copied
  -- to the clone's metatable, and all other fields to the cloned
  -- container itself.  For instance, you can change the name of the
  -- cloned object by setting the `_type` field in the argument table.
  --
  -- The `_init` private field is also special: When set to a sequence of
  -- field names, unnamed fields in the call argument table are assigned
  -- to those field names in subsequent clones, like the example below.
  --
  -- Alternatively, you can set the `_init` private field of a cloned
  -- container object to a function instead of a sequence, in which case
  -- all the arguments passed when *it* is called/cloned (including named
  -- and unnamed fields in the initial table argument, if there is one)
  -- are passed through to the `_init` function, following the nascent
  -- cloned object. See the @{mapfields} usage example below.
  -- @function prototype:__call
  -- @param ... arguments to prototype's *\_init*, often a single table
  -- @treturn prototype clone of this container, with shared or
  --   merged metatable as appropriate
  -- @usage
  -- local Cons = Container {_type="Cons", _init={"car", "cdr"}}
  -- local list = Cons {"head", Cons {"tail", nil}}
  __call = function (self, ...)
    local mt     = getmetatable (self)
    local obj_mt = mt
    local obj    = {}

    -- This is the slowest part of cloning for any objects that have
    -- a lot of fields to test and copy.
    local k, v = next (self)
    while (k) do
      obj[k] = v
      k, v = next (self, k)
    end

    if type (mt._init) == "function" then
      obj = mt._init (obj, ...)
    else
      obj = (self.mapfields or mapfields) (obj, (...), mt._init)
    end

    -- If a metatable was set, then merge our fields and use it.
    if next (getmetatable (obj) or {}) then
      local new_mt = getmetatable (obj)
      local new_type = new_mt._type or ""
      local i = string_find ("." .. new_type, "%.[^%.]*$")
      if i > 1 then
	-- expand long-form type.
	new_mt._type = string_sub (new_type, i)
	new_mt._module = string_sub (new_type, 1, i -2)
      end

      -- Merge fields.
      obj_mt = instantiate (mt, getmetatable (obj))

      -- Merge object methods.
      if type (obj_mt.__index) == "table" and
        type ((mt or {}).__index) == "table"
      then
        obj_mt.__index = instantiate (mt.__index, obj_mt.__index)
      end

      -- Invalidate obsoleted _module field
      if new_mt._type ~= nil and new_mt._module == nil then
	obj_mt._module = nil
      end
    end

    return setmetatable (obj, obj_mt)
  end,


  --- Return a compact string representation of this object.
  --
  -- First the container name, and then between { and } an ordered list
  -- of the array elements of the contained values with numeric keys,
  -- followed by asciibetically sorted remaining public key-value pairs.
  --
  -- This metamethod doesn't recurse explicitly, but relies upon
  -- suitable `__tostring` metamethods for non-primitive content objects.
  -- @function prototype:__tostring
  -- @treturn string stringified object representation
  -- @see tostring
  -- @usage
  -- assert (tostring (list) == 'Cons {car="head", cdr=Cons {car="tail"}}')
  __tostring = function (self)
    return table_concat {
      -- Pass a shallow copy to render to avoid triggering __tostring
      -- again and blowing the stack.
      getmetatable (self)._type,
      " ",
      render (copy (self), tostring_vtable),
    }
  end,


  --- Return a loadable serialization of this object, where possible.
  --
  -- If the object contains an unpicklable element (e.g. a userdata with
  -- no `__pickle` metamethod) then neither is the entire container
  -- picklable, and an error will be raised.
  --
  -- Assuming the object metatable carries a correct `_module` field,
  -- (either set manually when the prototype was created, or else because
  -- the long form `_type` field was provided) that module path will be
  -- required when the pickled object is evaluated.  Otherwise, the bare
  -- `_type` string is used and you will be responsible for setting that
  -- to the correct object prototype before evaluating a pickled object.
  -- @function prototype:__pickle
  -- @treturn string pickled object representation
  -- @see std.string.pickle
  __pickle = function (self)
    local mt = getmetatable (self)
    if type (mt._module) == "string" then
      -- object with _module set
      return table_concat {
        'require "',
        mt._module,
        '".prototype ',
        pickle (copy (self)),
      }
    end
    -- rely on caller preloading `local ObjectName = require "obj".prototype`
    return table_concat {
      mt._type, " ", pickle (copy (self)),
    }
  end,
}


if _DEBUG.argcheck then
  local __call = prototype.__call

  prototype.__call = function (self, ...)
    local mt = getmetatable (self)

    -- A function initialised object can be passed arguments of any
    -- type, so only argcheck non-function initialised objects.
    if type (mt._init) ~= "function" then
      local name, n = mt._type, select ("#", ...)
      -- Don't count `self` as an argument for error messages, because
      -- it just refers back to the object being called: `prototype {"x"}.
      argcheck (name, 1, "table", (...))
      if n > 1 then
        argerror (name, 2, extramsg_toomany ("argument", 1, n), 2)
      end
    end

    return __call (self, ...)
  end
end


return Module {
  prototype = setmetatable ({}, prototype),

  --- Functions
  -- @section functions

  --- Return *new* with references to the fields of *src* merged in.
  --
  -- This is the function used to instantiate the contents of a newly
  -- cloned container, as called by @{__call} above, to split the
  -- fields of a @{__call} argument table into private "_" prefixed
  -- field namess, -- which are merged into the *new* metatable, and
  -- public (everything else) names, which are merged into *new* itself.
  --
  -- You might want to use this function from `_init` functions of your
  -- own derived containers.
  -- @function mapfields
  -- @tparam table new partially instantiated clone container
  -- @tparam table src @{__call} argument table that triggered cloning
  -- @tparam[opt={}] table map key renaming specification in the form
  --   `{old_key=new_key, ...}`
  -- @treturn table merged public fields from *new* and *src*, with a
  --   metatable of private fields (if any), both renamed according to
  --   *map*
  -- @usage
  -- local Bag = Container {
  --   _type = "Bag",
  --   _init = function (new, ...)
  --     if type (...) == "table" then
  --       return container.mapfields (new, (...))
  --     end
  --     return functional.reduce (operator.set, new, ipairs, {...})
  --   end,
  -- }
  -- local groceries = Bag ("apple", "banana", "banana")
  -- local purse = Bag {_type = "Purse"} ("cards", "cash", "id")
  mapfields = argscheck (
      "std.container.mapfields (table, table|object, ?table)", mapfields),
}
