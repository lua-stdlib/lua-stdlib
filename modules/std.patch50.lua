-- Patches for buggy standard library functions and implementations of
-- missing functions in Lua 5.0

require "std.data.global"


if strsub (_VERSION, 1, 7) == "Lua 5.0" then

  -- Make sort return its result
  local _sort = table.sort
  function table.sort (t, c)
    _sort (t, c)
    return t
  end
  
  -- Make PI unassignable
  PI = newConstant (PI)

end
