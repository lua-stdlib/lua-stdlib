-- Regular expressions

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
  if type (f) == "string" then
    local rep = f
    f = function (...)
          local ret = rep
          local function repfun (percent, d)
            if math.mod (string.len (percent), 2) == 1 then
              d = arg[tonumber (d)]
              assert (d ~= nil, "invalid capture index")
              d = d or "" -- capture can be false
              percent = string.sub (percent, 2)
            end
            return percent .. d
          end
          ret = string.gsub (ret, "(%%+)([1-9])", repfun)
          ret = string.gsub (ret, "%%(.)", "%1")
          return ret
        end
  end
  local reg = rex (p, cf, lo)
  local st = 1
  local r, reps = {}, 0
  while (not n) or reps < n do
    local from, to, cap = reg:match (s, st, ef)
    if not from then break; end
    table.insert (r, string.sub (s, st, from - 1))
    if table.getn (cap) == 0 then
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
