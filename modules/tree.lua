-- @module tree

module ("tree", package.seeall)

require "list"

-- @func new: Make a table into a tree
--   @param t: table
-- @returns
--   @param tr: tree
local metatable = {}
function new (t)
  return setmetatable (t or {}, metatable)
end

-- @func __index: Tree __index metamethod
--   @param tr: tree
--   @param i: non-table, or list of indices {i1 ... in}
-- @returns
--   @param v: tr[i]...[in] if i is a table, or tr[i] otherwise
function metatable.__index (tr, i)
  if type (i) == "table" then
    return list.foldl (op["[]"], tr, i)
  else
    return rawget (tr, i)
  end
end

-- @func __newindex: Tree __newindex metamethod
-- Sets tr[i1]...[in] = v if i is a table, or tr[i] = v otherwise
--   @param tr: tree
--   @param i: non-table, or list of indices {i1 ... in}
--   @param v: value
function metatable.__newindex (tr, i, v)
  if type (i) == "table" then
    for n = 1, #i - 1 do
      if type (tr[i[n]]) ~= "table" then
        tr[i[n]] = tree.new ()
      end
      tr = tr[i[n]]
    end
    rawset (tr, i[#i], v)
  else
    rawset (tr, i, v)
  end
end

-- @func clone: Make a deep copy of a tree, including any
-- metatables
--   @param t: table
--   @param nometa: if non-nil don't copy metatables
-- @returns
--   @param u: copy of table
function clone (t, nometa)
  local r = {}
  if not nometa then
    setmetatable (r, getmetatable (t))
  end
  local d = {[t] = r}
  local function copy (o, x)
    for i, v in pairs (x) do
      if type (v) == "table" then
        if not d[v] then
          d[v] = {}
          if not nometa then
            setmetatable (d[v], getmetatable (v))
          end
          o[i] = copy (d[v], v)
        else
          o[i] = d[v]
        end
      else
        o[i] = v
      end
    end
    return o
  end
  return copy (r, t)
end
