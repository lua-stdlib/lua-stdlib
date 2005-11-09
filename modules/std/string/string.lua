-- String

require "std.string.regex"
require "std.algorithm.lcs"


-- @func string.concat: Give a name to .. for strings
--   @param s1, s2, ..., sn: strings
-- @returns
--   @param s_: s1 .. s2 .. ... .. sn
function string.concat (...)
  return table.concat (arg)
end

-- @func string.caps: Capitalise each word in a string
--   @param s: string
-- @returns
--   @param s_: capitalised string
function string.caps (s)
  return (string.gsub (s, "(%w)([%w]*)",
                       function (l, ls)
                         return string.upper (l) .. ls
                       end))
end

-- @func string.chomp: Remove any final newline from a string
--   @param s: string to process
-- @returns
--   @param s_: processed string
function string.chomp (s)
  return (string.gsub (s, "\n$", ""))
end

-- @func string.escapePattern: Escape a string to be used as a pattern
--   @param s: string to process
-- @returns
--   @param s_: processed string
function string.escapePattern (s)
  return (string.gsub (s, "(%W)", "%%%1"))
end

-- @param string.escapeShell: Escape a string to be used as a shell token
-- Quotes spaces, parentheses and \s
--   @param s: string to process
-- @returns
--   @param s_: processed string
function string.escapeShell (s)
  return (string.gsub (s, "([ %(%)%\\])", "\\%1"))
end

-- @func string.ordinalSuffix: Return the English suffix for an ordinal
--   @param n: number of the day
-- @returns
--   @param s: suffix
function string.ordinalSuffix (n)
  n = math.mod (n, 100)
  local d = math.mod (n, 10)
  if d == 1 and n ~= 11 then
    return "st"
  elseif d == 2 and n ~= 12 then
    return "nd"
  elseif d == 3 and n ~= 13 then
    return "rd"
  else
    return "th"
  end
end

-- @func string.lcs: Find the longest common subsequence of two
-- strings
--   @param: a, b: strings
-- @returns
--   @param: s: longest common subsequence
function string.lcs (a, b)
  return lcs.longestCommonSubseq (a, b,
                                  function (s, i)
                                    return string.sub (s, i, i)
                                  end,
                                  string.len, string.concat, "")
end
