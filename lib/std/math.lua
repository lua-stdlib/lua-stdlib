--[[--
 Additions to the core math module.

 @module std.math
]]

local base = require "std.base"


local _floor = math.floor
local argscheck = base.argscheck


local M -- forward declaration


--- Extend `math.floor` to take the number of decimal places.
-- @number n number
-- @int[opt=0] p number of decimal places to truncate to
-- @treturn number `n` truncated to `p` decimal places
-- @usage tenths = floor (magnitude, 1)
local function floor (n, p)
  argscheck ("std.math.floor", {"number", {"int", "nil"}}, {n, p})

  if p and p ~= 0 then
    local e = 10 ^ p
    return _floor (n * e) / e
  else
    return _floor (n)
  end
end


--- Overwrite core methods with `std` enhanced versions.
--
-- Replaces core `math.floor` with `std.math` version.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
-- @usage require "std.math".monkey_patch ()
local function monkey_patch (namespace)
  namespace = namespace or _G
  assert (type (namespace) == "table",
          "bad argument #1 to 'monkey_patch' (table expected, got " .. type (namespace) .. ")")

  namespace.math.floor = floor
  return M
end


--- Round a number to a given number of decimal places
-- @number n number
-- @int[opt=0] p number of decimal places to round to
-- @treturn number `n` rounded to `p` decimal places
-- @usage roughly = round (exactly, 2)
local function round (n, p)
  argscheck ("std.math.floor", {"number", {"int", "nil"}}, {n, p})

  local e = 10 ^ (p or 0)
  return _floor (n * e + 0.5) / e
end


--- @export
local M = {
  floor        = floor,
  monkey_patch = monkey_patch,
  round        = round,
}

for k, v in pairs (math) do
  M[k] = M[k] or v
end

return M
