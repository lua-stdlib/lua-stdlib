-- Bitwise logic

-- Modifies the existing bit module

module ("bit-ext", package.seeall)

require "base-ext"


-- @func band: Extend to work on lists
--   @param (l: list
--   ( or
--   @param (v1 ... @param vn: numbers
-- @returns
--   @param m: logical and of numbers
bit.band = listable (bit.band)

-- @func bor: Extend to work on lists
--   @param (l: list
--   ( or
--   @param (v1 ... @param vn: numbers
-- @returns
--   @param m: logical or of numbers
bit.bor = listable (bit.bor)

-- @func bxor: Extend to work on lists
--   @param (l: list
--   ( or
--   @param (v1 ... @param vn: numbers
-- @returns
--   @param m: logical exclusive-or of numbers
bit.bxor = listable (bit.bxor)
