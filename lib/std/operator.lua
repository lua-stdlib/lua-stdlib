--[[--
 Functional Operators.

 @module std.operator
]]


--- Functional forms of Lua operators.
--
-- Defined here so that other modules can write to it.
--
--   1. `..`: concatenation
--   1. `[]`: dereference a table
--   1. `{}`: tablification
--   1. `""`: stringification
--   1. `~`: string matching
--   1. `#`: table or string length
--   1. `+`: addition
--   1. `-`: subtraction
--   1. `*`: multiplication
--   1. `/`: division
--   1. `%`: modulo
--   1. `^`: exponentiation
--   1. `and`: logical and
--   1. `or`: logical or
--   1. `not`: logical not
--   1. `==`: equality
--   1. `~=`: inequality
--   1. `<`: less than
--   1. `<=`: less than or equal
--   1. `>`: greater than
--   1. `>=`: greater than or equal
-- @table std.operator

---
return {
  [".."]  = function (a, b) return tostring (a) .. tostring (b) end,
  ["[]"]  = function (t, s) return t and t[s] or nil end,
  ["{}"]  = function (...)  return {...}   end,
  ['""']  = function (x)    return tostring (x) end,
  ["~"]   = function (s, p) return string.find (s, p) end,
  ["#"]   = function (t)    return #t end,
  ["+"]   = function (a, b) return a + b   end,
  ["-"]   = function (a, b) return a - b   end,
  ["*"]   = function (a, b) return a * b   end,
  ["/"]   = function (a, b) return a / b   end,
  ["%"]   = function (a, b) return a % b   end,
  ["^"]   = function (a, b) return math.pow (a, b) end,
  ["and"] = function (a, b) return a and b end,
  ["or"]  = function (a, b) return a or b  end,
  ["not"] = function (a)    return not a   end,
  ["=="]  = function (a, b) return a == b  end,
  ["~="]  = function (a, b) return a ~= b  end,
  ["<"]   = function (a, b) return a < b   end,
  ["<="]  = function (a, b) return a <= b  end,
  [">"]   = function (a, b) return a > b   end,
  [">="]  = function (a, b) return a >= b  end,
}
