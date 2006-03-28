-- Math

-- Adds to the existing math module

module ("math-ext", package.seeall)

require "base-ext"


-- Calculate bits in an integer
local n, b = 1, 0
while n < n + 1 do
  n = n * 2
  b = b + 1
end
math._INTEGER_BITS = b

-- @func math.max: Extend to work on lists
--   @param (l: list
--          ( or
--   @param (v1 ... @param vn: values
-- @returns
--   @param m: max value
math.max = listable (math.max)

-- @func math.min: Extend to work on lists
--   @param (l: list
--          ( or
--   @param (v1 ... @param vn: values
-- @returns
--   @param m: min value
math.min = listable (math.min)

-- @func math.floor: Extend to take the number of decimal places
--   @param n: number
--   @param [p]: number of decimal places to truncate to [0]
-- @returns
--   @param r: n truncated to p decimal places
local floor = math.floor
function math.floor (n, p)
  local e = 10 ^ (p or 0)
  return floor (n * e) / e
end

-- @func math.round: Round a number to p decimal places
--   @param n: number
--   @param [p]: number of decimal places to truncate to [0]
-- @returns
--   @param r: n to p decimal places
function math.round (n, p)
  local e = 10 ^ (p or 0)
  return floor (n * e + 0.5) / e
end
