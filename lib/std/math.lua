--[[--
 Additions to the core math module.

 The module table returned by `std.math` also contains all of the entries from
 the core math table.  An hygienic way to import this module, then, is simply
 to override the core `math` locally:

    local math = require "std.math"

 @corelibrary std.math
]]


local _ENV, _DEBUG = _G, require "std.debug_init"._DEBUG

if _DEBUG.strict then
  _ENV = require "std.strict" (setmetatable ({}, {__index = _G}))
  if rawget (_G, "setfenv") then setfenv (1, _ENV) end
end


local std = require "std.base"

local M


local _floor  = math.floor

local function floor (n, p)
  if p and p ~= 0 then
    local e = 10 ^ p
    return _floor (n * e) / e
  else
    return _floor (n)
  end
end


local function monkey_patch (namespace)
  namespace = namespace or _G
  namespace.math = std.base.copy (namespace.math or {}, M)
  return M
end


local function round (n, p)
  local e = 10 ^ (p or 0)
  return _floor (n * e + 0.5) / e
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return require "std.debug".argscheck ("std.math." .. decl, fn)
end


M = {
  --- Core Functions
  -- @section corefuncs

  --- Extend `math.floor` to take the number of decimal places.
  -- @function floor
  -- @number n number
  -- @int[opt=0] p number of decimal places to truncate to
  -- @treturn number `n` truncated to `p` decimal places
  -- @usage tenths = floor (magnitude, 1)
  floor = X ("floor (number, ?int)", floor),

  --- Round a number to a given number of decimal places
  -- @function round
  -- @number n number
  -- @int[opt=0] p number of decimal places to round to
  -- @treturn number `n` rounded to `p` decimal places
  -- @usage roughly = round (exactly, 2)
  round = X ("round (number, ?int)", round),


  --- Module Functions
  -- @section modulefuncs

  --- Overwrite core `math` methods with `std` enhanced versions.
  -- @function monkey_patch
  -- @tparam[opt=_G] table namespace where to install global functions
  -- @treturn table the module table
  -- @usage require "std.math".monkey_patch ()
  monkey_patch = X ("monkey_patch (?table)", monkey_patch),
}


return std.base.merge (M, math)
