-- Require for Lua 4.0
-- Adapted from Jay Carlson's version posted to lua-l on 03Dec01
-- Reuben Thomas 10Jan02

-- Suggested uses
--   lua require.lua -f yourfilename.lua
--   #! /usr/local/bin/lua /usr/local/share/lua/require.lua -f


-- Don't load if require already present (e.g. in Lua 4.1 or above)
if require then
  return
end

local Private = {loaded = {}}

local defaultPath = ":/usr/local/share/lua:/usr/share/lua"
if getenv ("HOME") then
  defaultPath = defaultPath .. ":" .. getenv ("HOME") .. "/share/lua"
end

local Public = {path = LUA_PATH or getenv ("LUA_PATH") or defaultPath}

Require = Public

function Public.require (file)
  local exists =
    function (f)
      local h = openfile (f, "r")
      if h then
        closefile (h)
        return 1
      end
      return nil
    end
  if not %Private.loaded[file] then
    local path = {}
    gsub (%Public.path, "([^:]*)",
          function (dir)
            tinsert (%path, dir)
          end)
    for i, v in path do
      %Private.loaded[file] = 1
      local file = v .. "/" .. file
      if exists (file) then
        return dofile (file)
      end
    end
    error ("required file `" .. file .. "' not found")
  end
end

require = Public.require
