-- require for Lua 4.0

-- Adapted from Jay Carlson's version posted to lua-l on 03Dec01
-- Reuben Thomas 10Jan02
-- rewrite by John Belmonte

-- Suggested uses
--   lua require.lua -f yourfilename.lua
--   #! /usr/local/bin/lua /usr/local/share/lua/require.lua -f

-- TODO: Rename this file to "std.config", and say that it must be
-- executed before using stdlib.


--------------------------------------------------------------------------------
-- stdlib configuration

-- system path of stdlib modules, no trailing separator
STDLIB_PATH = "/usr/local/share/lua"

-- system path separator
STDLIB_PATH_SEPARATOR = STDLIB_PATH_SEPARATOR or "/"

--------------------------------------------------------------------------------
-- Don't edit below here


-- Add stdlib to module search path
LUA_PATH = STDLIB_PATH .. STDLIB_PATH_SEPARATOR .. "/?.lua;" ..
  (LUA_PATH or getenv ("LUA_PATH") or "")


-- require for Lua 4.0

-- Don't define require if it's built-in
if require then
  return
end

_LOADED = {}

local exists =
  function (f)
    local h = openfile (f, "r")
    if h then
      closefile (h)
      return 1
    end
    return nil
  end

function require (name)
  if _LOADED[name] then
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
          error ("error loading `" .. filename .. "'")
        end
        _LOADED[name] = 1
        return
      end
    end
    index = s2 and (s2 + 1)
  end
  error ("could not load `" .. name .. "' from path `" .. path .. "'")
end
