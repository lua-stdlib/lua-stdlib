--[[--
 Additions to the core math module.

 The module table returned by `std.io` also contains all of the entries from
 the core math table.  An hygienic way to import this module, then, is simply
 to override the core `math` locally:

    local math = require "std.math"

 @module std.math
]]


local base = require "std.base"


local _floor = math.floor
local argcheck, argscheck = base.argcheck, base.argscheck


local M -- forward declaration


--- Extend `math.floor` to take the number of decimal places.
-- @number n number
-- @int[opt=0] p number of decimal places to truncate to
-- @treturn number `n` truncated to `p` decimal places
-- @usage tenths = floor (magnitude, 1)
local function floor (n, p)
  argscheck ("std.math.floor", {"number", "int?"}, {n, p})

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
  argcheck ("std.math.monkey_patch", 1, "table?", namespace)
  namespace = namespace or _G

  namespace.math.floor = floor
  return M
end


--- Round a number to a given number of decimal places
-- @number n number
-- @int[opt=0] p number of decimal places to round to
-- @treturn number `n` rounded to `p` decimal places
-- @usage roughly = round (exactly, 2)
local function round (n, p)
  argscheck ("std.math.floor", {"number", "int?"}, {n, p})

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
