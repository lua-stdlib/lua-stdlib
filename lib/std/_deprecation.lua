--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Warn about the APIs that stdlib keeps for compatibility with 41.x.

 Like the rest of stdlib, these obey `std._debug.deprecate`:

  - `nil` (the default): deprecated APIs write a warning to stderr the
    first time each one is used in a run;
  - `false`: deprecated APIs work without a warning;
  - `true`: deprecated APIs are not defined at all.

 This internal module depends on nothing else in stdlib, so that it can
 move into a package of its own when something outside stdlib needs it.
]]


local _ENV = require 'std.normalize' {
   _debug = require 'std._debug',
   format = 'string.format',
   stderr = 'io.stderr',
}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local function DEPRECATIONMSG(version, name, extramsg, level)
   if level == nil then
      level, extramsg = extramsg, nil
   end
   if _debug.deprecate ~= nil then
      return ''
   end
   local where = ''
   if level then
      where = select(2, pcall(function()
         error('', level + 3)
      end))
   end
   return format('%s%s was deprecated in release %s, %s.\n', where, name,
      tostring(version), extramsg or 'and will be removed entirely in a future release')
end


local function DEPRECATED(version, name, extramsg, fn)
   if fn == nil then
      fn, extramsg = extramsg, nil
   end
   if not _debug.deprecate then
      local warned = false
      return function(...)
         if not warned then
            warned = true
            stderr:write(DEPRECATIONMSG(version, name, extramsg, 2))
         end
         return fn(...)
      end
   end
end



--[[ ============= ]]--
--[[ Internal API. ]]--
--[[ ============= ]]--


return {
   --- Wrap a deprecated function to warn the first time it is called.
   -- @function DEPRECATED
   -- @string version first deprecation release version
   -- @string name function name for automatic warning message
   -- @string[opt] extramsg additional warning text
   -- @func fn deprecated function
   -- @treturn function|nil a function that writes the warning on its
   --    first call, unless `std._debug.deprecate` is `false`, and hands
   --    off to *fn*; or `nil` if `std._debug.deprecate` is `true`
   -- @usage
   --    M.okeys = DEPRECATED('42', "'std.table.okeys'", okeys)
   DEPRECATED = DEPRECATED,

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
   --    stderr:write(DEPRECATIONMSG('42', "multi-argument 'module.fname'", 2))
   DEPRECATIONMSG = DEPRECATIONMSG,
}
