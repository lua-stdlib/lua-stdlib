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

local base  = require "std.base"
local debug = require "std.debug"

local ipairs, pairs, okeys = base.ipairs, base.pairs, base.okeys
local insert, len, maxn = base.insert, base.len, base.maxn
local okeys, prototype, tostring = base.okeys, base.prototype, base.tostring
local argcheck = debug.argcheck



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
  if getmetatable (fn) == ModuleFunction then
    -- Don't double wrap!
    return fn
  else
    return setmetatable ({_type = "modulefunction", call = fn}, ModuleFunction)
  end
end



--[[ ================= ]]--
--[[ Container Object. ]]--
--[[ ================= ]]--


local function mapfields (obj, src, map)
  local mt = getmetatable (obj) or {}

  -- Map key pairs.
  -- Copy all pairs when `map == nil`, but discard unmapped src keys
  -- when map is provided (i.e. if `map == {}`, copy nothing).
  if map == nil or next (map) then
    map = map or {}
    local k, v = next (src)
    while k do
      local key, dst = map[k] or k, obj
      local kind = type (key)
      if kind == "string" and key:sub (1, 1) == "_" then
        mt[key] = v
      elseif next (map) and kind == "number" and len (dst) + 1 < key then
        -- When map is given, but has fewer entries than src, stop copying
        -- fields when map is exhausted.
        break
      else
        dst[key] = v
      end
      k, v = next (src, k)
    end
  end

  -- Quicker to remove this after copying fields than test for it
  -- it on every iteration above.
  mt._functions = nil

  -- Inject module functions.
  local t = src._functions or {}
  local k, v = next (t)
  while (k) do
    obj[k] = modulefunction (v)
    k, v = next (t, k)
  end

  -- Only set non-empty metatable.
  if next (mt) then
    setmetatable (obj, mt)
  end
  return obj
end


local function __call (self, x, ...)
  local mt     = getmetatable (self)
  local obj_mt = mt
  local obj    = {}

  -- This is the slowest part of cloning for any objects that have
  -- a lot of fields to test and copy.  If you need to clone a lot of
  -- objects from a prototype with several module functions, it's much
  -- faster to clone objects from each other than the prototype!
  local k, v = next (self)
  while (k) do
    if type (v) ~= "table" or v._type ~= "modulefunction" then
      obj[k] = v
    end
    k, v = next (self, k)
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


local function X (decl, fn)
  return debug.argscheck ("std.container." .. decl, fn)
end

local M = {
  mapfields = X ("mapfields (table, table|object, ?table)", mapfields),
}


if _DEBUG.argcheck then

  local argerror, extramsg_toomany = debug.argerror, debug.extramsg_toomany

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
        argerror (name, 2, extramsg_toomany ("argument", 1, 1 + maxn (argt)), 2)
      end
    end

    return __call (self, x, ...)
  end

else

  M.__call = __call

end


function M.__tostring (self)
  local n, k_ = 1, nil
  local buf = { prototype (self), " {" }	-- pre-buffer object open
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
  __pairs    = M.__pairs,
})
