-- Regular expressions

require "std.patch50"


-- strfindt: Do strfind, returning captures as a list
--   s: target string
--   p: pattern
--   [init]: start position [1]
--   [plain]: inhibit magic characters [nil]
-- returns
--   from, to: start and finish of match
--   capt: table of captures
function strfindt (s, p, init, plain)
  local pack =
    function (from, to, ...)
      return from, to, arg
    end
  return pack (strfind (s, p, init, plain))
end

-- nextstr: iterator for strings
--   s: string being iterated over
--   p: pattern being iterated with
--   f: function to be iterated
--     from, to: start and end points of substring
--     capt: table of captures
--     t: result accumulator (initialised to t below)
--     s: string being iterated over (same as s above)
--   returns
--     cont: point at which to continue iteration, or nil to stop
--   t: result accumulator (usually result table)
-- returns
--   u: result accumulator (same as u argument)
function nextstr (s, p, f, t)
  t = t or {}
  local from, to, capt
  repeat
    from, to, capt = strfindt (s, p, from)
    if from and to then
      from = f (from, to, capt, t, s)
    end
  until not (from and to)
  return t
end

-- strfinds: Do multiple strfinds on a string
--   s: target string
--   p: pattern
--   [init]: start position [1]
--   [plain]: inhibit magic characters [nil]
-- returns
--   t: table of {from=from, to=to; capt = {captures}}
function strfinds (s, p, init, plain)
  init = init or 1
  local t = {}
  local from, to, r
  repeat
    from, to, r = strfindt (s, p, init, plain)
    if from ~= nil then
      tinsert (t, {from = from, to = to, capt = r})
      init = to + 1
    end
  until not from
  return t
end

-- gsubs: Perform multiple calls to gsub
--   s: string to call gsub on
--   sub: {pattern1=replacement1 ...}
--   [n]: upper limit on replacements [infinite]
-- returns
--   s_: result string
--   r: number of replacements made
function gsubs (s, sub, n)
  local r = 0
  for i, v in sub do
    local rep
    if n ~= nil then
      s, rep = gsub (s, i, v, n)
      r = r + rep
      n = n - rep
      if n == 0 then
        break
      end
    else
      s, rep = gsub (s, i, v)
      r = r + rep
    end
  end
  return s, r
end

-- split: Turn a string into a list of strings, breaking at sep
--   [sep]: separator regex ["%s+"]
--   s: string to split
-- returns
--   l: list of strings
function split (sep, s)
  if s == nil then
    s, sep = sep, "%s+"
  end
  local t, len = {n = 0}, strlen (s)
  local init, oldto, from = 1, 0, 0
  local to
  while init <= len and from do
    from, to = strfind (s, sep, init)
    if from ~= nil then
      if oldto > 0 or to > 0 then
        tinsert (t, strsub (s, oldto, from - 1))
      end
      init = max (from + 1, to + 1)
      oldto = to + 1
    end
  end
  if (oldto <= len or to == len) and len > 0 then
    tinsert (t, strsub (s, oldto))
  end
  return t
end

-- rstrfind: strfind-like wrapper for match
-- TODO: make a function tag method for compiled regexes so that
-- match (s, r) is written r (s)
--   s: target string
--   p: pattern
-- returns
--   m: first match of p in s
function rstrfind (s, p)
  return match (s, regex (p))
end

-- rgmatch: Wrapper for gmatch
--   s: target string
--   p: pattern
--   r: function
--     m: matched string
--     t: table of captures
--   [n]: maximum number of matches [infinite]
-- returns
--   n: number of matches made
function rgmatch (s, p, r, n)
  return gmatch (s, regex (p), r, n)
end

-- TODO: rgsub: gsub-like wrapper for match
-- really needs to be in C for speed (replace gmatch)
--   s: target string
--   p: pattern
--   r: function
--     t: table of captures
--   [n]: maximum number of substutions [infinite]
--   returns
--     rep: replacement
-- returns
--   n: number of substitutions made

-- TODO: checkRegex: check regex is valid
--   r: regex
-- returns
--   f: true if regex is valid, or nil otherwise

-- TODO: checkPosixRegex: check POSIX regex is valid
--   r: POSIX regex
-- returns
--   f: true if regex is valid, or nil otherwise
