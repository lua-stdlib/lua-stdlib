-- Regular expressions

-- Default constructor (use PCREs)
setmetatable (rex, {__call =
                function (self, p)
                  return self.newPCRE (p)
                end})

-- @function rex.find: string.find for rex library
--   @param s: string to search
--   @param p: pattern to find
-- returns
--   @param from, to: start and end points of match, or nil
--   @param sub: table of substring matches, or nil if none
function rex.find (s, p)
  return rex (p):match (s)
end

-- @function rex.gsub: partial string.gsub for rex
-- FIXME: Add support for back-refs in replacement string
--  @param s: string to search
--  @param p: pattern to find
--  @param f: replacement function or string
--  @param [n]: maximum number of replacements [all]
-- returns
--  @param r: string with replacements
--  @param reps: number of replacements made
function rex.gsub (s, p, f, n)
  local reg = rex (p)
  local st = 1
  local r, reps = {}, 0
  local from, to, sub
  if type (f) == "string" then
    local rep = f
    f = function ()
          return rep
        end
  end
  repeat
    from, to, sub = reg:match (s, st)
    if from then
      table.insert (r, string.sub (s, st, from - 1))
      table.insert (r, f (unpack (sub)))
      st = to + 1
      reps = reps + 1
      if n and reps == n then
        break
      end
    end
  until not from
  table.insert (r, string.sub (s, st))
  return table.concat (r), reps
end
