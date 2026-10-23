--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Debug hints, deprecated.

 This is the 41.x `std.debug_init` API, deprecated in favour of the
 hints in 'std._debug', which its `_DEBUG` table reads and writes:

      local _DEBUG = require 'std.debug_init'._DEBUG
      _DEBUG.argcheck = false   -- the same as:
      require 'std._debug'.argcheck = false

 Requiring it writes a deprecation warning to stderr, unless
 `std._debug.deprecate` is `false`; with `std._debug.deprecate` set to
 `true`, it raises an error, as if it were not installed.

 @module std.debug_init
]]


local _ = require 'std._base'  -- applies any `_DEBUG` global

local _debug = require 'std._debug'
local DEPRECATIONMSG = require 'std._deprecation'.DEPRECATIONMSG

local MSG = "use 'std._debug' instead"

if _debug.deprecate == true then
   error("module 'std.debug_init' was removed in release 42, " .. MSG, 2)
end

io.stderr:write(DEPRECATIONMSG('42', "'std.debug_init'", MSG, 3))

return {
   _DEBUG = setmetatable({}, {__index = _debug, __newindex = _debug}),
}
