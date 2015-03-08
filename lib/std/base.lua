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


local dirsep     = string.match (package.config, "^(%S+)\n")
local loadstring = rawget (_G, "loadstring") or load


local function raise (bad, to, name, i, extramsg, level)
  level = level or 1
  local s = string.format ("bad %s #%d %s '%s'", bad, i, to, name)
  if extramsg ~= nil then
    s = s .. " (" .. extramsg .. ")"
  end
  error (s, level + 1)
end


local function argerror (name, i, extramsg, level)
  level = level or 1
  raise ("argument", "to", name, i, extramsg, level + 1)
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


local function catfile (...)
  return table.concat ({...}, dirsep)
end


-- Lua < 5.2 doesn't call `__len` automatically!
local function len (t)
  local m = getmetamethod (t, "__len")
  return m and m (t) or #t
end


-- Iterate over keys 1..n, where n is the key before the first nil
-- valued ordinal key (like Lua 5.3).
local function ipairs (l)
  return function (l, n)
    n = n + 1
    if l[n] ~= nil then
      return n, l[n]
    end
  end, l, 0
end


local _pairs = pairs

local maxn = table.maxn or function (t)
  local n = 0
  for k in _pairs (t) do
    if type (k) == "number" and k > n then n = k end
  end
  return n
end


local _unpack = table.unpack or unpack

local function unpack (t, i, j)
  return _unpack (t, i or 1, j or maxn (t))
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


local function escape_pattern (s)
  return (s:gsub ("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end


local function eval (s)
  return loadstring ("return " .. s)()
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


local function invert (t)
  local i = {}
  for k, v in pairs (t) do
    i[v] = k
  end
  return i
end


-- Be careful to reverse only the valid sequence part of a table.
local function ireverse (t)
  local oob = 1
  while t[oob] ~= nil do
    oob = oob + 1
  end

  local r = {}
  for i = 1, oob - 1 do r[oob - i] = t[i] end
  return r
end


-- Sort numbers first then asciibetically
local function keysort (a, b)
  if type (a) == "number" then
    return type (b) ~= "number" or a < b
  else
    return type (b) ~= "number" and tostring (a) < tostring (b)
  end
end


local function okeys (t)
  local r = {}
  for k in pairs (t) do r[#r + 1] = k end
  table.sort (r, keysort)
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


local function npairs (t)
  local i, n = 0, maxn (t)
  return function (t)
    i = i + 1
    if i <= n then return i, t[i] end
   end,
  t, i
end


local function collect (ifn, ...)
  local argt, r = {...}, {}
  if not callable (ifn) then
    ifn, argt = npairs, {ifn, ...}
  end

  -- How many return values from ifn?
  local arity = 1
  for e, v in ifn (unpack (argt)) do
    if v then arity, r = 2, {} break end
    -- Build an arity-1 result table on first pass...
    r[#r + 1] = e
  end

  if arity == 2 then
    -- ...oops, it was arity-2 all along, start again!
    for k, v in ifn (unpack (argt)) do
      r[k] = v
    end
  end

  return r
end


local function prototype (o)
  return (getmetatable (o) or {})._type or io.type (o) or type (o)
end


local function reduce (fn, d, ifn, ...)
  local argt = {...}
  if not callable (ifn) then
    ifn, argt = pairs, {ifn, ...}
  end

  local nextfn, state, k = ifn (unpack (argt))
  local t = {nextfn (state, k)}	-- table of iteration 1

  local r = d			-- initialise accumulator
  while t[1] ~= nil do		-- until iterator returns nil
    k = t[1]
    r = fn (r, unpack (t))	-- pass all iterator results to fn
    t = {nextfn (state, k)}	-- maintain loop invariant
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

local function render (x, opencb, closecb, elemcb, paircb, sepcb, roots)
  roots = roots or {}
  local function stop_roots (x)
    return roots[x] or render (x, opencb, closecb, elemcb, paircb, sepcb, copy (roots))
  end

  if type (x) ~= "table" or getmetamethod (x, "__tostring") then
    return elemcb (x)
  else
    local buf, k_, v_ = { opencb (x) }		-- pre-buffer table open
    roots[x] = elemcb (x)			-- initialise recursion protection

    for _, k in ipairs (okeys (x)) do		-- for ordered table members
      local v = x[k]
      buf[#buf + 1] = sepcb (x, k_, v_, k, v)	-- | buffer separator
      buf[#buf + 1] = paircb (x, k, v, stop_roots (k), stop_roots (v))
						-- | buffer key/value pair
      k_, v_ = k, v
    end
    buf[#buf + 1] = sepcb (x, k_, v_)		-- buffer trailing separator
    buf[#buf + 1] = closecb (x)			-- buffer table close

    return table.concat (buf)			-- stringify buffer
  end
end


local function ripairs (t)
  local oob = 1
  while t[oob] ~= nil do
    oob = oob + 1
  end

  return function (t, n)
    n = n - 1
    if n > 0 then
      return n, t[n]
    end
  end, t, oob
end


local function rnpairs (t)
  local oob = maxn (t) + 1

  return function (t, n)
    n = n - 1
    if n > 0 then
      return n, t[n]
    end
  end, t, oob
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
  local v = tostring (m.version or m._VERSION or ""):match (pattern or "([%.%d]+)%D*$")
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
		 function (_, i, _, k) return i and k and "," or "" end)
end



return {
  copy    = copy,
  keysort = keysort,
  merge   = merge,
  okeys   = okeys,
  raise   = raise,

  -- std.lua --
  assert   = assert,
  eval     = eval,
  elems    = elems,
  ielems   = ielems,
  ipairs   = ipairs,
  ireverse = ireverse,
  npairs   = npairs,
  pairs    = pairs,
  ripairs  = ripairs,
  rnpairs  = rnpairs,
  require  = require,
  tostring = tostring,

  -- debug.lua --
  argerror = argerror,

  -- functional.lua --
  callable = callable,
  collect  = collect,
  nop      = function () end,
  reduce   = reduce,

  -- io.lua --
  catfile = catfile,

  -- list.lua --
  compare = compare,

  -- object.lua --
  prototype = prototype,

  -- package.lua --
  dirsep = dirsep,

  -- string.lua --
  escape_pattern = escape_pattern,
  render         = render,
  split          = split,

  -- table.lua --
  getmetamethod = getmetamethod,
  insert        = insert,
  invert        = invert,
  last          = last,
  len           = len,
  maxn          = maxn,
  unpack        = unpack,

  -- tree.lua --
  leaves = leaves,

}
