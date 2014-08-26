--[[--
 Functional Operators.

 @module std.operator
]]


local base = require "std.base"


--- Functional forms of Lua operators.
--
--   1. `concat`: concatenation
--   1. `deref`: dereference a table
--   1. `cons`: tablification
--   1. `length`: table or string length
--   1. `sum`: addition
--   1. `diff`: subtraction
--   1. `prod`: multiplication
--   1. `quot`: division
--   1. `mod`: modulo
--   1. `pow`: exponentiation
--   1. `and`: logical and
--   1. `or`: logical or
--   1. `not`: logical not
--   1. `eq`: equality
--   1. `neq`: inequality
--   1. `lt`: less than
--   1. `lte`: less than or equal
--   1. `gt`: greater than
--   1. `gte`: greater than or equal
-- @table std.operator

---
return {
  concat  = function (a, b) return tostring (a) .. tostring (b) end,
  deref   = function (t, s) return t and t[s] or nil end,
  cons    = function (...)  return {...}   end,
  length  = base.len,
  sum     = function (a, b) return a + b   end,
  diff    = function (a, b) return a - b   end,
  prod    = function (a, b) return a * b   end,
  quot    = function (a, b) return a / b   end,
  mod     = function (a, b) return a % b   end,
  pow     = function (a, b) return a ^ b   end,
  ["and"] = function (a, b) return a and b end,
  ["or"]  = function (a, b) return a or b  end,
  ["not"] = function (a)    return not a   end,
  eq      = function (a, b) return a == b  end,
  neq     = function (a, b) return a ~= b  end,
  lt      = function (a, b) return a < b   end,
  lte     = function (a, b) return a <= b  end,
  gt      = function (a, b) return a > b   end,
  gte     = function (a, b) return a >= b  end,
}
