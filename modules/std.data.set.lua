-- Sets

require "std.data.table"


-- Sets are tables whose indices are the members of the set; the
-- values are ignored (and the functions below set them to 1)
-- To add an element to a set, s[e] = 1
-- To find whether e is in s, evaluate s[e] ~= nil

_SetTag = newtag () -- tag for sets

-- Set: Make a list into a set
--   l: list
-- returns
--   s: set
function Set (l)
  local s = {}
  for i = 1, getn (l) do
    s[l[i]] = 1
  end
  return settag (s, _SetTag)
end

-- setminus: Find the difference of two sets
--   s, t: sets
-- returns
--   r: s with elements of t removed
function setminus (s, t)
  local r = Table (tag (s))
  for i, v in s do
    if t[i] == nil then
      r[i] = 1
    end
  end
  return r
end

-- intersect: Find the intersection of two sets
--   s, t: sets
-- returns
--   r: set intersection of s and t
function intersect (s, t)
  local r = Table (tag (s))
  for i, _ in s do
    if t[i] ~= nil then
      r[i] = 1
    end
  end
  return r
end

-- subset: Find whether one set is a subset of another
--   s, t: sets
-- returns
--   r: non-nil if s is a subset of t, nil otherwise
function subset (s, t)
  for i, _ in s do
    if t[i] == nil then
      return nil
    end
  end
  return 1
end

-- propersubset: Find whether one set is a proper subset of another
--   s, t: sets
-- returns
--   r: non-nil if s is a proper subset of t, nil otherwise
function propersubset (s, t)
  return subset (s, t) and not subset (t, s)
end

-- setempty: Find whether a set is empty
--   s: set
-- returns
--   r: nil if s is empty, non-nil otherwise
function setempty (s)
  return subset (s, {})
end

-- setequal: Find whether two sets are equal
--   s, t: sets
-- returns
--   r: nil if sets are not equal, non-nil otherwise
function setequal (s, t)
  return subset (s, t) and subset (t, s)
end

-- Tag methods for sets
settagmethod (_SetTag, "add", merge) -- set + table = union
settagmethod (_SetTag, "sub", setminus) -- set - table = set difference
settagmethod (_SetTag, "mul", intersect) -- set * table = intersection
-- The next tag method looks nice, but doesn't work because subset is
-- not a total order (and "lt" is the only tag method; need "le" tag
-- method)
-- settagmethod (_SetTag, "lt", propersubset) -- set < table = subset
