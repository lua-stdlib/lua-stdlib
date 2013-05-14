-- Extensions to the table module

local base = require "std.base"
local func = require "std.functional"

local _sort = table.sort
--- Make table.sort return its result.
-- @param t table
-- @param c comparator function
-- @return sorted table
local function sort (t, c)
  _sort (t, c)
  return t
end

--- Return whether table is empty.
-- @param t table
-- @return <code>true</code> if empty or <code>false</code> otherwise
local function empty (t)
  return not next (t)
end

--- Turn a tuple into a list.
-- @param ... tuple
-- @return list
local function pack (...)
  return {...}
end

--- Find the number of elements in a table.
-- @param t table
-- @return number of elements in t
local function size (t)
  local n = 0
  for _ in pairs (t) do
    n = n + 1
  end
  return n
end

--- Make the list of keys of a table.
-- @param t table
-- @return list of keys
local function keys (t)
  local u = {}
  for i, v in pairs (t) do
    table.insert (u, i)
  end
  return u
end

--- Make the list of values of a table.
-- @param t table
-- @return list of values
local function values (t)
  local u = {}
  for i, v in pairs (t) do
    table.insert (u, v)
  end
  return u
end

--- Invert a table.
-- @param t table <code>{i=v, ...}</code>
-- @return inverted table <code>{v=i, ...}</code>
local function invert (t)
  local u = {}
  for i, v in pairs (t) do
    u[v] = i
  end
  return u
end

--- An iterator like ipairs, but in reverse.
-- @param t table to iterate over
-- @return iterator function
-- @return the table, as above
-- @return #t + 1
local function ripairs (t)
  return function (t, n)
           n = n - 1
           if n > 0 then
             return n, t[n]
           end
         end,
  t, #t + 1
end

--- Turn an object into a table according to __totable metamethod.
-- @param x object to turn into a table
-- @return table or nil
local function totable (x)
  local m = func.metamethod (x, "__totable")
  if m then
    return m (x)
  elseif type (x) == "table" then
    return x
  else
    return nil
  end
end

--- Make a table with a default value for unset keys.
-- @param x default entry value (default: <code>nil</code>)
-- @param t initial table (default: <code>{}</code>)
-- @return table whose unset elements are x
local function new (x, t)
  return setmetatable (t or {},
                       {__index = function (t, i)
                                    return x
                                  end})
end

local M = {
  clone        = base.clone,
  clone_rename = base.clone_rename,
  empty        = empty,
  invert       = invert,
  keys         = keys,
  merge        = base.merge,
  new          = new,
  pack         = pack,
  ripairs      = ripairs,
  size         = size,
  sort         = sort,
  totable      = totable,
  values       = values,

  -- Core Lua table.sort function.
  _sort        = _sort,
}

for k, v in pairs (table) do
  M[k] = M[k] or v
end

return M
