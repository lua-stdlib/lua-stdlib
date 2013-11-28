--[[--
 Tables as trees.
 @module std.tree
]]

local base = require "std.base"
local list = require "std.list"
local func = require "std.functional"

local metatable = {}


--- Tree iterator which returns just numbered leaves, in order.
-- @function ileaves
-- @tparam  std.tree tr tree table
-- @treturn function    iterator function
-- @treturn std.tree    the tree `tr`
local ileaves = base.ileaves


--- Tree iterator which returns just leaves.
-- @function leaves
-- @tparam  std.tree tr tree table
-- @treturn function    iterator function
-- @treturn std.tree    the tree, `tr`
local leaves = base.leaves


--- Make a table into a tree.
-- @tparam  table    t any table
-- @treturn std.tree   a new tree table
local function new (t)
  return setmetatable (t or {}, metatable)
end


--- Tree `__index` metamethod.
-- @function __index
-- @param i non-table, or list of keys `{i\_1 ... i\_n}`
-- @return `tr[i]...[i\_n]` if i is a table, or `tr[i]` otherwise
-- @todo the following doesn't treat list keys correctly
--       e.g. tr[{{1, 2}, {3, 4}}], maybe flatten first?
function metatable.__index (self, i)
  if type (i) == "table" and #i > 0 then
    return list.foldl (i, func.op["[]"], self)
  else
    return rawget (self, i)
  end
end


--- Tree `__newindex` metamethod.
--
-- Sets `tr[i\_1]...[i\_n] = v` if i is a table, or `tr[i] = v` otherwise
-- @function __newindex
-- @param i non-table, or list of keys `{i\_1 ... i\_n}`
-- @param v value
function metatable.__newindex (self, i, v)
  if type (i) == "table" then
    for n = 1, #i - 1 do
      if getmetatable (self[i[n]]) ~= metatable then
        rawset (self, i[n], new ())
      end
      self = self[i[n]]
    end
    rawset (self, i[#i], v)
  else
    rawset (self, i, v)
  end
end


--- Make a deep copy of a tree, including any metatables.
--
-- To make fast shallow copies, use @{std.table.clone}.
-- @tparam  table   t      table to be cloned
-- @tparam  boolean nometa if non-nil don't copy metatables
-- @treturn table          a deep copy of `t`
local function clone (t, nometa)
  assert (type (t) == "table",
          "bad argument #1 to 'clone' (table expected, got " .. type (t) .. ")")
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


--- Tree iterator.
-- @tparam  function it iterator function
-- @tparam  std.tree tr tree
-- @treturn string   type ("leaf", "branch" (pre-order) or "join" (post-order))
-- @treturn table    path to node ({i\_1...i\_k})
-- @return           node
local function _nodes (it, tr)
  local p = {}
  local function visit (n)
    if type (n) == "table" then
      coroutine.yield ("branch", p, n)
      for i, v in it (n) do
        table.insert (p, i)
        visit (v)
        table.remove (p)
      end
      coroutine.yield ("join", p, n)
    else
      coroutine.yield ("leaf", p, n)
    end
  end
  return coroutine.wrap (visit), tr
end


--- Tree iterator over all nodes.
--
-- The returned iterator function performs a depth-first traversal of
-- `tr`, and at each node it returns `{node-type, tree-path, tree-node}`
-- where `node-type` is `branch`, `join` or `leaf`; `tree-path` is a
-- list of keys used to reach this node, and `tree-node` is the current
-- node.
--
-- Given a `std.tree` to represent:
--
--     + root
--        +-- node1
--        |    +-- leaf1
--        |    '-- leaf2
--        '-- leaf 3
--
--     tree = std.tree { std.tree { "leaf1", "leaf2"}, "leaf3" }
--
-- A series of calls to `tree.nodes` will return:
--
--     "branch", {},    {{"leaf1", "leaf2"}, "leaf3"}
--     "branch", {1},   {"leaf1", "leaf"2")
--     "leaf",   {1,1}, "leaf1"
--     "leaf",   {1,2}, "leaf2"
--     "join",   {1},   {"leaf1", "leaf2"}
--     "leaf",   {2},   "leaf3"
--     "join",   {},    {{"leaf1", "leaf2"}, "leaf3"}
--
-- Note that the `tree-path` reuses the same table on each iteration, so
-- you must `table.clone` a copy if you want to take a snap-shot of the
-- current state of the `tree-path` list before the next iteration
-- changes it.
-- @tparam  std.tree tr tree to iterate over
-- @treturn function    iterator function
-- @treturn std.tree    the tree, `tr`
-- @see inodes
local function nodes (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'nodes' (table expected, got " .. type (tr) .. ")")
  return _nodes (pairs, tr)
end


--- Tree iterator over numbered nodes, in order.
--
-- The iterator function behaves like @{nodes}, but only traverses the
-- array part of the nodes of `tr`, ignoring any others.
-- @tparam  std.tree tr tree to iterate over
-- @treturn function    iterator function
-- @treturn std.tree    the tree, `t`
-- @see nodes
local function inodes (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'inodes' (table expected, got " .. type (tr) .. ")")
  return _nodes (ipairs, tr)
end


--- Destructively deep-merge one tree into another.
-- @tparam  std.tree t destination tree
-- @tparam  std.tree u tree with nodes to merge
-- @treturn std.tree   `t` with nodes from `u` merged in
-- @see std.table.merge
local function merge (t, u)
  assert (getmetatable (t) == metatable,
          "bad argument #1 to 'merge' (tree table expected, got " .. type (t) .. ")")
  assert (getmetatable (u) == metatable,
          "bad argument #2 to 'merge' (tree table expected, got " .. type (u) .. ")")
  for ty, p, n in nodes (u) do
    if ty == "leaf" then
      t[p] = n
    end
  end
  return t
end


--- @export
local Tree = {
  clone   = clone,
  ileaves = ileaves,
  inodes  = inodes,
  leaves  = leaves,
  merge   = merge,
  new     = new,
  nodes   = nodes,
}

return Tree
