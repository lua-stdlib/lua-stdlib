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
--  @param s: string to search
--  @param p: pattern to find
--  @param f: replacement function
--  @param [n]: maximum number of replacements [infinite]
-- returns
--  @param r: number of replacements made
function rex.gsub (s, p, f, n)
  return rex (p):gmatch (s, f, n)
end
