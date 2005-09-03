-- @module Regular expressions


-- @function string.findl: Do string.find, returning captures as a list
--   @param s: target string
--   @param p: pattern
--   @param [init]: start position [1]
--   @param [plain]: inhibit magic characters [nil]
-- @returns
--   @param from, to: start and finish of match
--   @param capt: table of captures
function string.findl (s, p, init, plain)
  local function pack (from, to, ...)
    return from, to, arg
  end
  return pack (string.find (s, p, init, plain))
end

-- @function string.finds: Do multiple string.find's on a string
--   @param s: target string
--   @param p: pattern
--   @param [init]: start position [1]
--   @param [plain]: inhibit magic characters [nil]
-- @returns
--   @param t: table of {from=from, to=to; capt = {captures}}
function string.finds (s, p, init, plain)
  init = init or 1
  local t = {}
  local from, to, r
  repeat
    from, to, r = string.findl (s, p, init, plain)
    if from ~= nil then
      table.insert (t, {from = from, to = to, capt = r})
      init = to + 1
    end
  until not from
  return t
end

-- @function string.gsubs: Perform multiple calls to string.gsub
--   @param s: string to call string.gsub on
--   @param sub: {pattern1=replacement1 ...}
--   @param [n]: upper limit on replacements [infinite]
-- @returns
--   @param s_: result string
--   @param r: number of replacements made
function string.gsubs (s, sub, n)
  local r = 0
  for i, v in pairs (sub) do
    local rep
    if n ~= nil then
      s, rep = string.gsub (s, i, v, n)
      r = r + rep
      n = n - rep
      if n == 0 then
        break
      end
    else
      s, rep = string.gsub (s, i, v)
      r = r + rep
    end
  end
  return s, r
end

-- @function string.split: Split a string at a given separator
--   @param [sep]: separator regex ["%s+"]
--   @param s: string to split
-- @returns
--   @param l: list of strings
function string.split (sep, s)
  if s == nil then
    s, sep = sep, "%s+"
  end
  local l, n = {}, 0
  for m, _, p in string.gfind (s, "(.-)(" .. sep .. ")()") do
    n = p
    table.insert (l, m)
  end
  table.insert (l, string.sub (s, n))
  return l
end

-- @function string.ltrim: Remove leading matter from a string
--   @param [r]: leading regex ["%s+"]
--   @param s: string
-- @returns
--   @param s_: string without leading r
function string.ltrim (r, s)
  if s == nil then
    s, r = r, "%s+"
  end
  return (string.gsub (s, "^" .. r, ""))
end

-- @function string.rtrim: Remove trailing matter from a string
--   @param [r]: trailing regex ["%s+"]
--   @param s: string
-- @returns
--   @param s_: string without trailing r
function string.rtrim (r, s)
  if s == nil then
    s, r = r, "%s+"
  end
  return (string.gsub (s, r .. "$", ""))
end

-- @function string.trim: Remove leading and trailing matter from a
-- string
--   @param [r]: leading/trailing regex ["%s+"]
--   @param s: string
-- @returns
--   @param s_: string without leading/trailing r
function string.trim (r, s)
  return string.ltrim (string.rtrim (r, s))
end

-- TODO: @function string.rgsub: string.gsub-like wrapper for match
-- really needs to be in C for speed (replace gmatch)
--   @param s: target string
--   @param p: pattern
--   @param r: function
--     @param t: table of captures
--   @param [n]: maximum number of substutions [infinite]
--   @returns
--     @param rep: replacement
-- @returns
--   @param n: number of substitutions made

-- TODO: @function string.checkRegex: check regex is valid
--   @param p: regex pattern
-- @returns
--   @param f: true if regex is valid, or nil otherwise

-- TODO: @function rex.check{Posix,PCRE}Regex: check POSIX regex is valid
--   @param p: POSIX regex pattern
-- @returns
--   @param f: true if regex is valid, or nil otherwise
