-- @module set
-- Sets

module ("set", package.seeall)

require "object"
require "table_ext"


-- Primitive methods (access the underlying representation)

-- The representation is a table whose tags are the elements, and
-- whose values are true.

-- Set: Make a list into a set
--   l: list
-- @returns
--   s: set
function Set (l)
  local set = {}
  for _, v in ipairs (l) do
    set[v] = true
  end
  return set
end


-- High level methods (no knowledge of representation)

set = {}

-- @func Set:minus: Find the difference of two sets
--   @param t: set
-- @returns
--   @param r: self with elements of t removed
function set.minus (t)
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
-- @returns
--   @param r: set intersection of self and t
function set.intersect (t)
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
-- @returns
--   @param r: set union of self and t
function set.union (t)
  local r = Set {}
  r.set = table.merge (self.set, t.set)
  return r
end

-- @func Set:subset: Find whether one set is a subset of another
--   @param t: set
-- @returns
--   @param r: true if self is a subset of t, false otherwise
function set.subset (t)
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
-- @returns
--   @param r: true if s is a proper subset of t, false otherwise
function set.propersubset (t)
  return self:subset (t) and not t:subset (self)
end

-- @func Set:equal: Find whether two sets are equal
--   @param t: set
-- @returns
--   @param r: true if sets are equal, false otherwise
function set.equal (t)
  return self:subset (t) and t:subset (self)
end

-- Metamethods
-- Set.__add = Set.union -- set + table = union
-- Set.__sub = Set.minus -- set - table = set difference
-- Set.__div = Set.intersect -- set / table = intersection
-- Set.__le = Set.subset -- set <= table = subset
-- Set.__lt = Set.propersubset -- set < table = proper subset
