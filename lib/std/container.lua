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

local base  = require "std.base"
local debug = require "std.debug"

local ipairs, pairs = base.ipairs, base.pairs
local insert, len, maxn = base.insert, base.len, base.maxn
local prototype = base.prototype
local argcheck  = debug.argcheck



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
  mapfields = X ("mapfields (table, table|object, table?)", mapfields),
}


if _ARGCHECK then

  local toomanyargmsg = debug.toomanyargmsg

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
        error (toomanyargmsg (name, 1, 1 + maxn (argt)), 2)
      end
    end

    return __call (self, x, ...)
  end

else

  M.__call = __call

end


function M.__pairs (self)
  local keys = {}
  local k = next (self)
  while k do
    keys[#keys + 1] = k
    k = next (self, k)
  end

  -- Sort numbers first then asciibetically
  table.sort (keys, function (a, b)
    if type (a) == "number" then
      return type (b) ~= "number" or a < b
    else
      return type (b) ~= "number" and tostring (a) < tostring (b)
    end
  end)

  local n, lenkeys = 0, #keys
  return function (t, k)
    n = n + 1
    if n <= lenkeys then
      local key = keys[n]
      return key, self[key]
    end
  end, self, nil
end


function M.__tostring (self)
  local n, ibuf, kbuf = 1, {}, {}
  for k, v in pairs (self) do
    if type (k) == "number" and k == n then
      ibuf[#ibuf + 1] = tostring (v)
      n = n + 1
    else
      kbuf[#kbuf + 1] = tostring (k) .. "=" .. tostring (v)
    end
  end

  local buf = {}
  if next (ibuf) then buf[#buf + 1] = table.concat (ibuf, ", ") end
  if next (kbuf) then buf[#buf + 1] = table.concat (kbuf, ", ") end

  return prototype (self) .. " {" .. table.concat (buf, "; ") .. "}"
end


--- Container prototype.
-- @table std.container
-- @string[opt="Container"] _type type of Container, returned by
--   @{std.object.prototype}
-- @tfield table|function _init a table of field names, or
--   initialisation function, used by @{std.object.__call}
-- @tfield[opt=nil] table _functions a table of module functions not copied
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
  __pairs    = M.__pairs,
})
