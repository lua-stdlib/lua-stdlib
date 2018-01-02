--[[
 General Lua Libraries for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2002-2018 stdlib authors
]]
--[[--
 Additions to the core debug module.

 The module table returned by `std.debug` also contains all of the entries
 from the core debug table.   An hygienic way to import this module, then, is
 simply to override the core `debug` locally:

      local debug = require 'std.debug'

 @corelibrary std.debug
]]


local _ENV = require 'std.normalize' {
   'debug',
   _debug = require 'std._debug',
   concat = 'table.concat',
   huge = 'math.huge',
   max = 'math.max',
   merge = 'table.merge',
   stderr = 'io.stderr',
}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local function say(n, ...)
   local level, argt = n, {...}
   if type(n) ~= 'number' then
      level, argt = 1, {n, ...}
   end
   if _debug.level ~= huge and
        ((type(_debug.level) == 'number' and _debug.level >= level) or level <= 1)
   then
      local t = {}
      for k, v in pairs(argt) do
         t[k] = str(v)
      end
      stderr:write(concat(t, '\t') .. '\n')
   end
end


local level = 0

local function trace(event)
   local t = debug.getinfo(3)
   local s = ' >>> '
   for i = 1, level do
      s = s .. ' '
   end
   if t ~= nil and t.currentline >= 0 then
      s = s .. t.short_src .. ':' .. t.currentline .. ' '
   end
   t = debug.getinfo(2)
   if event == 'call' then
      level = level + 1
   else
      level = max(level - 1, 0)
   end
   if t.what == 'main' then
      if event == 'call' then
         s = s .. 'begin ' .. t.short_src
      else
         s = s .. 'end ' .. t.short_src
      end
   elseif t.what == 'Lua' then
      s = s .. event .. ' ' ..(t.name or '(Lua)') .. ' <' ..
         t.linedefined .. ':' .. t.short_src .. '>'
   else
      s = s .. event .. ' ' ..(t.name or '(C)') .. ' [' .. t.what .. ']'
   end
   stderr:write(s .. '\n')
end

-- Set hooks according to _debug
if _debug.call then
   debug.sethook(trace, 'cr')
end



local M = {
   --- Function Environments
   -- @section environments

   --- Extend `debug.getfenv` to unwrap functables correctly.
   -- @function getfenv
   -- @tparam int|function|functable fn target function, or stack level
   -- @treturn table environment of *fn*
   getfenv = getfenv,

   --- Extend `debug.setfenv` to unwrap functables correctly.
   -- @function setfenv
   -- @tparam function|functable fn target function
   -- @tparam table env new function environment
   -- @treturn function *fn*
   setfenv = setfenv,


   --- Functions
   -- @section functions

   --- Print a debugging message to `io.stderr`.
   -- Display arguments passed through `std.tostring` and separated by tab
   -- characters when `std._debug` hinting is `true` and *n* is 1 or less;
   -- or `std._debug.level` is a number greater than or equal to *n*.   If
   -- `std._debug` hinting is false or nil, nothing is written.
   -- @function say
   -- @int[opt=1] n debugging level, smaller is higher priority
   -- @param ... objects to print(as for print)
   -- @usage
   --    local _debug = require 'std._debug'
   --    _debug.level = 3
   --    say(2, '_debug status level:', _debug.level)
   say = say,

   --- Trace function calls.
   -- Use as debug.sethook(trace, 'cr'), which is done automatically
   -- when `std._debug.call` is set.
   -- Based on test/trace-calls.lua from the Lua distribution.
   -- @function trace
   -- @string event event causing the call
   -- @usage
   --    local _debug = require 'std._debug'
   --    _debug.call = true
   --    local debug = require 'std.debug'
   trace = trace,
}


--- Metamethods
-- @section metamethods

--- Equivalent to calling `debug.say(1, ...)`
-- @function __call
-- @see say
-- @usage
--    local debug = require 'std.debug'
--    debug 'oh noes!'
local metatable = {
   __call = function(self, ...)
      M.say(1, ...)
   end,
}


return setmetatable(merge(debug, M), metatable)
