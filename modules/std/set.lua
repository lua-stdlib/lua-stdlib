-- @module set
-- FIXME: metamethods need sorting out. How do we neatly set a
-- metamethods table which still gives access to globals?

module ("Set", package.seeall)

require "std.object"
require "std.table"


local metamethods = {}
--setmetatable (_M, metamethods)

-- Primitive methods (access the underlying representation)

-- The representation is a table whose tags are the elements, and
-- whose values are true.

-- @func member: Say whether an element is in a set
--   @param e: element
-- @returns
--   @param f: true if e is in set, false otherwise
function member (e)
  return self[e] == true
end

-- @func add: Add an element to a set
--   @param e: element
function add (e)
  self[e] = true
end

-- @func new: Make a list into a set
--   @param l: list
-- @returns
--   @param s: set
function metamethods.__call (l)
  local s = {}
  for _, v in ipairs (l) do
    s:add (true)
  end
  return s
end


-- High level methods (no knowledge of representation)

-- @func minus: Find the difference of two sets
--   @param t: set
-- @returns
--   @param r: self with elements of t removed
function minus (t)
  local r = new {}
  for e in self:pairs () do
    if not t:member (e) then
      r:add (e)
    end
  end
  return r
end

-- @func intersect: Find the intersection of two sets
--   @param t: set
-- @returns
--   @param r: set intersection of self and t
function intersect (t)
  local r = Set {}
  for e in self:pairs () do
    if t:member (e) then
      r:add (e)
    end
  end
  return r
end

-- @func union: Find the union of two sets
--   @param t: set
-- @returns
--   @param r: set union of self and t
function union (t)
  local r = Set {}
  r.set = table.merge (self.set, t.set)
  return r
end

-- @func subset: Find whether one set is a subset of another
--   @param t: set
-- @returns
--   @param r: true if self is a subset of t, false otherwise
function subset (t)
  for e in self:pairs () do
    if not t:member (e) then
      return false
    end
  end
  return true
end

-- @func propersubset: Find whether one set is a proper subset of
-- another
--   @param t: set
-- @returns
--   @param r: true if s is a proper subset of t, false otherwise
function propersubset (t)
  return self:subset (t) and not t:subset (self)
end

-- @func equal: Find whether two sets are equal
--   @param t: set
-- @returns
--   @param r: true if sets are equal, false otherwise
function equal (t)
  return self:subset (t) and t:subset (self)
end

-- FIXME: Metamethods
-- __add = union -- set + table = union
-- __sub = minus -- set - table = set difference
-- __div = intersect -- set / table = intersection
-- __le = subset -- set <= table = subset
-- __lt = propersubset -- set < table = proper subset
