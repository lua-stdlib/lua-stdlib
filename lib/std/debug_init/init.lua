--[[
 Return a table of debug parameters.

 Before loading this module, set the global `_DEBUG` according to what
 debugging features you wish to use until the application exits.
]]


local function set (explicit, default, development, production)
  if type(_DEBUG) == "table" then
    if _DEBUG[explicit] == nil then
      return default
    end
    return _DEBUG[explicit]
  end
  if _DEBUG == false then
    return production
  elseif _DEBUG == nil then
    return default
  end
  return development
end


return {
  _DEBUG = {
    -- _G._DEBUG is: table[name]   nil   true    false
    -- ------------------------------------------------
    argcheck  = set ("argcheck",  true,  true,   false),
    call      = set ("call",      false, false,  false),
    deprecate = set ("deprecate", nil,   true,   false),
    level     = set ("level",     1,     1,      math.huge),
    strict    = set ("strict",    true,  true,   false),
  },
}
