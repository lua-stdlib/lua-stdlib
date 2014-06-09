--[[--
 Extensions to the core table module.

 The module table returned by `std.io` also contains all of the entries from
 the core table module.  An hygienic way to import this module, then, is simply
 to override the core `table` locally:

    local table = require "std.table"

 @module std.table
]]

local _ARGCHECK = require "std.debug_init"._ARGCHECK

local base = require "std.base"


local M -- forward declaration

local argcheck, argscheck, getmetamethod, ielems =
      base.argcheck, base.argscheck, base.getmetamethod, base.ielems



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Merge one table's fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @tparam boolean nometa if non-nil don't copy metatable
-- @return table *t* with fields from *u* merged in
local function merge_allfields (t, u, map, nometa)
  map = map or {}
  if type (map) ~= "table" then
    map, nometa = {}, map
  end

  if not nometa then
    setmetatable (t, getmetatable (u))
  end
  for k, v in pairs (u) do
    t[map[k] or k] = v
  end
  return t
end


--- Merge one table's named fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table keys list of keys to copy
-- @tparam boolean nometa if non-nil don't copy metatable
-- @return copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
local function merge_namedfields (t, u, keys, nometa)
  keys = keys or {}
  if type (keys) ~= "table" then
    keys, nometa = {}, keys
  end

  if not nometa then
    setmetatable (t, getmetatable (u))
  end
  for k in ielems (keys) do
    t[k] = u[k]
  end
  return t
end



--[[ ============== ]]--
--[[ API Functions. ]]--
--[[ ============== ]]--


--- Make a shallow copy of a table, including any metatable.
--
-- To make deep copies, use @{std.tree.clone}.
-- @tparam table t source table
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @tparam[opt] boolean nometa if non-nil don't copy metatable
-- @return copy of *t*, also sharing *t*'s metatable unless *nometa*
--   is true, and with keys renamed according to *map*
-- @see std.table.merge
-- @see std.table.clone_select
-- @usage
-- shallowcopy = clone (original, {rename_this = "to_this"}, ":nometa")
local function clone (t, map, nometa)
  if _ARGCHECK then
    local types = {"table", "table", {"boolean?", ":nometa"}}
    if type (map) ~= "table" then
      types = {"table", {"table?", "boolean?", ":nometa"}}
    end
    argscheck ("std.table.clone", types, {t, map, nometa})
  end

  return merge_allfields ({}, t, map, nometa)
end


-- DEPRECATED: Remove in first release following 2015-04-15.
-- Clone a table, renaming some keys.
-- @function clone_rename
-- @tparam table map table `{old_key=new_key, ...}`
-- @tparam table t   source table
-- @return copy of *table*
local clone_rename = base.deprecate (function (map, t)
                                       local r = clone (t)
                                       for i, v in pairs (map) do
                                         r[v] = t[i]
                                         r[i] = nil
                                       end
                                       return r
                                     end, nil,
  "table.clone_rename is deprecated, use the new `map` argument to table.clone instead.")


--- Make a partial clone of a table.
--
-- Like `clone`, but does not copy any fields by default.
-- @function clone_select
-- @tparam table t source table
-- @tparam[opt={}] table keys list of keys to copy
-- @tparam[opt] boolean nometa if non-nil don't copy metatable
-- @return copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
-- @see std.table.clone
-- @see std.table.merge_select
-- @usage
-- partialcopy = clone_select (original, {"this", "and_this"}, true)
local function clone_select (t, keys, nometa)
  if _ARGCHECK then
    local types = {"table", "table", {"boolean?", ":nometa"}}
    if type (keys) ~= "table" then
      types = {"table", {"table?", "boolean?", ":nometa"}}
    end
    argscheck ("std.table.clone_select", types, {t, keys, nometa})
  end

  return merge_namedfields ({}, t, keys, nometa)
end


--- Return whether table is empty.
-- @tparam table t any table
-- @return `true` if *t* is empty, otherwise `false`
-- @usage if empty (t) then error "ohnoes" end
local function empty (t)
  argcheck ("std.table.empty", 1, "table", t)

  return not next (t)
end


--- Invert a table.
-- @tparam table t a table with `{k=v, ...}`
-- @treturn table inverted table `{v=k, ...}`
-- @usage values = invert (t)
local function invert (t)
  argcheck ("std.table.invert", 1, "table", t)

  local i = {}
  for k, v in pairs (t) do
    i[v] = k
  end
  return i
end


