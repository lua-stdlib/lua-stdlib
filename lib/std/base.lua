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


local function argerror (name, i, extramsg, level)
  level = level or 1
  local s = string.format ("bad argument #%d to '%s'", i, name)
  if extramsg ~= nil then
    s = s .. " (" .. extramsg .. ")"
  end
  error (s, level + 1)
end


local function assert (expect, fmt, arg1, ...)
  local msg = (arg1 ~= nil) and string.format (fmt, arg1, ...) or fmt or ""
  return expect or error (msg, 2)
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


local function callable (x)
  if type (x) == "function" then return x end
  return  getmetamethod (x, "__call")
end


-- Lua < 5.2 doesn't call `__len` automatically!
local function len (t)
  local m = getmetamethod (t, "__len")
  return m and m (t) or #t
end


local function ipairs (l)
  local lenl = len (l)

  return function (l, n)
    n = n + 1
    if n <= lenl then
      return n, l[n]
    end
  end, l, 0
end


local function collect (ifn, ...)
  local argt = {...}
  if not callable (ifn) then
    ifn, argt = ipairs, {ifn, ...}
  end

  local r = {}
  for k, v in ifn (unpack (argt)) do
    if v == nil then k, v = #r + 1, k end
    r[k] = v
  end
  return r
end


local function compare (l, m)
  local lenl, lenm = len (l), len (m)
  for i = 1, math.min (lenl, lenm) do
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
  if lenl < lenm then
    return -1
  elseif lenl > lenm then
    return 1
  end
  return 0
end


local _pairs = pairs

-- Respect __pairs metamethod, even in Lua 5.1.
local function pairs (t)
  return (getmetamethod (t, "__pairs") or _pairs) (t)
end


local function copy (dest, src)
  if src == nil then dest, src = {}, dest end
  for k, v in pairs (src) do dest[k] = v end
  return dest
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
  return wrapiterator (pairs, t)
end


local function eval (s)
  return loadstring ("return " .. s)()
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


local function ielems (l)
  return wrapiterator (ipairs, l)
end


local _insert = table.insert

local function insert (t, pos, v)
  if v == nil then pos, v = len (t) + 1, pos end
  if pos < 1 or pos > len (t) + 1 then
    argerror ("std.table.insert", 2, "position " .. pos .. " out of bounds", 2)
  end
  _insert (t, pos, v)
  return t
end


-- Be careful not to compact holes from `t` when reversing.
local function ireverse (t)
  local r, tlen = {}, len (t)
  for i = 1, tlen do r[tlen - i + 1] = t[i] end
  return r
end


local function last (t) return t[len (t)] end


local function leaves (it, tr)
  local function visit (n)
    if type (n) == "table" then
      for _, v in it (n) do
        visit (v)
      end
    else
      coroutine.yield (n)
    end
  end
  return coroutine.wrap (visit), tr
end


local function merge (dest, src)
  for k, v in pairs (src) do dest[k] = dest[k] or v end
  return dest
end


local function prototype (o)
  return (getmetatable (o) or {})._type or io.type (o) or type (o)
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


-- Write pretty-printing based on:
--
--   John Hughes's and Simon Peyton Jones's Pretty Printer Combinators
--
--   Based on "The Design of a Pretty-printing Library in Advanced
--   Functional Programming", Johan Jeuring and Erik Meijer (eds), LNCS 925
--   http://www.cs.chalmers.se/~rjmh/Papers/pretty.ps
--   Heavily modified by Simon Peyton Jones, Dec 96
--
--   Haskell types:
--   data Doc     list of lines
--   quote :: Char -> Char -> Doc -> Doc    Wrap document in ...
--   (<>) :: Doc -> Doc -> Doc              Beside
--   (<+>) :: Doc -> Doc -> Doc             Beside, separated by space
--   ($$) :: Doc -> Doc -> Doc              Above; if there is no overlap it "dovetails" the two
--   nest :: Int -> Doc -> Doc              Nested
--   punctuate :: Doc -> [Doc] -> [Doc]     punctuate p [d1, ... dn] = [d1 <> p, d2 <> p, ... dn-1 <> p, dn]
--   render      :: Int                     Line length
--               -> Float                   Ribbons per line
--               -> (TextDetails -> a -> a) What to do with text
--               -> a                       What to do at the end
--               -> Doc                     The document
--               -> a                       Result

local function render (x, open, close, elem, pair, sep, roots)
  local function stop_roots (x)
    return roots[x] or render (x, open, close, elem, pair, sep, copy (roots))
  end
  roots = roots or {}
  if type (x) ~= "table" or type ((getmetatable (x) or {}).__tostring) == "function" then
    return elem (x)
  else
    local r = {}
    r[#r + 1] =  open (x)
    roots[x] = elem (x)

    -- create a sorted list of keys
    local ord = {}
    for k, _ in pairs (x) do ord[#ord + 1] = k end
    table.sort (ord, function (a, b) return tostring (a) < tostring (b) end)

    -- render x elements in order
    local i, v = nil, nil
    for _, j in ipairs (ord) do
      local w = x[j]
      r[#r + 1] = sep (x, i, v, j, w) .. pair (x, j, w, stop_roots (j), stop_roots (w))
      i, v = j, w
    end
    r[#r + 1] = sep (x, i, v, nil, nil) .. close (x)
    return table.concat (r)
  end
end


local function ripairs (t)
  return function (t, n)
    n = n - 1
    if n > 0 then
      return n, t[n]
    end
  end, t, len (t) + 1
end


local function split (s, sep)
  local r, patt = {}
  if sep == "" then
    patt = "(.)"
    insert (r, "")
  else
    patt = "(.-)" .. (sep or "%s+")
  end
  local b, lens = 0, len (s)
  while b <= lens do
    local e, n, m = string.find (s, patt, b + 1)
    insert (r, m or s:sub (b + 1, lens))
    b = n or lens + 1
  end
  return r
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



return {
  copy  = copy,
  merge = merge,

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

  -- debug.lua --
  argerror = argerror,

  -- functional.lua --
  callable = callable,
  collect  = collect,
  nop      = function () end,
  reduce   = reduce,

  -- list.lua --
  compare = compare,

  -- object.lua --
  prototype = prototype,

  -- string.lua --
  render   = render,
  split    = split,

  -- table.lua --
  getmetamethod = getmetamethod,
  insert        = insert,
  last          = last,
  len           = len,

  -- tree.lua --
  leaves = leaves,

}
