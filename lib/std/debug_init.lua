-- Debugging is on by default
local M = {
  _DEBUG    = true,
  _ARGCHECK = true,
}

if _G._DEBUG ~= nil then
  M._DEBUG = _G._DEBUG
end


-- Argument checking is on by default
M._ARGCHECK = M._DEBUG
if type (M._DEBUG) == "table" then
  M._ARGCHECK = M._DEBUG.argcheck
  if M._ARGCHECK == nil then M._ARGCHECK= true end
end


return M
