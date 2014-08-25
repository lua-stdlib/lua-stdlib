--[[--
 Prevent dependency loops with key function implementations.

 A few key functions are used in several stdlib modules; we implement those
 functions in this internal module to prevent dependency loops in the first
 instance, and to minimise coupling between modules where the use of one of
 these functions might otherwise load a whole selection of other supporting
 modules unnecessarily.

 Although the implementations are here for logistical reasons, we re-export
 them from their respective logical modules so that the api is not affected
 as far as client code is concerned. The functions in this file do not make
 use of `argcheck` or similar, because we know that they are only called by
 other stdlib functions which have already performed the necessary checking
 and neither do we want to slow everything down by recheckng those argument
 types here.

 This implies that when re-exporting from another module when argument type
 checking is in force, we must export a wrapper function that can check the
 user's arguments fully at the API boundary.

 @module std.base
]]


local callable = require "std.base.functional".callable
local bstring  = require "std.base.string"
local copy, render, split = bstring.copy, bstring.render, bstring.split



local function len (t)
  -- Lua < 5.2 doesn't call `__len` automatically!
  local m = (getmetatable (t) or {}).__len
  return m and m (t) or #t
end


local _pairs = pairs

-- Respect __pairs metamethod, even in Lua 5.1.
local function pairs (t)
  return ((getmetatable (t) or {}).__pairs or _pairs) (t)
end


-- Iterate over keys 1..#l, like Lua 5.3.
local function ipairs (l)
  local tlen = len (l)

  return function (l, n)
    n = n + 1
    if n <= tlen then
      return n, l[n]
    end
  end, l, 0
end


local function ripairs (t)
  return function (t, n)
    n = n - 1
    if n > 0 then
      return n, t[n]
    end
  end, t, len (t) + 1
end


-- Be careful not to compact holes from `t` when reversing.
local function ireverse (t)
  local r, tlen = {}, len (t)
  for i = 1, tlen do r[tlen - i + 1] = t[i] end
  return r
end


local function getmetamethod (x, n)
  local _, m = pcall (function (x)
                        return getmetatable (x)[n]
                      end,
                      x)
  if type (m) ~= "function" then
    m = nil
  end
  return m
end


--- Iterator adaptor for discarding first value from core iterator function.
-- @func factory iterator to be wrapped
-- @param ... *factory* arguments
-- @treturn function iterator that discards first returned value of
--   factory iterator
-- @return invariant state from *factory*
-- @return `true`
-- @usage
-- for v in wrapiterator (ipairs {"a", "b", "c"}) do process (v) end
local function wrapiterator (factory, ...)
  -- Capture wrapped ctrl variable into an upvalue...
  local fn, istate, ctrl = factory (...)
  -- Wrap the returned iterator fn to maintain wrapped ctrl.
  return function (state, _)
           local v
	   ctrl, v = fn (state, ctrl)
	   if ctrl then return v end
	 end, istate, true -- wrapped initial state, and wrapper ctrl
end


local function elems (t)
  return wrapiterator ((getmetatable (t) or {}).__pairs or pairs, t)
end


local function ielems (l)
  return wrapiterator (ipairs, l)
end


local function assert (expect, f, arg1, ...)
  local msg = (arg1 ~= nil) and string.format (f, arg1, ...) or f or ""
  return expect or error (msg, 2)
end


local function compare (l, m)
  for i = 1, math.min (#l, #m) do
    local li, mi = tonumber (l[i]), tonumber (m[i])
    if li == nil or mi == nil then
      li, mi = l[i], m[i]
    end
    if li < mi then
      return -1
    elseif li > mi then
      return 1
    end
  end
  if #l < #m then
    return -1
  elseif #l > #m then
    return 1
  end
  return 0
end


local function eval (s)
  return loadstring ("return " .. s)()
end


local function vcompare (a, b)
  return compare (split (a, "%."), split (b, "%."))
end


local _require = require

local function require (module, min, too_big, pattern)
  local m = _require (module)
  local v = (m.version or m._VERSION or ""):match (pattern or "([%.%d]+)%D*$")
  if min then
    assert (vcompare (v, min) >= 0, "require '" .. module ..
            "' with at least version " .. min .. ", but found version " .. v)
  end
  if too_big then
    assert (vcompare (v, too_big) < 0, "require '" .. module ..
            "' with version less than " .. too_big .. ", but found version " .. v)
  end
  return m
end


local _tostring = _G.tostring

local function tostring (x)
  return render (x,
                 function () return "{" end,
		 function () return "}" end,
                 _tostring,
                 function (_, _, _, is, vs) return is .."=".. vs end,
		 function (_, i, _, j) return i and j and "," or "" end)
end



--[[ ========================= ]]--
--[[ Documented in object.lua. ]]--
--[[ ========================= ]]--


local function prototype (o)
  return (getmetatable (o) or {})._type or io.type (o) or type (o)
end


--- Metamethods
-- @section Metamethods

return setmetatable ({
  len = len,

  -- std.lua --
  assert   = assert,
  case     = case,
  eval     = eval,
  elems    = elems,
  ielems   = ielems,
  ipairs   = ipairs,
  ireverse = ireverse,
  pairs    = pairs,
  ripairs  = ripairs,
  require  = require,
  tostring = tostring,

  -- functional.lua --
  nop = function () end,

  -- list.lua --
  compare = compare,

  -- object.lua --
  prototype = prototype,

  -- string.lua --
  render   = render,
  split    = split,

  -- table.lua --
  getmetamethod = getmetamethod,

}, {

  --- Lazy loading of shared base modules.
  -- Don't load everything on initial startup, wait until first attempt
  -- to access a submodule, and then load it on demand.
  -- @function __index
  -- @string name submodule name
  -- @treturn table|nil the submodule that was loaded to satisfy the missing
  --   `name`, otherwise `nil` if nothing was found
  -- @usage
  -- local base    = require "base"
  -- local memoize = base.functional.memoize
  __index = function (self, name)
              local ok, t = pcall (require, "std.base." .. name)
              if ok then
		rawset (self, name, t)
		return t
	      end
	    end,
})
