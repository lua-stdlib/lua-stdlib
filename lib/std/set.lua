--[[--
 Set container prototype.

 Note that Functions listed below are only available from the Set
 prototype returned by requiring this module, because Container
 objects cannot have object methods.

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> Container
                 `-> Set

 @classmod std.set
 @see std.container
 ]]

local base      = require "std.base"

local Container = require "std.container" {}

local ielems, pairs, prototype = base.ielems, base.pairs, base.prototype


local Set -- forward declaration



--[[ ==================== ]]--
--[[ Primitive Functions. ]]--
--[[ ==================== ]]--


-- These functions know about internal implementatation.
-- The representation is a table whose tags are the elements, and
-- whose values are true.


local elems = base.pairs


local function insert (set, e)
  return rawset (set, e, true)
end


local function member (set, e)
  return rawget (set, e) == true
end



--[[ ===================== ]]--
--[[ High Level Functions. ]]--
--[[ ===================== ]]--


-- These functions are independent of the internal implementation.


local difference, symmetric_difference, intersection, union, subset,
      proper_subset, equal


function difference (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  local t = Set {}
  for e in elems (set1) do
    if not member (set2, e) then
      insert (t, e)
    end
  end
  return t
end


function symmetric_difference (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  return difference (union (set1, set2), intersection (set2, set1))
end


function intersection (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  local t = Set {}
  for e in elems (set1) do
    if member (set2, e) then
      insert (t, e)
    end
  end
  return t
end


function union (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  local t = Set {}
  for e in elems (set1) do
    insert (t, e)
  end
  for e in elems (set2) do
    insert (t, e)
  end
  return t
end


function subset (set1, set2)
  if prototype (set2) == "table" then
    set2 = Set (set2)
  end
  for e in elems (set1) do
    if not member (set2, e) then
      return false
    end
  end
  return true
end


function proper_subset (set1, set2)
  if prototype (set2) == "table" then
    t = Set (set2)
  end
  return subset (set1, set2) and not subset (set2, set1)
end


function equal (set1, set2)
  return subset (set1, set2) and subset (set2, set1)
end



--[[ =========== ]]--
--[[ Set Object. ]]--
--[[ =========== ]]--


local function X (decl, fn)
  return require "std.debug".argscheck ("std.set." .. decl, fn)
end


--- Signature for cloning Set prototype object.
-- @function Set_Clone
-- @tparam table elements a list of additional elements
-- @treturn Set clone of prototype, with *elements* merged in
-- @usage
-- local Set = require "std.set" {}
-- local set_a = Set {1, 2, 3, 4}
-- local set_b = set_a {2, 4, 6, 8}
-- print (set_b) --> Set {1, 2, 3, 4, 6, 8}
-- os.exit (0)


--- Set prototype object.
--
-- Set also inherits all the fields and methods from
-- @{std.container.Container}.
-- @object Set
-- @string[opt="Set"] _type object name
-- @tfield Set_Clone _init initialisation function
-- @see std.container
-- @see std.object.__call
-- @usage
-- local std = require "std"
-- std.prototype (std.set) --> "Set"
-- os.exit (0)
Set = Container {
  _type      = "Set",

  _init      = function (self, t)
                 for e in ielems (t) do
                   insert (self, e)
                 end
                 return self
               end,


  --- Union operator.
  -- @static
  -- @function __add
  -- @tparam Set s a set
  -- @tparam table|Set t another set, or table
  -- @treturn Set union of *s* and *t*
  -- @see union
  -- @usage
  -- union = set + {"table"}
  __add = union,


  --- Difference operator.
  -- @static
  -- @function __sub
  -- @tparam Set s a set
  -- @tparam table|Set t another set, or table
  -- @treturn Set difference between *s* and *t*
  -- @see difference
  -- @usage
  -- difference = set - {"table"}
  __sub = difference,


  --- Intersection operator.
  -- @static
  -- @function __mul
  -- @tparam Set s a set
  -- @tparam table|Set t another set, or table
  -- @treturn Set intersection of *s* and *t*
  -- @see intersection
  -- @usage
  -- intersection = set * {"table"}
  __mul = intersection,


  --- Symmetric difference operator.
  -- @function __div
  -- @static
  -- @tparam Set s a set
  -- @tparam table|Set t another set, or table
  -- @treturn Set symmetric difference between *s* and *t*
  -- @see symmetric_difference
  -- @usage
  -- symmetric_difference = set / {"table"}
  __div = symmetric_difference,


  --- Subset operator.
  -- @static
  -- @function __le
  -- @tparam Set s a set
  -- @tparam table|Set t another set, or table
  -- @treturn boolean `true` if *s* is a subset of *t*
  -- @see subset
  -- @usage
  -- set = set <= {"table"}
  __le  = subset,


  --- Proper subset operator.
  -- @static
  -- @function __lt
  -- @tparam Set s set
  -- @tparam table|Set t another set or table
  -- @treturn boolean `true` if *s* is a proper subset of *t*
  -- @see proper_subset
  -- @usage
  -- proper_subset = set < {"table"}
  __lt  = proper_subset,


  -- Return a string representation of this set.
  -- @treturn string string representation of a set.
  -- @see std.tostring
  __tostring = function (self)
                 local keys = {}
                 for k in pairs (self) do
                   keys[#keys + 1] = tostring (k)
                 end
                 table.sort (keys)
                 return prototype (self) .. " {" .. table.concat (keys, ", ") .. "}"
               end,


  _functions = {
    --- Delete an element from a set.
    -- @static
    -- @function delete
    -- @tparam Set set a set
    -- @param e element
    -- @treturn Set the modified *set*
    -- @usage
    -- set.delete (available, found)
    delete = X ("delete (Set, any)",
                function (set, e) return rawset (set, e, nil) end),

    --- Find the difference of two sets.
    -- @static
    -- @function difference
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn Set a copy of *set1* with elements of *set2* removed
    -- @usage
    -- all = set.difference (all, {32, 49, 56})
    difference = X ("difference (Set, Set|table)", difference),

    --- Iterator for sets.
    -- @static
    -- @function elems
    -- @tparam Set set a set
    -- @todo Make the iterator return only the key
    -- @usage
    -- for code in set.elems (isprintable) do print (code) end
    elems = X ("elems (Set)", elems),

    --- Find whether two sets are equal.
    -- @static
    -- @function equal
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn boolean `true` if *set1* and *set2* each contain identical
    --   elements, `false` otherwise
    -- @usage
    -- if set.equal (keys, {META, CTRL, "x"}) then process (keys) end
    equal = X ( "equal (Set, Set|table)", equal),

    --- Insert an element into a set.
    -- @static
    -- @function insert
    -- @tparam Set set a set
    -- @param e element
    -- @treturn Set the modified *set*
    -- @usage
    -- for byte = 32,126 do
    --   set.insert (isprintable, string.char (byte))
    -- end
    insert = X ("insert (Set, any)", insert),

    --- Find the intersection of two sets.
    -- @static
    -- @function intersection
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn Set a new set with elements in both *set1* and *set2*
    -- @usage
    -- common = set.intersection (a, b)
    intersection = X ("intersection (Set, Set|table)", intersection),

    --- Say whether an element is in a set.
    -- @static
    -- @function difference
    -- @tparam Set set a set
    -- @param e element
    -- @return `true` if *e* is in *set*, otherwise `false`
    -- otherwise
    -- @usage
    -- if not set.member (keyset, pressed) then return nil end
    member = X ("member (Set, any)", member),

    --- Find whether one set is a proper subset of another.
    -- @static
    -- @function proper_subset
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn boolean `true` if *set2* contains all elements in *set1*
    --   but not only those elements, `false` otherwise
    proper_subset = X ("proper_subset (Set, Set|table)", proper_subset),

    --- Find whether one set is a subset of another.
    -- @static
    -- @function subset
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn boolean `true` if all elements in *set1* are also in *set2*,
    --   `false` otherwise
    subset = X ("subset (Set, Set|table)", subset),

    --- Find the symmetric difference of two sets.
    -- @static
    -- @function symmetric_difference
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn Set a new set with elements that are in *set1* or *set2*
    --   but not both
    -- @usage
    -- unique = set.symmetric_difference (a, b)
    symmetric_difference = X ("symmetric_difference (Set, Set|table)",
                              symmetric_difference),

    --- Find the union of two sets.
    -- @static
    -- @function union
    -- @tparam Set set1 a set
    -- @tparam table|Set set2 another set, or table
    -- @treturn Set a copy of *set1* with elements in *set2* merged in
    -- @usage
    -- all = set.union (a, b)
    union = X ("union (Set, Set|table)", union),
  },
}

return Set
