-- @module rex
-- Regular expressions library

-- The rex module provides an interface to the lrexlib POSIX and PCRE
-- regular expression support that mimics the standard string library.
-- It provides find, gmatch and gsub functions, which as far as
-- possible are compatible with their string library equivalents. It
-- also adds a gmatch metamethod for regex objects (this allows gmatch
-- to be used without constructing the regex object each time).

module ("rex", package.seeall)

-- TODO: Allow a default regex library to be installed (Lua, POSIX or PCRE)
require "rex_pcre" -- global
_G.rex = rex_pcre

-- Default constructor (use PCREs)
setmetatable (rex, {__call =
                function (self, p, cf, lo)
                  return self.newPCRE (p, cf, lo)
                end})

rex:flags() -- add flags to rex namespace

-- @func find: string.find for rex library
--   @param s: string to search
--   @param p: pattern to find
--   @param [st]: start position for match
--   @param [cf]: compile-time flags for the regex
--   @param [lo]: locale for the regex
--   @param [ef]: execution flags for the regex
-- @returns
--   @param from, to: start and end points of match, or nil
--   @param [match, ...]: substring matches
function rex.find (s, p, st, cf, lo, ef)
  local from, to, cap = rex (p, cf, lo):match (s, st, ef)
  if from and cap[1] ~= nil then
    return from, to, unpack (cap)
  end
  return from, to
end

-- @func rex.gmatch: rex:gmatch in Lua
--   @param self: compiled regex
--   @param s: string to search
--   @param f: function to call for each match
--     @param m: matched string
--     @param t: table of captures
--   @returns
--     @param quit: true to stop gmatch immediately
--   @param [n]: maximum number of replacements [all]
--   @param [ef]: execution flags for the regex
-- @returns
--   @param reps: number of replacements made
function rex.gmatch (self, s, f, n, ef)
  local reps, st = 0, 1
  while (not n) or reps < n do
    local from, to, cap = self:match (s, st, ef)
    if from then
      reps = reps + 1
      if f (string.sub (s, from, to), cap) then
        break
      end
      st = to + 1
    else
      break
    end
  end
  return reps
end
getmetatable (rex ("")).gmatch = rex.gmatch

-- @func gsub: string.gsub for rex
--   @param s: string to search
--   @param p: pattern to find
--   @param f: replacement function or string
--   @param [n]: maximum number of replacements [all]
--   @param [cf]: compile-time flags for the regex
--   @param [lo]: locale for the regex
--   @param [ef]: execution flags for the regex
-- @returns
--   @param r: string with replacements
--   @param reps: number of replacements made
function rex.gsub (s, p, f, n, cf, lo, ef)
  if type (f) == "string" then
    local rep = f
    f = function (...)
          local arg = {...}
          local ret = rep
          local function repfun (percent, d)
            if #percent % 2 == 1 then
              d = tonumber(d)
              d = arg [d == 0 and 1 or d]
              assert (d ~= nil, "invalid capture index")
              d = d or "" -- capture can be false
              percent = string.sub (percent, 2)
            end
            return percent .. d
          end
          ret = string.gsub (ret, "(%%+)([0-9])", repfun)
          ret = string.gsub (ret, "%%(.)", "%1")
          return ret
        end
  elseif type (f) == "table" then
    local rep = f
    f = function (s)
          return rep[s]
        end
  end
  local reg = rex (p, cf, lo)
  local st = 1
  local r, reps = {}, 0
  local efr = bit.bor (ef or 0, rex.NOTEMPTY, rex.ANCHORED)
  local retry
  while (not n) or reps < n do
    local from, to, cap = reg:match (s, st, retry and efr or ef)
    retry = false
    if from then
      table.insert (r, string.sub (s, st, from - 1))
      if #cap == 0 then
        cap[1] = string.sub (s, from, to)
      end
      local rep = f (unpack (cap)) or string.sub (s, from, to)
      local reptype = type (rep)
      if reptype ~= "string" and reptype ~= "number" then
        error ("invalid replacement value (a " .. reptype .. ")")
      end
      table.insert (r, rep)
      reps = reps + 1
      if from <= to then
        st = to + 1
      elseif st <= #s then -- retry from the matching point
        retry = true
        st = from
      else
        break
      end
    else
      if retry and st <= #s then -- advance by 1 char (not replaced)
        table.insert (r, string.sub (s, st, st))
        st = st + 1
      else
        break
      end
    end
  end
  table.insert (r, string.sub (s, st))
  return table.concat (r), reps
end


-- Tests

