--[[--
 Base implementations of functions exported by `std.functional`.

 These functions are required by implementations of exported functions
 in other stdlib modules.  We keep them here to avoid bloating std.base,
 which is loaded by *every* stdlib module.

 @module std.base.functional
]]


local function callable (x)
  if type (x) == "function" then return true end
  return type ((getmetatable (x) or {}).__call) == "function"
end


local function map (mapfn, ifn, ...)
  local argt = {...}
  if not callable (ifn) or not next (argt) then
    ifn, argt = pairs, {ifn, ...}
  end

  local nextfn, state, k = ifn (unpack (argt))
  local mapargs = {nextfn (state, k)}

  local r = {}
  while mapargs[1] ~= nil do
    k = mapargs[1]
    local d, v = mapfn (unpack (mapargs))
    if v == nil then d, v = #r + 1, d end
    if v ~= nil then
      r[d] = v
    end
    mapargs = {nextfn (state, k)}
  end
  return r
end


local function reduce (fn, d, ifn, ...)
  local nextfn, state, k = ifn (...)
  local t = {nextfn (state, k)}

  local r = d
  while t[1] ~= nil do
    r = fn (r, t[#t])
    t = {nextfn (state, t[1])}
  end
  return r
end


return {
  callable = callable,
  map      = map,
  reduce   = reduce,
}
