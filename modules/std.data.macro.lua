-- Macros

require "std.data.list"
require "std.text.regex"


-- lookup: Do a late-bound table lookup
--   t: table to look up in
--   l: list of indices {l1 ... ln}
-- returns
--   u: t[l1]...[ln]
function lookup (t, l)
  return foldl (subscript, t, l)
end

-- pathSubscript: Subscript a table with a string containing dots
--   t: table
--   s: subscript of the form s1.s2. ... .sn
-- returns
--   v: t.s1.s2. ... .sn
function pathSubscript (t, s)
  return lookup (t, split ("%.", s))
end