if type (_DEBUG) == "table" and _DEBUG.std then
  
  local function gsubPCRE(str, pat, repl, n)
    return generic_gsub(rex_pcre.newPCRE, str, pat, repl, n)
  end

  local t_esc = {
    a = "[:alpha:]",
    A = "[:^alpha:]",
    c = "[:cntrl:]",
    C = "[:^cntrl:]",
    l = "[:lower:]",
    L = "[:^lower:]",
    p = "[:punct:]",
    P = "[:^punct:]",
    u = "[:upper:]",
    U = "[:^upper:]",
    w = "[:alnum:]",
    W = "[:^alnum:]",
    x = "[:xdigit:]",
    X = "[:^xdigit:]",
    z = "\\x00",
    Z = "\\x01-\\xFF",
  }

  local function rep_normal (ch)
    assert (ch ~= "b", "\"%b\" subpattern is not supported")
    assert (ch ~= "0", "invalid capture index")
    local v = t_esc[ch]
    return v and ("[" .. v .. "]") or ("\\" .. ch)
  end

  local function rep_charclass (ch)
    return t_esc[ch] or ("\\" .. ch)
  end

  local function PatternLua2Pcre (s)
    local ind = 0

    local function getc ()
      ind = ind + 1
      return string.sub (s, ind, ind)
    end

    local function getnum ()
      local num = string.match (s, "^\\(%d%d?%d?)", ind)
      if num then
        ind = ind + #num
        return string.format ("\\x%02X", num)
      end
    end

    local out, state = "", "normal"
    while ind < #s do
      local ch = getc ()
      if state == "normal" then
        if ch == "%" then
          out = out .. rep_normal (getc ())
        elseif ch == "-" then
          out = out .. "*?"
        elseif ch == "." then
          out = out .. "\\C"
        elseif ch == "[" then
          out = out .. ch
          state = "charclass"
        else
          local num = getnum ()
          out = num and (out .. num) or (out .. ch)
        end
      elseif state == "charclass" then
        if ch == "%" then
          out = out .. rep_charclass (getc ())
        elseif ch == "]" then
          out = out .. ch
          state = "normal"
        else
          local num = getnum ()
          out = num and (out .. num) or (out .. ch)
        end
      end
    end
    return out
  end

  local subj, pat = "abcdef", "[abef]+"
  local set1 = {
    name = "Set1",
    --  { s,    p,   f,   n,     res1,  res2 },
    { subj, pat, "",  0,       subj, 0 }, -- test "n" + empty_replace
    { subj, pat, "",  1,     "cdef", 1 },
    { subj, pat, "",  2,       "cd", 2 },
    { subj, pat, "",  3,       "cd", 2 },
    { subj, pat, "",  false,   "cd", 2 },
    { subj, pat, "#", 0,       subj, 0 }, -- test "n" + non-empty_replace
    { subj, pat, "#", 1,    "#cdef", 1 },
    { subj, pat, "#", 2,     "#cd#", 2 },
    { subj, pat, "#", 3,     "#cd#", 2 },
    { subj, pat, "#", false, "#cd#", 2 },
  }

  subj, pat = "abc", "([ac])"
  local set2 = {
    name = "Set2",
    --  { s,    p,   f,        n,     res1,      res2 },
    { subj, pat, "<%1>",   false, "<a>b<c>", 2 }, -- test non-escaped chars in f
    { subj, pat, "%<%1%>", false, "<a>b<c>", 2 }, -- test escaped chars in f
    { subj, pat, "",       false, "b",       2 }, -- test empty replace
    { subj, pat, "1",      false, "1b1",     2 }, -- test odd and even %'s in f
    { subj, pat, "%1",     false, "abc",     2 },
    { subj, pat, "%%1",    false, "%1b%1",   2 },
    { subj, pat, "%%%1",   false, "%ab%c",   2 },
    { subj, pat, "%%%%1",  false, "%%1b%%1", 2 },
    { subj, pat, "%%%%%1", false, "%%ab%%c", 2 },
  }

  local set3 = {
    name = "Set3",
    --  { s,     p,      f,    n,     res1,  res2 },
    { "abc", "a",    "%0", false, "abc", 1 }, -- test (in)valid capture number
    { "abc", "a",    "%1", false, "abc", 1 },
    { "abc", "[ac]", "%1", false, "abc", 2 },
    { "abc", "(a)",  "%1", false, "abc", 1 },
    { "abc", "(a)",  "%2", false, false, 0 },
  }

  local set4 = {
    name = "Set4",
    --  { s,          p,              f,    n,     res1,       res2 },
    { "a2c3",     ".",            "#", false, "####",      4 }, -- test .
    { "a2c3",     ".+",           "#", false, "#",         1 }, -- test .+
    { "a2c3",     ".*",           "#", false, "##",        2 }, -- test .*
    { "/* */ */", "%/%*(.*)%*%/", "#", false, "#",         1 },
    { "a2c3",     ".-",           "#", false, "#a#2#c#3#", 5 }, -- test .-
    { "/**/",     "%/%*(.-)%*%/", "#", false, "#",         1 },
    { "/* */ */", "%/%*(.-)%*%/", "#", false, "# */",      1 },
    { "a2c3",     "%d",           "#", false, "a#c#",      2 }, -- test %d
    { "a2c3",     "%D",           "#", false, "#2#3",      2 }, -- test %D
    { "a \t\nb",  "%s",           "#", false, "a###b",     3 }, -- test %s
    { "a \t\nb",  "%S",           "#", false, "# \t\n#",   2 }, -- test %S
  }

  local function frep1(...) end                             -- returns nothing
  local function frep2(...) return "#" end                  -- ignores arguments
  local function frep3(...) return table.concat({...}, ",") end -- "normal"
  local function frep4(...) return {} end                   -- invalid return type

  subj = "a2c3"
  local set5 = {
    name = "Set5",
    --  { s,      p,          f,     n,     res1,        res2 },
    { subj, "a(.)c(.)", frep1, false, subj,        1 },
    { subj, "a(.)c(.)", frep2, false, "#",         1 },
    { subj, "a(.)c(.)", frep3, false, "2,3",       1 },
    { subj, "a.c.",     frep3, false, subj,        1 },
    { subj, "",         frep1, false, subj,        5 },
    { subj, "",         frep2, false, "#a#2#c#3#", 5 },
    { subj, "",         frep3, false, subj,        5 },
    { subj, subj,       frep4, false, false,       0 },
  }

  local tab1, tab2, tab3 = {}, { ["2"] = 56 }, { ["2"] = {} }
  subj = "a2c3"
  local set6 = {
    name = "Set6",
    --  { s,      p,        f,     n,     res1,  res2 },
    { subj, "a(.)c(.)", tab1,  false, subj,  1 },
    { subj, "a(.)c(.)", tab2,  false, "56",  1 },
    { subj, "a(.)c(.)", tab3,  false, false, 0 },
    { subj, "a.c.",     tab1,  false, subj,  1 },
    { subj, "a.c.",     tab2,  false, subj,  1 },
    { subj, "a.c.",     tab3,  false, subj,  1 },
  }

  subj = ""
  for i = 0, 255 do
    subj = subj .. string.char (i)
  end

  -- This set requires calling prepare_set before calling gsub_test
  local set7 = {
    name = "Set7",
    --  { s,    p,    f,  n, },
    { subj, "%a", "", false, },
    { subj, "%A", "", false, },
    { subj, "%c", "", false, },
    { subj, "%C", "", false, },
    { subj, "%l", "", false, },
    { subj, "%L", "", false, },
    { subj, "%p", "", false, },
    { subj, "%P", "", false, },
    { subj, "%u", "", false, },
    { subj, "%U", "", false, },
    { subj, "%w", "", false, },
    { subj, "%W", "", false, },
    { subj, "%x", "", false, },
    { subj, "%X", "", false, },
    { subj, "%z", "", false, },
    { subj, "%Z", "", false, },

    { subj, "[%a]", "", false, },
    { subj, "[%A]", "", false, },
    { subj, "[%c]", "", false, },
    { subj, "[%C]", "", false, },
    { subj, "[%l]", "", false, },
    { subj, "[%L]", "", false, },
    { subj, "[%p]", "", false, },
    { subj, "[%P]", "", false, },
    { subj, "[%u]", "", false, },
    { subj, "[%U]", "", false, },
    { subj, "[%w]", "", false, },
    { subj, "[%W]", "", false, },
    { subj, "[%x]", "", false, },
    { subj, "[%X]", "", false, },
    { subj, "[%z]", "", false, },
    { subj, "[%Z]", "", false, },

    { subj, "[%a_]", "", false, },
    { subj, "[%A_]", "", false, },
    { subj, "[%c_]", "", false, },
    { subj, "[%C_]", "", false, },
    { subj, "[%l_]", "", false, },
    { subj, "[%L_]", "", false, },
    { subj, "[%p_]", "", false, },
    { subj, "[%P_]", "", false, },
    { subj, "[%u_]", "", false, },
    { subj, "[%U_]", "", false, },
    { subj, "[%w_]", "", false, },
    { subj, "[%W_]", "", false, },
    { subj, "[%x_]", "", false, },
    { subj, "[%X_]", "", false, },
    { subj, "[%z_]", "", false, },
    { subj, "[%Z_]", "", false, },

    { subj, "[%a%d]", "", false, },
    { subj, "[%A%d]", "", false, },
    { subj, "[%c%d]", "", false, },
    { subj, "[%C%d]", "", false, },
    { subj, "[%l%d]", "", false, },
    { subj, "[%L%d]", "", false, },
    { subj, "[%p%d]", "", false, },
    { subj, "[%P%d]", "", false, },
    { subj, "[%u%d]", "", false, },
    { subj, "[%U%d]", "", false, },
    { subj, "[%w%d]", "", false, },
    { subj, "[%W%d]", "", false, },
    { subj, "[%x%d]", "", false, },
    { subj, "[%X%d]", "", false, },
    { subj, "[%z%d]", "", false, },
    { subj, "[%Z%d]", "", false, },

    { subj, "[^%a%d]", "", false, },
    { subj, "[^%A%d]", "", false, },
    { subj, "[^%c%d]", "", false, },
    { subj, "[^%C%d]", "", false, },
    { subj, "[^%l%d]", "", false, },
    { subj, "[^%L%d]", "", false, },
    { subj, "[^%p%d]", "", false, },
    { subj, "[^%P%d]", "", false, },
    { subj, "[^%u%d]", "", false, },
    { subj, "[^%U%d]", "", false, },
    { subj, "[^%w%d]", "", false, },
    { subj, "[^%W%d]", "", false, },
    { subj, "[^%x%d]", "", false, },
    { subj, "[^%X%d]", "", false, },
    { subj, "[^%z%d]", "", false, },
    { subj, "[^%Z%d]", "", false, },

    { subj, "[^%a_]", "", false, },
    { subj, "[^%A_]", "", false, },
    { subj, "[^%c_]", "", false, },
    { subj, "[^%C_]", "", false, },
    { subj, "[^%l_]", "", false, },
    { subj, "[^%L_]", "", false, },
    { subj, "[^%p_]", "", false, },
    { subj, "[^%P_]", "", false, },
    { subj, "[^%u_]", "", false, },
    { subj, "[^%U_]", "", false, },
    { subj, "[^%w_]", "", false, },
    { subj, "[^%W_]", "", false, },
    { subj, "[^%x_]", "", false, },
    { subj, "[^%X_]", "", false, },
    { subj, "[^%z_]", "", false, },
    { subj, "[^%Z_]", "", false, },

    { subj, "\100",          "", false, },
    { subj, "[\100]",        "", false, },
    { subj, "[^\100]",       "", false, },
    { subj, "[\100-\200]",   "", false, },
    { subj, "[^\100-\200]",  "", false, },
    { subj, "\100a",         "", false, },
    { subj, "[\100a]",       "", false, },
    { subj, "[^\100a]",      "", false, },
    { subj, "[\100-\200a]",  "", false, },
    { subj, "[^\100-\200a]", "", false, },
  }

  -- This function fills test sets with the reference results.
  --   * test positions 5 and 6 may be empty initially
  --   * this function calls string.gsub which fills the test positions 5 and 6
  --     that are further used as reference gsub results.
  --
  local function prepare_set (set)
    for k,v in ipairs(set) do
      local r0, r1, r2 = pcall (string.gsub, v[1], v[2], v[3], v[4] or nil)
      if r0 then
        v[5], v[6] = r1, r2
      else
        v[5], v[6] = r0, r1
      end
    end
  end

  -- This function operates on test sets with the following properties:
  --   * test position 4 specifies number of replacements (or false, if not limited)
  --   * test positions 5 and 6 specify reference gsub results
  -- This function does not modify test sets
  --
  local function gsub_test (set)
    local r0, r1, r2 -- results
    local function err (k, func_name)
      print("Test " .. k .. " of " .. func_name)
      print("Test Data:", unpack(set[k]))
      print("Test Results:", r1, r2, "\n")
    end
    print(set.name or "Unnamed Set")
    for k,v in ipairs(set) do
      local num = v[4] or nil

      local function run_test (f_gsub, s_gsub, f_pat)
        r0, r1, r2 = pcall (f_gsub, v[1], f_pat(v[2]), v[3], num)
        if (r0 and (r1~=v[5] or r2~=v[6])) or (not r0 and v[5]) then
          err(k, s_gsub)
        end
      end

      run_test (string.gsub, "string.gsub", function (p) return p end)
      run_test (rex.gsub,    "rex.gsub",    PatternLua2Pcre)
      run_test (gsubPCRE,    "gsubPCRE",    PatternLua2Pcre)
    end
  end

  gsub_test (set1)
  gsub_test (set2)
  gsub_test (set3)
  gsub_test (set4)
  gsub_test (set5)
  gsub_test (set6)

  prepare_set (set7)
  gsub_test (set7)

end


-- TODO: @func string.checkRegex: check regex is valid
--   @param p: regex pattern
-- @returns
--   @param f: true if regex is valid, or nil otherwise

-- TODO: @func rex.check{Posix,PCRE}Regex: check POSIX regex is valid
--   @param p: POSIX regex pattern
-- @returns
--   @param f: true if regex is valid, or nil otherwise
