-- Math

import "std.base"


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
