-- Math

-- Adds to the existing math module

module ("math", package.seeall)

require "base"


-- Calculate bits in an integer
local n, b = 1, 0
while n < n + 1 do
  n = n * 2
  b = b + 1
end
_INTEGER_BITS = b

-- @func floor: Extend to take the number of decimal places
--   @param n: number
--   @param [p]: number of decimal places to truncate to [0]
-- @returns
--   @param r: n truncated to p decimal places
local _floor = floor
function floor (n, p)
  local e = 10 ^ (p or 0)
  return _floor (n * e) / e
end

-- @func round: Round a number to p decimal places
--   @param n: number
--   @param [p]: number of decimal places to truncate to [0]
-- @returns
--   @param r: n to p decimal places
function round (n, p)
  local e = 10 ^ (p or 0)
  return floor (n * e + 0.5) / e
end
