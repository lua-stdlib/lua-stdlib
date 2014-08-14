--[[--
 Base implementations of functions exported by `std.functional`.

 The only reason to keep these here is to support deprecated access points
 to the shared implementations, where they are only loaded when actually
 needed, rather than cluttering `std.base`.

 These will be merged back into `std.functional` when the deprecated access
 points are no longer supported.

 @module std.base.functional
]]


local base     = require "std.base"
local operator = require "std.operator"


local ipairs, ireverse, len = base.ipairs, base.ireverse, base.len


local function callable (x)
  if type (x) == "function" then return true end
  return type ((getmetatable (x) or {}).__call) == "function"
end


local function memoize (fn, normalize)
  if normalize == nil then
    -- Call require here, to avoid pulling in all of 'std.string'
    -- even when memoize is never called.
    normalize = function (...) return require "std.base".tostring {...} end
  end

  return setmetatable ({}, {
    __call = function (self, ...)
               local k = normalize (...)
               local t = self[k]
               if t == nil then
                 t = {fn (...)}
                 self[k] = t
               end
               return unpack (t)
             end
  })
end


local function nop () end


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


local function foldl (fn, d, t)
  if t == nil then
    local tail = {}
    for i = 2, len (d) do tail[#tail + 1] = d[i] end
    d, t = d[1], tail
  end
  return reduce (fn, d, ipairs, t)
end


local function foldr (fn, d, t)
  if t == nil then
    local u, last = {}, len (d)
    for i = 1, last - 1 do u[#u + 1] = d[i] end
    d, t = d[last], u
  end
  return reduce (function (x, y) return fn (y, x) end, d, ipairs, ireverse (t))
end


return {
  callable = callable,
  foldl    = foldl,
  foldr    = foldr,
  memoize  = memoize,
  nop      = nop,
  reduce   = reduce,
}
