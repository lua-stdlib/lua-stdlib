--[[--
 Set object.
 @classmod std.set
 ]]

local list   = require "std.base"
local Object = require "std.object"

local Set -- forward declaration

-- Primitive methods (know about representation)
-- The representation is a table whose tags are the elements, and
-- whose values are true.

--- Say whether an element is in a set.
-- @param e element
-- @return `true` if e is in set, `false`
-- otherwise
local function member (self, e)
  return rawget (self, e) == true
end

--- Insert an element into a set.
-- @param e element
-- @return the modified set
local function insert (self, e)
  rawset (self, e, true)
  return self
end

--- Delete an element from a set.
-- @param e element
-- @return the modified set
local function delete (self, e)
  rawset (self, e, nil)
  return self
end

--- Iterator for sets.
-- @todo Make the iterator return only the key
local function elems (self)
  return pairs (self)
end


-- High level methods (representation-independent)

local difference, symmetric_difference, intersection, union, subset, equal

--- Find the difference of two sets.
-- @param s set
-- @return `self` with elements of s removed
function difference (self, s)
  if Object.type (s) == "table" then
    s = Set (s)
  end
  local t = Set {}
  for e in elems (self) do
    if not member (s, e) then
      insert (t, e)
    end
  end
  return t
end

--- Find the symmetric difference of two sets.
-- @param s set
-- @return elements of `self` and `s` that are in `self` or `s` but not both
function symmetric_difference (self, s)
  if Object.type (s) == "table" then
    s = Set (s)
  end
  return difference (union (self, s), intersection (s, self))
end

--- Find the intersection of two sets.
-- @param s set
-- @return set intersection of `self` and `s`
function intersection (self, s)
  if Object.type (s) == "table" then
    s = Set (s)
  end
  local t = Set {}
  for e in elems (self) do
    if member (s, e) then
      insert (t, e)
    end
  end
  return t
end

--- Find the union of two sets.
-- @param s set or set-like table
-- @return set union of `self` and `s`
function union (self, s)
  if Object.type (s) == "table" then
    s = Set (s)
  end
  local t = Set {}
  for e in elems (self) do
    insert (t, e)
  end
  for e in elems (s) do
    insert (t, e)
  end
  return t
end

--- Find whether one set is a subset of another.
-- @param s set
-- @return `true` if `self` is a subset of `s`, `false` otherwise
function subset (self, s)
  if Object.type (s) == "table" then
    s = Set (s)
  end
  for e in elems (self) do
    if not member (s, e) then
      return false
    end
  end
  return true
end

--- Find whether one set is a proper subset of another.
-- @param s set
-- @return `true` if `self` is a proper subset of `s`, `false` otherwise
function propersubset (self, s)
  if Object.type (s) == "table" then
    t = Set (s)
  end
  return subset (self, s) and not subset (s, self)
end

--- Find whether two sets are equal.
-- @param s set
-- @return `true` if `self` and `s` are equal, `false` otherwise
function equal (self, s)
  return subset (self, s) and subset (s, self)
end


Set = Object {
  -- Derived object type.
  _type = "Set",

  -- Initialise.
  _init = function (self, t)
    for e in list.elems (t) do
      insert (self, e)
    end
    return self
  end,


  ------
  -- Union operator.
  --     set + table = union
  -- @function __add
  -- @param set set
  -- @param table set or set-like table
  -- @see union
  __add = union,

  ------
  -- Difference operator.
  --     set - table = set difference
  -- @function __sub
  -- @param set set
  -- @param table set or set-like table
  -- @see difference
  __sub = difference,

  ------
  -- Intersection operator.
  --     set * table = intersection
  -- @function __mul
  -- @param set set
  -- @param table set or set-like table
  -- @see intersection
  __mul = intersection,

  ------
  -- Symmetric difference operator.
  --     set / table = symmetric difference
  -- @function __div
  -- @param set set
  -- @param table set or set-like table
  -- @see symmetric_difference
  __div = symmetric_difference,

  ------
  -- Subset operator.
  --     set <= table = subset
  -- @function __le
  -- @param set set
  -- @param table set or set-like table
  -- @see subset
  __le  = subset,

  ------
  -- Proper subset operator.
  --     set < table = proper subset
  -- @function __lt
  -- @param set set
  -- @param table set or set-like table
  -- @see propersubset
  __lt  = propersubset,

  ------
  -- Object to table conversion.
  --     table = set:totable ()
  __totable  = function (self)
                 local t = {}
                 for e in elems (self) do
                   table.insert (t, e)
                 end
                 table.sort (t)
                 return t
               end,

  --- @export
  __index = {
    delete               = delete,
    difference           = difference,
    elems                = elems,
    equal                = equal,
    insert               = insert,
    intersection         = intersection,
    member               = member,
    propersubset         = propersubset,
    subset               = subset,
    symmetric_difference = symmetric_difference,
    union                = union,
  },
}

return Set
