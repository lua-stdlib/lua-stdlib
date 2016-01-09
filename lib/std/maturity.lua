--[[--
 API Maturity.

 Rather than suddenly changing or removing APIs between releases of a
 library use these functions to support deprecated calls for a time
 first, while issuing warnings to the caller.

 The verbosity of APIs deprecated with these functions is controlled by
 the global `_DEBUG` variable, which must be set before any `stdlib`
 modules are loaded.  This declaration will disable deprecation, so
 that deprecated APIs will behave normally:

     _DEBUG = { deprecate = false }

 Alternatively, without affecting the global environment, the following
 style causes deprecated APIs to be undefined so that you can easily
 check whether your code is still using deprecated calls:

     local init = require "std.debug_init"
     init._DEBUG.deprecate = true

 Not setting `_DEBUG.deprecate` will warn on every call to deprecated
 APIs.

 @module std.maturity
]]

local error		= error
local pcall		= pcall
local select		= select
local tostring		= tostring

local io_stderr		= io.stderr
local string_format	= string.format
local table_unpack	= table.unpack or unpack


local _ = {
  debug_init		= require "std.debug_init",
  strict		= require "std.strict",
}

local _DEBUG		= _.debug_init._DEBUG


local _, _ENV		= nil, _.strict {}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local function DEPRECATIONMSG (version, name, extramsg, level)
  if level == nil then level, extramsg = extramsg, nil end
  extramsg = extramsg or "and will be removed entirely in a future release"

  local _, where = pcall (function () error ("", level + 3) end)
  if _DEBUG.deprecate == nil then
    return (where .. string_format ("%s was deprecated in release %s, %s.\n",
                                    name, tostring (version), extramsg))
  end

  return ""
end


local function result_pack (...)
  return {n = select ("#", ...), ...}
end


local function DEPRECATED (version, name, extramsg, fn)
  if fn == nil then fn, extramsg = extramsg, nil end

  if not _DEBUG.deprecate then
    return function (...)
      io_stderr:write (DEPRECATIONMSG (version, name, extramsg, 2))

      -- `return fn (...)` is subject to tail call elimination, which
      -- would lose a stack frame and change the `level` argument
      -- required for frame counting functions, so we do this instead:
      local r = result_pack (fn (...))
      return table_unpack (r, 1, r.n)
    end
  end
end


return {
  --- Provide a deprecated function definition according to _DEBUG.deprecate.
  -- You can check whether your covered code uses deprecated functions by
  -- setting `_DEBUG.deprecate` to  `true` before loading any stdlib modules,
  -- or silence deprecation warnings by setting `_DEBUG.deprecate = false`.
  -- @function DEPRECATED
  -- @string version first deprecation release version
  -- @string name function name for automatic warning message
  -- @string[opt] extramsg additional warning text
  -- @func fn deprecated function
  -- @return a function to show the warning on first call, and hand off to *fn*
  -- @usage
  -- M.op = DEPRECATED ("41", "'std.functional.op'", std.operator)
  DEPRECATED = DEPRECATED,

  --- Format a deprecation warning message.
  -- @function DEPRECATIONMSG
  -- @string version first deprecation release version
  -- @string name function name for automatic warning message
  -- @string[opt] extramsg additional warning text
  -- @int level call stack level to blame for the error
  -- @treturn string deprecation warning message, or empty string
  -- @usage
  -- io.stderr:write (DEPRECATIONMSG ("42", "multi-argument 'module.fname'", 2))
  DEPRECATIONMSG = DEPRECATIONMSG,
}
