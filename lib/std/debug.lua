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


local _deprecation = require 'std._deprecation'
local tc = require 'std._base'.typecheck or {}

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
   --- Deprecation
   -- @section deprecation

   --- Wrap a deprecated function to warn the first time it is called.
   -- Unless `std._debug.deprecate` is `false`, the warning goes to
   -- stderr; with `std._debug.deprecate` set to `true`, the deprecated
   -- function is not defined at all.
   -- @function DEPRECATED
   -- @string version first deprecation release version
   -- @string name function name for automatic warning message
   -- @string[opt] extramsg additional warning text
   -- @func fn deprecated function
   -- @treturn function|nil a function that warns on its first call, and
   --    hands off to *fn*; or `nil` if `std._debug.deprecate` is `true`
   -- @usage
   --    M.op = DEPRECATED('41', "'std.functional.op'", std.operator)
   DEPRECATED = _deprecation.DEPRECATED,

   --- Format a deprecation warning message.
   -- @function DEPRECATIONMSG
   -- @string version first deprecation release version
   -- @string name function name for automatic warning message
   -- @string[opt] extramsg additional warning text
   -- @tparam int|false level call stack level to blame for the warning,
   --    or `false` to blame nothing
   -- @treturn string the warning, or an empty string unless
   --    `std._debug.deprecate` is `nil`
   -- @usage
   --    io.stderr:write(DEPRECATIONMSG('42', "multi-argument 'module.fname'", 2))
   DEPRECATIONMSG = _deprecation.DEPRECATIONMSG,

   --- Argument Checking
   -- These are typecheck's functions, when it is installed.  Otherwise,
   -- `argcheck` and `argscheck` check nothing, as when
   -- `std._debug.argcheck` is `false`, and the rest are not defined.
   -- @section argcheck

   --- Check the type of an argument against an expected type.
   -- @function argcheck
   -- @see typecheck.argcheck
   argcheck = tc.argcheck or function(...)
      return ...
   end,

   --- Raise a bad argument error.
   -- @function argerror
   -- @see typecheck.argerror
   argerror = tc.argerror,

   --- Wrap a function definition with argument type and arity checking.
   -- @function argscheck
   -- @see typecheck.argscheck
   argscheck = tc.argscheck or function(_, inner)
      return inner or setmetatable({}, {
         __concat = function(_, concat_inner)
            return concat_inner
         end,
      })
   end,

   --- Format a type mismatch error.
   -- @function extramsg_mismatch
   -- @see typecheck.extramsg_mismatch
   extramsg_mismatch = tc.extramsg_mismatch,

   --- Format a too many things error.
   -- @function extramsg_toomany
   -- @see typecheck.extramsg_toomany
   extramsg_toomany = tc.extramsg_toomany,

   --- Compact permutation list into a list of valid types at each argument.
   -- @function parsetypes
   -- @see typecheck.parsetypes
   parsetypes = tc.parsetypes,

   --- Raise a bad result error.
   -- @function resulterror
   -- @see typecheck.resulterror
   resulterror = tc.resulterror,

   --- Split a typespec string into a table of normalized type names.
   -- @function typesplit
   -- @see typecheck.typesplit
   typesplit = tc.typesplit,

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
