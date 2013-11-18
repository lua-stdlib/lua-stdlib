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
-- @param s set
-- @param e element
-- @return `true` if e is in set, `false`
-- otherwise
local function member (s, e)
  return rawget (s, e) == true
end

--- Insert an element into a set.
-- @param s set
-- @param e element
-- @return the modified set
local function insert (s, e)
  rawset (s, e, true)
  return s
end

--- Delete an element from a set.
-- @param s set
-- @param e element
-- @return the modified set
local function delete (s, e)
  rawset (s, e, nil)
  return s
end

--- Iterator for sets.
-- @todo Make the iterator return only the key
local function elems (s)
  return pairs (s)
end


-- High level methods (representation-independent)

local difference, symmetric_difference, intersection, union, subset, equal

--- Find the difference of two sets.
-- @param s set
-- @param t set
-- @return s with elements of t removed
function difference (s, t)
  if Object.type (t) == "table" then
    t = Set (t)
  end
  local r = Set {}
  for e in elems (s) do
    if not member (t, e) then
      insert (r, e)
    end
  end
  return r
end

--- Find the symmetric difference of two sets.
-- @param s set
-- @param t set
-- @return elements of s and t that are in s or t but not both
function symmetric_difference (s, t)
  if Object.type (t) == "table" then
    t = Set (t)
  end
  return difference (union (s, t), intersection (t, s))
end

--- Find the intersection of two sets.
-- @param s set
-- @param t set
-- @return set intersection of s and t
function intersection (s, t)
  if Object.type (t) == "table" then
    t = Set (t)
  end
  local r = Set {}
  for e in elems (s) do
    if member (t, e) then
      insert (r, e)
    end
  end
  return r
end

--- Find the union of two sets.
-- @param s set
-- @param t set or set-like table
-- @return set union of s and t
function union (s, t)
  if Object.type (t) == "table" then
    t = Set (t)
  end
  local r = Set {}
  for e in elems (s) do
    insert (r, e)
  end
  for e in elems (t) do
    insert (r, e)
  end
  return r
end

--- Find whether one set is a subset of another.
-- @param s set
-- @param t set
-- @return `true` if s is a subset of t, `false` otherwise
function subset (s, t)
  if Object.type (t) == "table" then
    t = Set (t)
  end
  for e in elems (s) do
    if not member (t, e) then
      return false
    end
  end
  return true
end

--- Find whether one set is a proper subset of another.
-- @param s set
-- @param t set
-- @return `true` if s is a proper subset of t, false otherwise
function propersubset (s, t)
  if Object.type (t) == "table" then
    t = Set (t)
  end
  return subset (s, t) and not subset (t, s)
end

--- Find whether two sets are equal.
-- @param s set
-- @param t set
-- @return `true` if sets are equal, `false` otherwise
function equal (s, t)
  return subset (s, t) and subset (t, s)
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
  -- @metamethod __add
  -- @see std.set:union
  __add = union,

  ------
  -- Difference operator.
  --     set - table = set difference
  -- @metamethod __sub
  -- @see std.set:difference
  __sub = difference,

  ------
  -- Intersection operator.
  --     set * table = intersection
  -- @metamethod __mul
  -- @see std.set:intersection
  __mul = intersection,

  ------
  -- Symmetric difference operator.
  --     set / table = symmetric difference
  -- @metamethod __div
  -- @see std.set:symmetric_difference
  __div = symmetric_difference,

  ------
  -- Subset operator.
  --     set <= table = subset
  -- @metamethod __le
  -- @see std.set:subset
  __le  = subset,

  ------
  -- Proper subset operator.
  --     set < table = proper subset
  -- @metamethod __lt
  -- @see std.set:propersubset
  __lt  = propersubset,

  ------
  -- Object to table conversion.
  --     table = set:totable ()
  -- @metamethod __totable
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
