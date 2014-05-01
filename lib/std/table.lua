--[[--
 Extensions to the table module.
 @module std.table
]]

local base = require "std.base"


local M -- forward declaration

-- No need to pull all of std.list into memory.
local elems = base.elems


--- Merge one table's fields into another.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @tparam boolean nometa if non-nil don't copy metatable
-- @return table   `t` with fields from `u` merged in
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
  for k in elems (keys) do
    t[k] = u[k]
  end
  return t
end


--- Make a shallow copy of a table, including any metatable.
--
-- To make deep copies, use @{std.tree.clone}.
-- @tparam table t source table
-- @tparam[opt={}] table map table of `{old_key=new_key, ...}`
-- @tparam boolean nometa if non-nil don't copy metatable
-- @return copy of *t*, also sharing *t*'s metatable unless *nometa*
--   is true, and with keys renamed according to *map*
local function clone (t, map, nometa)
  assert (type (t) == "table",
          "bad argument #1 to 'clone' (table expected, got " .. type (t) .. ")")
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
-- @return copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
local function clone_select (t, keys, nometa)
  assert (type (t) == "table",
          "bad argument #1 to 'clone_select' (table expected, got " .. type (t) .. ")")
  return merge_namedfields ({}, t, keys, nometa)
end


--- Return whether table is empty.
-- @tparam table t any table
-- @return `true` if `t` is empty, otherwise `false`
local function empty (t)
  return not next (t)
end


--- Invert a table.
-- @tparam  table t a table with `{k=v, ...}`
-- @treturn table   inverted table `{v=k, ...}`
local function invert (t)
  local i = {}
  for k, v in pairs (t) do
    i[v] = k
  end
  return i
end


--- Make the list of keys in table.
-- @tparam  table t any table
-- @treturn table   list of keys
local function keys (t)
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
-- @tparam boolean nometa if non-nil don't copy metatable
-- @return table   `t` with fields from `u` merged in
local function merge (t, u, map, nometa)
  assert (type (t) == "table",
          "bad argument #1 to 'merge' (table expected, got " .. type (t) .. ")")
  assert (type (u) == "table",
          "bad argument #2 to 'merge' (table expected, got " .. type (u) .. ")")
  return merge_allfields (t, u, map, nometa)
end


--- Destructively merge another table's named fields into *table*.
--
-- Like `merge`, but does not merge any fields by default.
-- @tparam table t destination table
-- @tparam table u table with fields to merge
-- @tparam[opt={}] table keys list of keys to copy
-- @tparam boolean nometa if non-nil don't copy metatable
-- @return copy of fields in *selection* from *t*, also sharing *t*'s
--   metatable unless *nometa*
local function merge_select (t, u, keys, nometa)
  assert (type (t) == "table",
          "bad argument #1 to 'merge_select' (table expected, got " .. type (t) .. ")")
  assert (type (u) == "table",
          "bad argument #2 to 'merge_select' (table expected, got " .. type (u) .. ")")
  return merge_namedfields (t, u, keys, nometa)
end


--- Return given metamethod, if any, or nil.
-- @function metamethod
-- @param x object to get metamethod of
-- @param n name of metamethod to get
-- @return metamethod function or nil if no metamethod or not a
-- function
local metamethod = base.metamethod


--- Make a table with a default value for unset keys.
-- @param         x default entry value (default: `nil`)
-- @tparam  table t initial table (default: `{}`)
-- @treturn table   table whose unset elements are x
local function new (x, t)
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
-- @tparam  table    t any table
-- @treturn function   iterator function
-- @treturn table      the table, `t`
-- @treturn  number    `#t + 1`
local function ripairs (t)
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
-- @return number of non-nil values in `t`
local function size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end


-- Preserve core table sort function.
local _sort = table.sort

--- Make table.sort return its result.
-- @tparam table    t unsorted table
-- @tparam function c comparator function
-- @return `t` with keys sorted accordind to `c`
local function sort (t, c)
  _sort (t, c)
  return t
end


--- Overwrite core methods with `std` enhanced versions.
--
-- Replaces core `table.sort` with `std.table` version.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
local function monkey_patch (namespace)
  namespace = namespace or _G
  assert (type (namespace) == "table",
          "bad argument #1 to 'monkey_patch' (table expected, got " .. type (namespace) .. ")")

  namespace.table.sort = sort
  return M
end


--- Turn an object into a table according to __totable metamethod.
-- @tparam  std.object x object to turn into a table
-- @treturn table resulting table or `nil`
local function totable (x)
  local m = metamethod (x, "__totable")
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
-- @tparam  table t any table
-- @treturn table   list of values
local function values (t)
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
