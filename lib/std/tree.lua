--[[--
 Tree container prototype.

 Note that Functions listed below are only available from the Tree
 prototype return by requiring this module, because Container objects
 cannot have object methods.

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> Container
                 `-> Tree

 @classmod std.tree
 @see std.container
]]

local base      = require "std.base"
local operator  = require "std.operator"

local Container = require "std.container" {}

local ielems, ipairs, base_leaves, pairs, prototype =
  base.ielems, base.ipairs, base.leaves, base.pairs, base.prototype
local last, len = base.last, base.len
local reduce = base.reduce

local Tree -- forward declaration



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Tree iterator.
-- @tparam function it iterator function
-- @tparam tree|table tr tree or tree-like table
-- @treturn string type ("leaf", "branch" (pre-order) or "join" (post-order))
-- @treturn table path to node (`{i1, ...in}`)
-- @treturn node node
local function _nodes (it, tr)
  local p = {}
  local function visit (n)
    if type (n) == "table" then
      coroutine.yield ("branch", p, n)
      for i, v in it (n) do
        p[#p + 1] = i
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



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Tree iterator which returns just numbered leaves, in order.
-- @static
-- @function ileaves
-- @tparam Tree|table tr tree or tree-like table
-- @treturn function iterator function
-- @treturn Tree|table the tree *tr*
-- @see inodes
-- @see leaves
-- @usage
-- --> t = {"one", "three", "five"}
-- for leaf in ileaves {"one", {two=2}, {{"three"}, four=4}}, foo="bar", "five"}
-- do
--   t[#t + 1] = leaf
-- end
local function ileaves (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'ileaves' (table expected, got " .. type (tr) .. ")")
  return base_leaves (ipairs, tr)
end


--- Tree iterator which returns just leaves.
-- @static
-- @function leaves
-- @tparam Tree|table tr tree or tree-like table
-- @treturn function iterator function
-- @treturn Tree|table the tree, *tr*
-- @see ileaves
-- @see nodes
-- @usage
-- for leaf in leaves {"one", {two=2}, {{"three"}, four=4}}, foo="bar", "five"}
-- do
--   t[#t + 1] = leaf
-- end
-- --> t = {2, 4, "five", "foo", "one", "three"}
-- table.sort (t, lambda "=tostring(_1) < tostring(_2)")
local function leaves (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'leaves' (table expected, got " .. type (tr) .. ")")
  return base_leaves (pairs, tr)
end


--- Make a deep copy of a tree, including any metatables.
-- @tparam Tree|table tr tree or tree-like table
-- @tparam boolean nometa if non-`nil` don't copy metatables
-- @treturn Tree|table a deep copy of *tr*
-- @see std.table.clone
-- @usage
-- tr = {"one", {two=2}, {{"three"}, four=4}}
-- copy = clone (tr)
-- copy[2].two=5
-- assert (tr[2].two == 2)
local function clone (tr, nometa)
  assert (type (tr) == "table",
          "bad argument #1 to 'clone' (table expected, got " .. type (tr) .. ")")
  local r = {}
  if not nometa then
    setmetatable (r, getmetatable (tr))
  end
  local d = {[tr] = r}
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
  return copy (r, tr)
end


--- Tree iterator over all nodes.
--
-- The returned iterator function performs a depth-first traversal of
-- `tr`, and at each node it returns `{node-type, tree-path, tree-node}`
-- where `node-type` is `branch`, `join` or `leaf`; `tree-path` is a
-- list of keys used to reach this node, and `tree-node` is the current
-- node.
--
-- Note that the `tree-path` reuses the same table on each iteration, so
-- you must `table.clone` a copy if you want to take a snap-shot of the
-- current state of the `tree-path` list before the next iteration
-- changes it.
-- @tparam Tree|table tr tree or tree-like table to iterate over
-- @treturn function iterator function
-- @treturn Tree|table the tree, *tr*
-- @see inodes
-- @usage
-- -- tree = +-- node1
-- --        |    +-- leaf1
-- --        |    '-- leaf2
-- --        '-- leaf 3
-- tree = Tree { Tree { "leaf1", "leaf2"}, "leaf3" }
-- for node_type, path, node in nodes (tree) do
--   print (node_type, path, node)
-- end
-- --> "branch"   {}      {{"leaf1", "leaf2"}, "leaf3"}
-- --> "branch"   {1}     {"leaf1", "leaf"2")
-- --> "leaf"     {1,1}   "leaf1"
-- --> "leaf"     {1,2}   "leaf2"
-- --> "join"     {1}     {"leaf1", "leaf2"}
-- --> "leaf"     {2}     "leaf3"
-- --> "join"     {}      {{"leaf1", "leaf2"}, "leaf3"}
-- os.exit (0)
local function nodes (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'nodes' (table expected, got " .. type (tr) .. ")")
  return _nodes (pairs, tr)
end


--- Tree iterator over numbered nodes, in order.
--
-- The iterator function behaves like @{nodes}, but only traverses the
-- array part of the nodes of *tr*, ignoring any others.
-- @tparam Tree|table tr tree or tree-like table to iterate over
-- @treturn function iterator function
-- @treturn tree|table the tree, *tr*
-- @see nodes
local function inodes (tr)
  assert (type (tr) == "table",
          "bad argument #1 to 'inodes' (table expected, got " .. type (tr) .. ")")
  return _nodes (ipairs, tr)
end


--- Destructively deep-merge one tree into another.
-- @tparam Tree|table tr destination tree or table
-- @tparam Tree|table ur tree or table with nodes to merge
-- @treturn Tree|table *tr* with nodes from *ur* merged in
-- @see std.table.merge
-- @usage
-- merge (dest, {{exists=1}, {{not = {present = { inside = "dest" }}}}})
local function merge (tr, ur)
  assert (type (tr) == "table",
          "bad argument #1 to 'merge' (table expected, got " .. type (tr) .. ")")
  assert (type (ur) == "table",
          "bad argument #2 to 'merge' (table expected, got " .. type (ur) .. ")")
  for ty, p, n in nodes (ur) do
    if ty == "leaf" then
      tr[p] = n
    end
  end
  return tr
end



--[[ ============ ]]--
--[[ Tree Object. ]]--
--[[ ============ ]]--


--- Tree prototype object.
-- @object Tree
-- @string[opt="Tree"] _type object name
Tree = Container {
  _type = "Tree",

  --- Deep retrieval.
  -- @static
  -- @function __index
  -- @tparam Tree tr a tree
  -- @param i non-table, or list of keys `{i1, ...i_n}`
  -- @return `tr[i1]...[i_n]` if *i* is a key list, `tr[i]` otherwise
  -- @todo the following doesn't treat list keys correctly
  --       e.g. tr[{{1, 2}, {3, 4}}], maybe flatten first?
  -- @usage
  -- del_other_window = keymap[{"C-x", "4", KEY_DELETE}]
  __index = function (tr, i)
    if prototype (i) == "table" then
      return reduce (operator.deref, tr, ielems, i)
    else
      return rawget (tr, i)
    end
  end,

  --- Deep insertion.
  -- @static
  -- @function __newindex
  -- @tparam Tree tr a tree
  -- @param i non-table, or list of keys `{i1, ...i_n}`
  -- @param v value
  -- @usage
  -- function bindkey (keylist, fn) keymap[keylist] = fn end
  __newindex = function (tr, i, v)
    if prototype (i) == "table" then
      for n = 1, len (i) - 1 do
        if prototype (tr[i[n]]) ~= "Tree" then
          rawset (tr, i[n], Tree {})
        end
        tr = tr[i[n]]
      end
      rawset (tr, last (i), v)
    else
      rawset (tr, i, v)
    end
  end,

  --- @export
  _functions = {
    clone   = clone,
    ileaves = ileaves,
    inodes  = inodes,
    leaves  = leaves,
    merge   = merge,
    nodes   = nodes,
  },
}

return Tree
