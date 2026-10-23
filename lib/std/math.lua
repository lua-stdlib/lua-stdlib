--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Additions to the core math module.

 The module table returned by `std.math` also contains all of the entries from
 the core math table.   An hygienic way to import this module, then, is simply
 to override the core `math` locally:

      local math = require 'std.math'

 @corelibrary std.math
]]


local _ = require 'std._base'

local DEPRECATED = require 'std._deprecation'.DEPRECATED
local argscheck = _.typecheck and _.typecheck.argscheck

_ = nil


local global = _G


local _ENV = require 'std.normalize' {
   'math',
   merge = 'table.merge',
}



--[[ ================= ]]--
--[[ Implementatation. ]]--
--[[ ================= ]]--


local M


local _floor = math.floor

local function floor(n, p)
   if(p or 0) == 0 then
      return _floor(n)
   end
   local e = 10 ^ p
   return _floor(n * e) / e
end


local function monkey_patch(namespace)
   namespace = namespace or global
   local math = namespace.math or {}
   for k, v in next, M do
      math[k] = v
   end
   namespace.math = math
   return M
end


local function round(n, p)
   local e = 10 ^(p or 0)
   return _floor(n * e + 0.5) / e
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X(decl, fn)
   return argscheck and argscheck('std.math.' .. decl, fn) or fn
end


M = {
   --- Core Functions
   -- @section corefuncs

   --- Extend `math.floor` to take the number of decimal places.
   -- @function floor
   -- @number n number
   -- @int[opt=0] p number of decimal places to truncate to
   -- @treturn number `n` truncated to `p` decimal places
   -- @usage
   --    tenths = floor(magnitude, 1)
   floor = X('floor(number, [?int])', floor),

   --- Round a number to a given number of decimal places.
   -- @function round
   -- @number n number
   -- @int[opt=0] p number of decimal places to round to
   -- @treturn number `n` rounded to `p` decimal places
   -- @usage
   --    roughly = round(exactly, 2)
   round = X('round(number, [?int])', round),

   --- Deprecated Functions
   -- @section deprecated

   --- Overwrite core `math` methods with `std` enhanced versions.
   -- @function monkey_patch
   -- @tparam[opt=_G] table namespace where to install global functions
   -- @treturn table the module table
   -- @usage
   --    require 'std.math'.monkey_patch()
   monkey_patch = DEPRECATED('42', "'std.math.monkey_patch'",
      X('monkey_patch([?table])', monkey_patch)),
}


return merge(math, M)
