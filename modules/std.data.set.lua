-- Sets

require "std.object"
require "std.table"


-- Define class
Set = Object {}


-- Primitive methods (access the underlying representation)

-- The representation is a table whose tags are the elements, and
-- whose values are true.

-- @func Set:pairs: Iterator for sets
function Set:pairs ()
  return pairs (self.set)
end

-- @func Set:add: Add an element to a set
--   @param e: element
function Set:add (e)
  self.set[e] = true
end

-- @func Set:member: Test for membership of a set
--   @param e: element
-- returns
--   @param f: true if e is in set, false otherwise
function Set:member (e)
  return self.set[e] ~= nil
end

-- Set:_clone: Make a list into a set
--   l: list
-- returns
--   s: set
function Set:_clone (l)
  local set = table.clone (self)
  setmetatable (set, set)
  set.set = {}
  for _, v in ipairs (l) do
    set:add (v)
  end
  return set
end


-- High level methods (no knowledge of representation)

-- @func Set:minus: Find the difference of two sets
--   @param t: set
-- returns
--   @param r: self with elements of t removed
function Set:minus (t)
  local r = Set {}
  for e in self:pairs () do
    if not t:member (e) then
      r:add (e)
    end
  end
  return r
end

-- @func Set:intersect: Find the intersection of two sets
--   @param t: set
-- returns
--   @param r: set intersection of self and t
function Set:intersect (t)
  local r = Set {}
  for e in self:pairs () do
    if t:member (e) then
      r:add (e)
    end
  end
  return r
end

-- @func Set:union: Find the union of two sets
--   @param t: set
-- returns
--   @param r: set union of self and t
function Set:union (t)
  local r = Set {}
  r.set = table.merge (self.set, t.set)
  return r
end

-- @func Set:subset: Find whether one set is a subset of another
--   @param t: set
-- returns
--   @param r: true if self is a subset of t, false otherwise
function Set:subset (t)
  for e in self:pairs () do
    if not t:member (e) then
      return false
    end
  end
  return true
end

-- @func Set:propersubset: Find whether one set is a proper subset of
-- another
--   @param t: set
-- returns
--   @param r: true if s is a proper subset of t, false otherwise
function Set:propersubset (t)
  return self:subset (t) and not t:subset (self)
end

-- @func Set:empty: Find whether a set is empty
-- returns
--   r: false if s is empty, true otherwise
function Set:empty ()
  return self:subset ({})
end

-- @func Set:equal: Find whether two sets are equal
--   @param t: set
-- returns
--   @param r: true if sets are equal, false otherwise
function Set:equal (t)
  return self:subset (t) and t:subset (self)
end

-- Metamethods
Set.__add = Set.union -- set + table = union
Set.__sub = Set.minus -- set - table = set difference
Set.__div = Set.intersect -- set / table = intersection
Set.__le = Set.subset -- set <= table = subset
Set.__lt = Set.propersubset -- set < table = proper subset