--- Make the list of keys in table.
-- @tparam table t any table
-- @treturn table list of keys
-- @see std.table.values
-- @usage globals = keys (_G)
local function keys (t)
  argcheck ("std.table.keys", 1, "table", t)

  local l = {}
  for k, _ in pairs (t) do
    l[#l + 1] = k
  end
  return l
end


--- Destructively merge another table's fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @tparam[opt] boolean nometa if non-nil don't copy metatable
-- @return table *t* with fields from *u* merged in
-- @see std.table.clone
-- @see std.table.merge_select
-- @usage merge (_G, require "std.debug", {say = "log"}, ":nometa")
local function merge (t, u, map, nometa)
  if _ARGCHECK then
    local types = {"table", "table", "table", {"boolean?", ":nometa"}}
    if type (map) ~= "table" then
      types = {"table", "table", {"table?", "boolean?", ":nometa"}}
    end
    argscheck ("std.table.merge", types, {t, u, map, nometa})
  end

  return merge_allfields (t, u, map, nometa)
end


--- Destructively merge another table's named fields into *table*.
--
-- Like `merge`, but does not merge any fields by default.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table keys list of keys to copy
-- @tparam[opt] boolean nometa if non-nil don't copy metatable
-- @return copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
-- @see std.table.merge
-- @see std.table.clone_select
-- @usage merge_select (_G, require "std.debug", {"say"}, false)
local function merge_select (t, u, keys, nometa)
  if _ARGCHECK then
    local types = {"table", "table", "table", {"boolean?", ":nometa"}}
    if type (keys) ~= "table" then
      types = {"table", "table", {"table?", "boolean?", ":nometa"}}
    end
    argscheck ("std.table.merge_select", types, {t, u, keys, nometa})
  end

  return merge_namedfields (t, u, keys, nometa)
end


--- Return given metamethod, if any, or nil.
-- @function metamethod
-- @tparam std.object x object to get metamethod of
-- @string n name of metamethod to get
-- @treturn function|nil metamethod function or `nil` if no metamethod or
--   not a function
-- @usage lookup = metamethod (require "std.object", "__index")
local metamethod

if _ARGCHECK then

  metamethod = function (x, n)
    argscheck ("std.table.metamethod", {{"object", "table"}, "string"}, {x, n})

    return getmetamethod (x, n)
  end

else

  -- Save a stack frame and a comparison on each call when not checking
  -- arguments.
  metamethod = getmetamethod

end


--- Make a table with a default value for unset keys.
-- @param[opt=nil] x default entry value
-- @tparam[opt={}] table t initial table
-- @treturn table table whose unset elements are x
-- @usage t = new (0)
local function new (x, t)
  argcheck ("std.table.new", 2, "table?", t)

  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end


--- Turn a tuple into a list.
-- @param ... tuple
-- @return list
local function pack (...)
  return {...}
end


--- An iterator like ipairs, but in reverse.
-- @tparam table t any table
-- @treturn function iterator function
-- @treturn table the table, *t*
-- @treturn number `#t + 1`
-- @usage for i, v = ripairs (t) do ... end
local function ripairs (t)
  argcheck ("std.table.ripairs", 1, "table", t)

  return function (t, n)
           n = n - 1
           if n > 0 then
             return n, t[n]
           end
         end,
  t, #t + 1
end


--- Find the number of elements in a table.
-- @tparam table t any table
-- @return number of non-nil values in *t*
-- @usage count = size {foo = true, bar = true, baz = false}
local function size (t)
  argcheck ("std.table.size", 1, "table", t)

  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end


-- Preserve core table sort function.
local _sort = table.sort

--- Make table.sort return its result.
-- @tparam table t unsorted table
-- @tparam[opt] function c comparator function if passed, otherwise standard
--   lua `<` operator
-- @return *t* with keys sorted accordind to *c*
-- @usage table.concat (sort (object))
local function sort (t, c)
  argscheck ("std.table.sort", {"table", "function"}, {t, c})

  _sort (t, c)
  return t
end


--- Overwrite core methods with `std` enhanced versions.
--
-- Replaces core `table.sort` with `std.table` version.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
-- @usage local table = require "std.table".monkey_patch ()
local function monkey_patch (namespace)
  argcheck ("std.table.monkey_patch", 1, "table?", namespace)
  namespace = namespace or _G

  namespace.table.sort = sort
  return M
end


--- Turn an object into a table according to `__totable` metamethod.
-- @tparam std.object x object to turn into a table
-- @treturn table resulting table or `nil`
-- @usage print (table.concat (totable (object)))
local function totable (x)
  argcheck ("std.table.totable", 1, {"object", "table", "string"}, x)

  local m = getmetamethod (x, "__totable")
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  elseif type (x) == "string" then
    local t = {}
    x:gsub (".", function (c) t[#t + 1] = c end)
    return t
  else
    return nil
  end
end


--- Make the list of values of a table.
-- @tparam table t any table
-- @treturn table list of values
-- @see std.table.keys
local function values (t)
  argcheck ("std.table.values", 1, "table", t)

  local l = {}
  for _, v in pairs (t) do
    l[#l + 1] = v
  end
  return l
end


--- @export
M = {
  clone        = clone,
  clone_select = clone_select,
  empty        = empty,
  invert       = invert,
  keys         = keys,
  merge        = merge,
  merge_select = merge_select,
  metamethod   = metamethod,
  monkey_patch = monkey_patch,
  new          = new,
  pack         = pack,
  ripairs      = ripairs,
  size         = size,
  sort         = sort,
  totable      = totable,
  values       = values,
}

-- Deprecated and undocumented.
M.clone_rename = clone_rename

for k, v in pairs (table) do
  M[k] = M[k] or v
end

return M
