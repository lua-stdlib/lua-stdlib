-- Logic

require "std.data.code"


-- @func band: Extend to work on lists
--   @param (l: list
--   ( or
--   @param (v1 ... @param vn: numbers
-- returns
--   @param m: logical and of numbers
band = listable (band)

-- @func bor: Extend to work on lists
--   @param (l: list
--   ( or
--   @param (v1 ... @param vn: numbers
-- returns
--   @param m: logical or of numbers
bor = listable (bor)

-- @func bxor: Extend to work on lists
--   @param (l: list
--   ( or
--   @param (v1 ... @param vn: numbers
-- returns
--   @param m: logical exclusive-or of numbers
bxor = listable (bxor)
