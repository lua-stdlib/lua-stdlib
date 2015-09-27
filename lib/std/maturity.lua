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
local tostring		= tostring

local io_stderr		= io.stderr
local string_format	= string.format


local _ = {
  debug_init		= require "std.debug_init",
  setenvtable		= require "std.strict".setenvtable,
}

local _DEBUG		= _.debug_init._DEBUG


local _, _ENV		= nil, _.setenvtable {}



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


local function DEPRECATED (version, name, extramsg, fn)
  if fn == nil then fn, extramsg = extramsg, nil end

  if not _DEBUG.deprecate then
    return function (...)
      io_stderr:write (DEPRECATIONMSG (version, name, extramsg, 2))
      return fn (...)
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
