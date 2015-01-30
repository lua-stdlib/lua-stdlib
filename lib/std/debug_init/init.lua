-- Debugging is on by default
local M = {}

-- Use rawget to satisfy std.strict.
local _DEBUG = rawget (_G, "_DEBUG")

-- User specified fields.
if type (_DEBUG) == "table" then
  M._DEBUG = _DEBUG

-- Turn everything off.
elseif _DEBUG == false then
  M._DEBUG  = {
    argcheck  = false,
    call      = false,
    deprecate = false,
    level     = math.huge,
  }

-- Turn everything on (except _DEBUG.call must be set explicitly).
elseif _DEBUG == true then
  M._DEBUG  = {
    argcheck  = true,
    call      = false,
    deprecate = true,
  }

else
  M._DEBUG  = {}
end


local function setdefault (field, value)
  if M._DEBUG[field] == nil then
    M._DEBUG[field] = value
  end
end


-- Default settings if otherwise unspecified.
setdefault ("argcheck", true)
setdefault ("call", false)
setdefault ("deprecate", nil)
setdefault ("level", 1)


return M
