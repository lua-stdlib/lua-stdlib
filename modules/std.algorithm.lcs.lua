-- LCS algorithm

-- After pseudo-code in
-- http://www.ics.uci.edu/~eppstein/161/960229.html
-- Lecture notes by David Eppstein, eppstein@ics.uci.edu

lcs = {}

function lcs.commonSeqs (a, b, sub, len)
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

function lcs.leastCommonSeq (a, b, sub, len, concat, s)
  local l, m, n = lcs.commonSeqs (a, b, sub, len)
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
