--[[--
 Extensions to the core table module.

 The module table returned by `std.table` also contains all of the entries from
 the core table module.  An hygienic way to import this module, then, is simply
 to override the core `table` locally:

    local table = require "std.table"

 @module std.table
]]


local base = require "std.base"

local export, getmetamethod, lambda, ielems =
      base.export, base.getmetamethod, base.lambda, base.ielems


local M = { "std.table" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Merge one table's fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @param nometa if non-nil don't copy metatable
-- @treturn table *t* with fields from *u* merged in
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
-- @param nometa if non-nil don't copy metatable
-- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
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



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Make a shallow copy of a table, including any metatable.
--
-- To make deep copies, use @{tree.clone}.
-- @function clone
-- @tparam table t source table
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @bool[opt] nometa if non-nil don't copy metatable
-- @return copy of *t*, also sharing *t*'s metatable unless *nometa*
--   is true, and with keys renamed according to *map*
-- @see merge
-- @see clone_select
-- @usage
-- shallowcopy = clone (original, {rename_this = "to_this"}, ":nometa")
local clone = export (M, "clone (table, [table], boolean|:nometa?)",
  function (...) return merge_allfields ({}, ...) end)


-- DEPRECATED: Remove in first release following 2015-04-15.
-- Clone a table, renaming some keys.
-- @function clone_rename
-- @tparam table map table `{old_key=new_key, ...}`
-- @tparam table t   source table
-- @treturn table copy of *t*
M.clone_rename = base.deprecate (function (map, t)
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
-- @bool[opt] nometa if non-nil don't copy metatable
-- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
-- @see clone
-- @see merge_select
-- @usage
-- partialcopy = clone_select (original, {"this", "and_this"}, true)
export (M, "clone_select (table, [table], boolean|:nometa?)",
  function (...) return merge_namedfields ({}, ...) end)


--- An iterator over all values of a table.
-- @function elems
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn table *t*
-- @treturn boolean `true`
-- @usage for func in elems (_G) do ... end
export (M, "elems (table)", function (t)
  local k, v = nil
  return function (t)
           k, v = next (t, k)
           if k then
             return v
           end
         end,
  t, true
end)


--- Return whether table is empty.
-- @function empty
-- @tparam table t any table
-- @treturn boolean `true` if *t* is empty, otherwise `false`
-- @usage if empty (t) then error "ohnoes" end
export (M, "empty (table)", function (t)
  return not next (t)
end)


--- An iterator over the integer keyed elements of a table.
-- @function ielems
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn table *t*
-- @treturn boolean `true`
-- @usage for value in ielems {"a", "b", "c"} do ... end
export (M, "ielems (table)", ielems)


--- Invert a table.
-- @function invert
-- @tparam table t a table with `{k=v, ...}`
-- @treturn table inverted table `{v=k, ...}`
-- @usage values = invert (t)
export (M, "invert (table)", function (t)
  local i = {}
  for k, v in pairs (t) do
    i[v] = k
  end
  return i
end)


--- Make the list of keys in table.
-- @function keys
-- @tparam table t a table
-- @treturn table list of keys from *t*
-- @see values
-- @usage globals = keys (_G)
export (M, "keys (table)", function (t)
  local l = {}
  for k, _ in pairs (t) do
    l[#l + 1] = k
  end
  return l
end)


--- Destructively merge another table's fields into another.
-- @function merge
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @bool[opt] nometa if `true` or ":nometa" don't copy metatable
-- @treturn table *t* with fields from *u* merged in
-- @see clone
-- @see merge_select
-- @usage merge (_G, require "std.debug", {say = "log"}, ":nometa")
export (M, "merge (table, table, [table], boolean|:nometa?)", merge_allfields)


--- Destructively merge another table's named fields into *table*.
--
-- Like `merge`, but does not merge any fields by default.
-- @function merge_select
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table keys list of keys to copy
-- @bool[opt] nometa if `true` or ":nometa" don't copy metatable
-- @treturn table copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
-- @see merge
-- @see clone_select
-- @usage merge_select (_G, require "std.debug", {"say"}, false)
export (M, "merge_select (table, table, [table], boolean|:nometa?)",
  merge_namedfields)


--- Return given metamethod, if any, or nil.
-- @function metamethod
-- @tparam object x object to get metamethod of
-- @string n name of metamethod to get
-- @treturn function|nil metamethod function, or `nil` if no metamethod
-- @usage lookup = metamethod (require "std.object", "__index")
export (M, "metamethod (object|table, string)", getmetamethod)


--- Make a table with a default value for unset keys.
-- @function new
-- @param[opt=nil] x default entry value
-- @tparam[opt={}] table t initial table
-- @treturn table table whose unset elements are *x*
-- @usage t = new (0)
export (M, "new (any?, table?)", function (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end)


--- Turn a tuple into a list.
-- @param ... tuple
-- @return list
function M.pack (...)
  return {...}
end


--- An iterator like ipairs, but in reverse.
-- @function ripairs
-- @tparam table t any table
-- @treturn function iterator function
-- @treturn table *t*
-- @treturn number `#t + 1`
-- @usage for i, v = ripairs (t) do ... end
export (M, "ripairs (table)", function (t)
  return function (t, n)
           n = n - 1
           if n > 0 then
             return n, t[n]
           end
         end,
  t, #t + 1
end)


--- Find the number of elements in a table.
-- @function size
-- @tparam table t any table
-- @treturn int number of non-nil values in *t*
-- @usage count = size {foo = true, bar = true, baz = false}
export (M, "size (table)", function (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end)


-- Preserve core table sort function.
local _sort = table.sort

--- Make table.sort return its result.
-- @function sort
-- @tparam table t unsorted table
-- @func[opt] c comparator function if passed, otherwise standard
--   lua `<` operator
-- @return *t* with keys sorted accordind to *c*
-- @usage table.concat (sort (object))
export (M, "sort (table, function?)", function (t, c)
  c = type (c) == "string" and lambda (c).call or c

  _sort (t, c)
  return t
end)


--- Overwrite core methods with `std` enhanced versions.
--
-- Replaces core `table.sort` with `std.table` version.
-- @function monkey_patch
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
-- @usage local table = require "std.table".monkey_patch ()
export (M, "monkey_patch (table?)", function (namespace)
  namespace.table.sort = M.sort
  return M
end)


--- Turn an object into a table according to `__totable` metamethod.
-- @function totable
-- @tparam object|table|string x object to turn into a table
-- @treturn table resulting table or `nil`
-- @usage print (table.concat (totable (object)))
export (M, "totable (object|table|string)", function (x)
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
end)


--- Make the list of values of a table.
-- @function values
-- @tparam table t any table
-- @treturn table list of values in *t*
-- @see keys
export (M, "values (table)", function (t)
  local l = {}
  for _, v in pairs (t) do
    l[#l + 1] = v
  end
  return l
end)


for k, v in pairs (table) do
  M[k] = M[k] or v
end

return M
