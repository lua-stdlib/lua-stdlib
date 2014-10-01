-- Debugging is on by default
local M = {}

-- User specified fields.
if type (_G._DEBUG) == "table" then
  M._DEBUG = _G._DEBUG

-- Turn everything off.
elseif _G._DEBUG == false then
  M._DEBUG  = {
    argcheck  = false,
    call      = false,
    deprecate = false,
    level     = math.huge,
  }

-- Turn everything on (except _DEBUG.call must be set explicitly).
elseif _G._DEBUG == true then
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
