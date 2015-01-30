--[[--
 Tree container prototype.

 Note that Functions listed below are only available from the Tree
 prototype returned by requiring this module, because Container objects
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

local ielems, ipairs, leaves, pairs, prototype =
  base.ielems, base.ipairs, base.leaves, base.pairs, base.prototype
local last, len = base.last, base.len
local reduce = base.reduce

local Tree -- forward declaration



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


local function clone (t, nometa)
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


local function merge (t, u)
  for ty, p, n in _nodes (pairs, u) do
    if ty == "leaf" then
      t[p] = n
    end
  end
  return t
end



--[[ ============ ]]--
--[[ Tree Object. ]]--
--[[ ============ ]]--


local function X (decl, fn)
  return require "std.debug".argscheck ("std.tree." .. decl, fn)
end


--- Tree prototype object.
-- @object Tree
-- @string[opt="Tree"] _type object name
-- @see std.container
-- @see std.object.__call
-- @usage
-- local std = require "std"
-- local Tree = std.tree {}
-- local tr = Tree {}
-- tr[{"branch1", 1}] = "leaf1"
-- tr[{"branch1", 2}] = "leaf2"
-- tr[{"branch2", 1}] = "leaf3"
-- print (tr[{"branch1"}])      --> Tree {leaf1, leaf2}
-- print (tr[{"branch1", 2}])   --> leaf2
-- print (tr[{"branch1", 3}])   --> nil
-- --> leaf1	leaf2	leaf3
-- for leaf in std.tree.leaves (tr) do
--   io.write (leaf .. "\t")
-- end
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
                return reduce (operator.get, tr, ielems, i)
              else
                return rawget (tr, i)
              end
            end,

  --- Deep insertion.
  -- @static
  -- @function __newindex
  -- @tparam Tree tr a tree
  -- @param i non-table, or list of keys `{i1, ...i_n}`
  -- @param[opt] v value
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

  _functions = {
    --- Make a deep copy of a tree, including any metatables.
    -- @static
    -- @function clone
    -- @tparam table t tree or tree-like table
    -- @tparam boolean nometa if non-`nil` don't copy metatables
    -- @treturn Tree|table a deep copy of *tr*
    -- @see std.table.clone
    -- @usage
    -- tr = {"one", {two=2}, {{"three"}, four=4}}
    -- copy = clone (tr)
    -- copy[2].two=5
    -- assert (tr[2].two == 2)
    clone = X ("clone (table, ?boolean|:nometa)", clone),

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
    ileaves = X ("ileaves (table)", function (t) return leaves (ipairs, t) end),

    --- Tree iterator over numbered nodes, in order.
    --
    -- The iterator function behaves like @{nodes}, but only traverses the
    -- array part of the nodes of *tr*, ignoring any others.
    -- @static
    -- @function inodes
    -- @tparam Tree|table tr tree or tree-like table to iterate over
    -- @treturn function iterator function
    -- @treturn tree|table the tree, *tr*
    -- @see nodes
    inodes = X ("inodes (table)", function (t) return _nodes (ipairs, t) end),

    --- Tree iterator which returns just leaves.
    -- @static
    -- @function leaves
    -- @tparam table t tree or tree-like table
    -- @treturn function iterator function
    -- @treturn table *t*
    -- @see ileaves
    -- @see nodes
    -- @usage
    -- for leaf in leaves {"one", {two=2}, {{"three"}, four=4}}, foo="bar", "five"}
    -- do
    --   t[#t + 1] = leaf
    -- end
    -- --> t = {2, 4, "five", "foo", "one", "three"}
    -- table.sort (t, lambda "=tostring(_1) < tostring(_2)")
    leaves = X ("leaves (table)", function (t) return leaves (pairs, t) end),

    --- Destructively deep-merge one tree into another.
    -- @static
    -- @function merge
    -- @tparam table t destination tree
    -- @tparam table u table with nodes to merge
    -- @treturn table *t* with nodes from *u* merged in
    -- @see std.table.merge
    -- @usage
    -- merge (dest, {{exists=1}, {{not = {present = { inside = "dest" }}}}})
    merge = X ("merge (table, table)", merge),

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
    -- @static
    -- @function nodes
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
    nodes = X ("nodes (table)", function (t) return _nodes (pairs, t) end),
  },
}

return Tree
