-- Require for Lua 4.0
-- Adapted from Jay Carlson's version posted to lua-l on 03Dec01
-- Reuben Thomas 10Jan02
-- rewrite by John Belmonte

-- Suggested uses
--   lua require.lua -f yourfilename.lua
--   #! /usr/local/bin/lua /usr/local/share/lua/require.lua -f

-- I suggest that this file be renamed to "std.config", and define the
-- policy that it must be manually executed (that is, not using require, since
-- this is not a module) before use of stdlib.  This file contains an
-- implementation of require for 4.0, but more importantly it contains
-- system configuration.  Currently the only configuration is the library
-- path, but other configuration options could be added, such as the path
-- separator character (required for platform-independent join function), etc.
--      -John

--------------------------------------------------------------------------------
-- stdlib configuration

-- system path of stdlib modules, no trailing separator
STDLIB_PATH='/usr/local/share/lua'

-- system path separator
--STDLIB_PATH_SEPARATOR='/'

--------------------------------------------------------------------------------

-- add stdlib to module search path
LUA_PATH = STDLIB_PATH..'/?.lua;'..(LUA_PATH or getenv ('LUA_PATH') or '')

-- Don't define require if it's built-in
if not require then
  -- NOTE: 5.0 uses a global _LOADED
  local loaded = {}

  local exists = function (f)
    local h = openfile (f, "r")
    if h then
      closefile (h)
      return 1
    end
    return nil
  end

  require = function (name)
    if %loaded[name] then
      return
    end
    local path = LUA_PATH or getenv ("LUA_PATH") or '?.lua'
    local index = 1
    while index do
      local s1, s2, dir = strfind (path, "([^;]+)", index)
      if dir then
        local filename = gsub (dir, '%?', name)
        if %exists (filename) then
          local result = dofile (filename)
          if not result then
            error ("error loading package `"..filename.."'")
          end
          %loaded[name] = 1
          return
        end
      end
      index = s2 and (s2 + 1)
    end
    error ("could not load package `"..name.."' from path `"..path.."'")
  end
end
