-- import
-- Based on code by Wim Couwenberg from LTN 11
-- http://www.lua.org/notes/ltn011.html

local function packageStub (name)
  return setmetatable ({},
    {
      __index =
        function (_, index)
          error (string.format ("member `%s' is accessed before " ..
                                "package `%s' is fully imported",
                                index, name))
        end,
      __newindex =
        function(_, index, _)
          error (string.format ("member `%s' is assigned a value " ..
                                "before package `%s' is fully imported",
                                index, name))
        end,
    })
end

local function locate (name)
  local path = LUA_PATH
  if type (path) ~= "string" then
    path = os.getenv "LUA_PATH" or "?;?.lua"
  end
  for path in string.gfind (path, "[^;]+") do
    path = string.gsub (path, "?", name)
    local chunk, err = loadfile (path)
    if chunk then
      return chunk, path
    elseif err and not string.find (err, "^cannot read") then
      error (err)
    end
  end
  return false, path
end

local imported = {}

function import (name)
  local package = imported[name]
  if package then
    return package
  end
  local chunk, path = locate (name)
  if not chunk then
    error (string.format ("could not locate package `%s' in `%s'",
                          name, path))
  end
  package = packageStub (name)
  imported[name] = package
  setfenv (chunk, getfenv (2))
  chunk = chunk ()
  setmetatable (package, nil)
  if type (chunk) == "function" then
    chunk (package, name, path)
  end
  return package
end
