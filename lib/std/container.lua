--[[--
 Container prototype.

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

 When making your own prototypes, derive from @{std.container} if you want
 to access the contents of your objects with the `[]` operator, or from
 @{std.object} if you want to access the functionality of your objects with
 named object methods.

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> Container

 @classmod std.container
]]


local _DEBUG = require "std.debug_init"._DEBUG

local std   = require "std.base"
local debug = require "std.debug"

local ipairs, okeys, tostring = std.ipairs, std.okeys, std.tostring



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


--[[ ================= ]]--
--[[ Container Object. ]]--
--[[ ================= ]]--


local function __call (self, ...)
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
    obj = (self.mapfields or std.mapfields) (obj, (...), mt._init)
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


local function __tostring (self)
  local n, k_ = 1, nil
  local buf = { getmetatable (self)._type, " {" }
  for _, k in ipairs (okeys (self)) do		-- for ordered public members
    local v = self[k]

    if k_ ~= nil then				-- | buffer separator
      if k ~= n and type (k_) == "number" and k_ == n - 1 then
        -- `;` separates `v` elements from `k=v` elements
        buf[#buf + 1] = "; "
      elseif k ~= nil then
	-- `,` separator everywhere else
        buf[#buf + 1] = ", "
      end
    end

    if type (k) == "number" and k == n then	-- | buffer key/value pair
      -- render initial array-like elements as just `v`
      buf[#buf + 1] = tostring (v)
      n = n + 1
    else
      -- render remaining elements as `k=v`
      buf[#buf + 1] = tostring (k) .. "=" .. tostring (v)
    end

    k_ = k -- maintain loop invariant: k_ is previous key
  end
  buf[#buf + 1] = "}"				-- buffer object close

  return table.concat (buf)			-- stringify buffer
end


--- Container prototype.
--
-- Container also inherits all the fields and methods from
-- @{std.object.Object}.
-- @object Container
-- @string[opt="Container"] _type object name
-- @see std.object
-- @see std.object.__call
-- @usage
-- local std = require "std"
-- local Container = std.container {}
--
-- local Graph = Container {
--   _type = "Graph",
--   _functions = {
--     nodes = function (graph)
--       local n = 0
--       for _ in std.pairs (graph) do n = n + 1 end
--       return n
--     end,
--   },
-- }
-- local g = Graph { "node1", "node2" }
-- --> 2
-- print (Graph.nodes (g))

local Container = {
  _type = "Container",

  __call     = __call,
  __tostring = __tostring,
}


if _DEBUG.argcheck then
  local argcheck, argerror, extramsg_toomany =
      debug.argcheck, debug.argerror, debug.extramsg_toomany

  Container.__call = function (self, ...)
    local mt = getmetatable (self)

    -- A function initialised object can be passed arguments of any
    -- type, so only argcheck non-function initialised objects.
    if type (mt._init) ~= "function" then
      local name, n = mt._type, select ("#", ...)
      -- Don't count `self` as an argument for error messages, because
      -- it just refers back to the object being called: `Container {"x"}.
      argcheck (name, 1, "table", (...))
      if n > 1 then
        argerror (name, 2, extramsg_toomany ("argument", 1, n), 2)
      end
    end

    return __call (self, ...)
  end
end


return std.Module {
  prototype = setmetatable ({}, Container),

  mapfields = debug.argscheck (
      "std.container.mapfields (table, table|object, ?table)", std.mapfields),
}
