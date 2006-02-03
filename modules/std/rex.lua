-- Regular expressions

-- rex = require "pcre" -- global

-- Default constructor (use PCREs)
setmetatable (rex, {__call =
                function (self, p, cf, lo)
                  return self.newPCRE (p, cf, lo)
                end})

-- @function rex.find: string.find for rex library
--   @param s: string to search
--   @param p: pattern to find
--   @param [cf]: compile-time flags for the regex
--   @param [lo]: locale for the regex
--   @param [ef]: execution flags for the regex
-- returns
--   @param from, to: start and end points of match, or nil
--   @param sub: table of substring matches, or nil if none
function rex.find (s, p, cf, lo, ef)
  return rex (p, cf, lo):match (s, 1, ef)
end

-- @function rex.gsub: string.gsub for rex
--   @param s: string to search
--   @param p: pattern to find
--   @param f: replacement function or string
--   @param [n]: maximum number of replacements [all]
--   @param [cf]: compile-time flags for the regex
--   @param [lo]: locale for the regex
--   @param [ef]: execution flags for the regex
-- returns
--   @param r: string with replacements
--   @param reps: number of replacements made
function rex.gsub (s, p, f, n, cf, lo, ef)
  local ncap -- number of captures; used as an upvalue for repfun
  if type (f) == "string" then
    local rep = f
    f = function (...)
          local ret = rep
          local function repfun (percent, d)
            if math.mod (string.len (percent), 2) == 1 then
              d = tonumber (d)
              assert (d > 0 and d <= ncap, "invalid capture index")
              d = arg[d] or "" -- capture can be false
              percent = string.sub (percent, 2)
            end
            return percent .. d
          end
          ret = string.gsub (ret, "(%%+)([0-9])", repfun)
          ret = string.gsub (ret, "%%(.)", "%1")
          return ret
        end
  end
  local reg = rex (p, cf, lo)
  local st = 1
  local r, reps = {}, 0
  while (not n) or reps < n do
    local from, to, cap = reg:match (s, st, ef)
    if not from then
      break
    end
    table.insert (r, string.sub (s, st, from - 1))
    ncap = table.getn (cap)
    if ncap == 0 then
      cap[1] = string.sub (s, from, to)
    end
    table.insert (r, f (unpack (cap)) or "")
    reps = reps + 1
    if st <= to then
      st = to + 1
    elseif st <= string.len (s) then -- advance by 1 char (not replaced)
      table.insert (r, string.sub (s, st, st))
      st = st + 1
    else
      break
    end
  end
  table.insert (r, string.sub (s, st))
  return table.concat (r), reps
end


-- Tests

local function PatternLua2Pcre (pat)
  local function repfun (percent)
    local d = (math.mod (string.len (percent), 2) == 1) and "-" or "*?"
    return percent .. d
  end
  pat = string.gsub (pat, "(%%*)%-", repfun) -- replace unescaped dashes
  pat = string.gsub (pat, "%%(.)", "\\%1")
  return pat
end

local subj, pat = "abcdef", "[abef]+"
local set1 = {
  name = "Set1",
--{s,    p,   f,   n,       res1,  res2},
  {subj, pat, "",  0,     subj,    0}, -- test "n" + empty_replace
  {subj, pat, "",  1,     "cdef",  1},
  {subj, pat, "",  2,     "cd",    2},
  {subj, pat, "",  3,     "cd",    2},
  {subj, pat, "",  false, "cd",    2},
  {subj, pat, "#", 0,     subj,    0}, -- test "n" + non-empty_replace
  {subj, pat, "#", 1,     "#cdef", 1},
  {subj, pat, "#", 2,     "#cd#",  2},
  {subj, pat, "#", 3,     "#cd#",  2},
  {subj, pat, "#", false, "#cd#",  2},
}

subj, pat = "abc", "([ac])"
local set2 = {
  name = "Set2",
--{s,    p,   f,        n,     res1,      res2},
  {subj, pat, "<%1>",   false, "<a>b<c>", 2}, -- test non-escaped chars in f
  {subj, pat, "%<%1%>", false, "<a>b<c>", 2}, -- test escaped chars in f
  {subj, pat, "",       false, "b",       2}, -- test empty replace
  {subj, pat, "1",      false, "1b1",     2}, -- test odd and even %'s in f
  {subj, pat, "%1",     false, "abc",     2},
  {subj, pat, "%%1",    false, "%1b%1",   2},
  {subj, pat, "%%%1",   false, "%ab%c",   2},
  {subj, pat, "%%%%1",  false, "%%1b%%1", 2},
  {subj, pat, "%%%%%1", false, "%%ab%%c", 2},
  {"abc", "[ac]", "%1", false, false,     0},
}

local set3 = {
  name = "Set3",
--{s,     p,     f,    n,     res1,  res2},
  {"abc", "a",   "%0", false, false, 0}, -- test invalid capture number
  {"abc", "a",   "%1", false, false, 0},
  {"abc", "a",   "%1", false, false, 0},
  {"abc", "(a)", "%1", false, "abc", 1},
  {"abc", "(a)", "%2", false, false, 0},
}

local function gsub_test (set)
  local r0, r1, r2 -- results
  local function err (k, func_name)
    print (set.name or "Unnamed Set")
    print ("Test " .. k .. " of " .. func_name)
    print ("Set:", unpack (set[k]))
    print ("Results:", r1, r2)
    print ("")
  end
  for k,v in ipairs (set) do
    local num = v[4] or nil

    r0, r1, r2 = pcall (string.gsub, v[1], v[2], v[3], num)
    if (r0 and (r1 ~= v[5] or r2 ~= v[6])) or (not r0 and v[5]) then
      err (k, "string.gsub")
    end

    r0, r1, r2 = pcall (rex.gsub, v[1], PatternLua2Pcre (v[2]), v[3], num)
    if (r0 and (r1 ~= v[5] or r2 ~= v[6])) or (not r0 and v[5]) then
      err (k, "rex.gsub")
    end
  end
end

gsub_test (set1)
gsub_test (set2)
gsub_test (set3)
