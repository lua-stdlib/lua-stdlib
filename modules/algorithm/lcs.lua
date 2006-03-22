-- @module LCS algorithm

-- After pseudo-code in
-- http://www.ics.uci.edu/~eppstein/161/960229.html
-- Lecture notes by David Eppstein, eppstein@ics.uci.edu

lcs = {}

-- The interface provided by this module is a little unwieldy at first
-- glance, but is quite easy to use: the best way is probably to
-- define a wrapper for lcs.longestCommonSubseq for each type on which
-- you wish to use it.
--
-- I used function parameters rather than metamethods because strings
-- don't have metamethods and there is no standard length metamethod.


-- @func lcs.commonSubseqs: find common subsequences
--   @param a, b: two sequences of type T
--   @param sub: subscription operator on T
--     @param s: a sequence of type T
--     @param i: a number
--   @returns
--     @param e: the ith element of s
--   @param len: length operator on T
--     @param s: a sequence of type T
--   @returns
--     @param l: the length of s
-- @returns
--   @param l_: list of common subsequences
--   @param m: the length of a
--   @param n: the length of b
function lcs.commonSubseqs (a, b, sub, len)
  local l, m, n = {}, len (a), len (b)
  for i = m + 1, 1, -1 do
    l[i] = {}
    for j = n + 1, 1, -1 do
      if i > m or j > n then
        l[i][j] = 0
      elseif sub (a, i) == sub (b, j) then
        l[i][j] = 1 + l[i + 1][j + 1]
      else
        l[i][j] = math.max (l[i + 1][j], l[i][j + 1])
      end
    end
  end
  return l, m, n
end

-- @func lcs.longestCommonSubseq: find the LCS of two sequences
--   @param a, b: two sequences of some type T
--   @param sub: subscription operator on T
--     @param s: a sequence of type T
--     @param i: a number
--   @returns
--     @param e: the ith element of s
--   @param len: length operator on T
--     @param s: a sequence of type T
--   @returns
--     @param l: the length of s
--   @concat: concatenation operator on T
--     @param s, t: two sequences of type T
--   @returns
--     @param u: t appended to s
--   @param s: an empty sequence of type T
-- @returns
--   @param s_: the LCS of a and b
function lcs.longestCommonSubseq (a, b, sub, len, concat, s)
  local l, m, n = lcs.commonSubseqs (a, b, sub, len)
  local i, j = 1, 1
  while i <= m and j <= n do
    if sub (a, i) == sub (b, j) then
      s = concat (s, sub (a, i))
      i = i + 1
      j = j + 1
    elseif l[i + 1][j] >= l[i][j + 1] then
      i = i + 1
    else
      j = j + 1
    end
  end
  return s
end
