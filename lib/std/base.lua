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


local dirsep		= string.match (package.config, "^(%S+)\n")
local error		= error
local getmetatable	= getmetatable
local loadstring	= loadstring or load
local next		= next
local pairs		= pairs
local rawget		= rawget
local require		= require
local select		= select
local setmetatable	= setmetatable
local tonumber		= tonumber
local tostring		= tostring
local type		= type

local coroutine_wrap	= coroutine.wrap
local coroutine_yield	= coroutine.yield
local math_huge		= math.huge
local math_min		= math.min
local io_type		= io.type
local string_find	= string.find
local string_format	= string.format
local table_concat	= table.concat
local table_insert	= table.insert
local table_maxn	= table.maxn
local table_sort	= table.sort
local table_unpack	= table.unpack or unpack

local _ENV		= require "std.strict".setenvtable {}



--[[ ============================ ]]--
--[[ Enhanced Core Lua functions. ]]--
--[[ ============================ ]]--

-- Forward declarations for Helper functions below.

local argerror, getmetamethod, len, vcompare

-- These come as early as possible, because we want the rest of the code
-- in this file to use these versions over the core Lua implementation
-- (which have slightly varying semantics between releases).


local function assert (expect, fmt, arg1, ...)
  local msg = (arg1 ~= nil) and string_format (fmt, arg1, ...) or fmt or ""
  return expect or error (msg, 2)
end


local function insert (t, pos, v)
  if v == nil then pos, v = len (t) + 1, pos end
  if pos < 1 or pos > len (t) + 1 then
    argerror ("std.table.insert", 2, "position " .. pos .. " out of bounds", 2)
  end
  table_insert (t, pos, v)
  return t
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

-- Respect __pairs metamethod, even in Lua 5.1.
local function pairs (t)
  return (getmetamethod (t, "__pairs") or _pairs) (t)
end


local maxn = table_maxn or function (t)
  local n = 0
  for k in pairs (t) do
    if type (k) == "number" and k > n then n = k end
  end
  return n
end


local _require = require

local function require (module, min, too_big, pattern)
  local m = _require (module)
  local v = tostring (type (m) == "table" and (m.version or m._VERSION) or ""):match (pattern or "([%.%d]+)%D*$")
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



--[[ ============================ ]]--
--[[ Shared Stdlib API functions. ]]--
--[[ ============================ ]]--


-- No need to recurse because functables are second class citizens in
-- Lua:
-- func=function () print "called" end
-- func() --> "called"
-- functable=setmetatable ({}, {__call=func})
-- functable() --> "called"
-- nested=setmetatable ({}, {__call=functable})
-- nested()
-- --> stdin:1: attempt to call a table value (global 'd')
-- --> stack traceback:
-- -->	stdin:1: in main chunk
-- -->		[C]: in ?
local function callable (x)
  if type (x) == "function" then return x end
  return (getmetatable (x) or {}).__call
end


local function catfile (...)
  return table_concat ({...}, dirsep)
end


local function compare (l, m)
  local lenl, lenm = len (l), len (m)
  for i = 1, math_min (lenl, lenm) do
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


local function last (t) return t[len (t)] end


local function leaves (it, tr)
  local function visit (n)
    if type (n) == "table" then
      for _, v in it (n) do
        visit (v)
      end
    else
      coroutine_yield (n)
    end
  end
  return coroutine_wrap (visit), tr
end


local function mapfields (obj, src, map)
  local mt = getmetatable (obj) or {}

  -- Map key pairs.
  -- Copy all pairs when `map == nil`, but discard unmapped src keys
  -- when map is provided (i.e. if `map == {}`, copy nothing).
  if map == nil or next (map) then
    map = map or {}
    local k, v = next (src)
    while k do
      local key, dst = map[k] or k, obj
      local kind = type (key)
      if kind == "string" and key:sub (1, 1) == "_" then
        mt[key] = v
      elseif next (map) and kind == "number" and len (dst) + 1 < key then
        -- When map is given, but has fewer entries than src, stop copying
        -- fields when map is exhausted.
        break
      else
        dst[key] = v
      end
      k, v = next (src, k)
    end
  end

  -- Only set non-empty metatable.
  if next (mt) then
    setmetatable (obj, mt)
  end
  return obj
end


local function merge (dest, src)
  for k, v in pairs (src) do dest[k] = dest[k] or v end
  return dest
end


local function Module (t)
  return setmetatable (t, {
    _type  = "Module",
    __call = function (self, ...) return self.prototype (...) end,
  })
end


local function npairs (t)
  local m = getmetamethod (t, "__len")
  local i, n = 0, m and m(t) or maxn (t)
  return function (t)
    i = i + 1
    if i <= n then return i, t[i] end
   end,
  t, i
end


local function unpack (t, i, j)
  if j == nil then
    -- respect __len, and then maxn if nil j was passed
    local m = getmetamethod (t, "__len")
    j = m and m (t) or maxn (t)
  end
  local fn = getmetamethod (t, "__unpack") or table_unpack
  return fn (t, tonumber (i) or 1, tonumber (j))
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


local fallbacks = {
  __index = {
    open  = function (x) return "{" end,
    close = function (x) return "}" end,
    elem  = tostring,
    pair  = function (x, kp, vp, k, v, kstr, vstr) return kstr .. "=" .. vstr end,
    sep   = function (x, kp, vp, kn, vn)
	      return kp ~= nil and kn ~= nil and "," or ""
            end,
    sort  = function (keys) return keys end,
    term  = function (x)
	      return type (x) ~= "table" or getmetamethod (x, "__tostring")
	    end,
  },
}

-- Write pretty-printing based on:
--
--   John Hughes's and Simon Peyton Jones's Pretty Printer Combinators
--
--   Based on "The Design of a Pretty-printing Library in Advanced
--   Functional Programming", Johan Jeuring and Erik Meijer (eds), LNCS 925
--   http://www.cs.chalmers.se/~rjmh/Papers/pretty.ps
--   Heavily modified by Simon Peyton Jones, Dec 96

local function render (x, fns, roots)
  fns = setmetatable (fns or {}, fallbacks)
  roots = roots or {}

  local function stop_roots (x)
    return roots[x] or render (x, fns, copy (roots))
  end

  if fns.term (x) then
    return fns.elem (x)

  else
    local buf, keys = {fns.open (x)}, {}	-- pre-buffer table open
    roots[x] = fns.elem (x)			-- recursion protection

    for k in pairs (x) do			-- collect keys
      keys[#keys + 1] = k
    end
    keys = fns.sort (keys)

    local pair, sep = fns.pair, fns.sep
    local kp, vp				-- previous key and value
    for _, k in ipairs (keys) do
      local v = x[k]
      buf[#buf + 1] = sep (x, kp, vp, k, v)	-- | buffer << separator
      buf[#buf + 1] = pair (x, kp, vp, k, v, stop_roots (k), stop_roots (v))
						-- | buffer << key/value pair
      kp, vp = k, v
    end
    buf[#buf + 1] = sep (x, kp, vp)		-- buffer << trailing separator
    buf[#buf + 1] = fns.close (x)		-- buffer << table close

    return table_concat (buf)			-- stringify buffer
  end
end


local function toqstring (x)
  if type (x) ~= "string" then return tostring (x) end
  return string_format ("%q", x)
end


local function sortkeys (t)
  table_sort (t, keysort)
  return t
end


local mnemonic_vtable = {
  elem = toqstring,
  sort = sortkeys,
}


local function mnemonic (...)
  local seq, n = {...}, select ("#", ...)
  local buf = {}
  for i = 1, n do
    buf[i] = render (seq[i], mnemonic_vtable)
  end
  return table_concat (buf, ",")
end


local picklable = {
  boolean = true, ["nil"] = true, number = true, string = true,
}

local pickle_vtable = {
  term = function (x)
    local type_x = type (x)
    if picklable[type_x] or getmetamethod (x, "__pickle") then
      return true
    elseif type (x) ~= "table" then
      -- don't know what to do with this :(
      error ("cannot pickle " .. tostring (x))
    end
  end,

  elem = function (x)
    -- math
    if x ~= x then
      return "0/0"
    elseif x == math_huge then
      return "math.huge"
    elseif x == -math_huge then
      return "-math.huge"
    elseif x == nil then
      return "nil"
    end

    -- common types
    local type_x = type (x)
    if type_x == "string" then
      return string_format ("%q", x)
    elseif type_x == "number" or type_x == "boolean" then
      return tostring (x)
    end

    -- pickling metamethod
    local __pickle = getmetamethod (x, "__pickle")
    if __pickle then return __pickle (x) end
  end,

  pair = function (x, kp, vp, k, v, kstr, vstr)
    return "[" .. kstr .. "]=" .. vstr
  end,
}


local function pickle (x)
  return render (x, pickle_vtable)
end


local function raise (bad, to, name, i, extramsg, level)
  level = level or 1
  local s = string_format ("bad %s #%d %s '%s'", bad, i, to, name)
  if extramsg ~= nil then
    s = s .. " (" .. extramsg .. ")"
  end
  error (s, level + 1)
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
  local m = getmetamethod (t, "__len")
  local oob = (m and m (t) or maxn (t)) + 1

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
  local b, slen = 0, len (s)
  while b <= slen do
    local e, n, m = string_find (s, patt, b + 1)
    insert (r, m or s:sub (b + 1, slen))
    b = n or slen + 1
  end
  return r
end


local tostring_vtable = {
  pair = function (x, kp, vp, k, v, kstr, vstr)
    if k == 1 or type (k) == "number" and k -1 == kp then
      return vstr
    end
    return kstr .. "=" .. vstr
  end,

  -- need to sort numeric keys to be able to skip printing them.
  sort = sortkeys,
}


--[[ ================= ]]--
--[[ Helper functions. ]]--
--[[ ================= ]]--

-- The bare minumum of functions required to support implementation of
-- Enhanced Core Lua functions, with forward declarations near the start
-- of the file.


argerror = function (name, i, extramsg, level)
  level = level or 1
  raise ("argument", "to", name, i, extramsg, level + 1)
end


-- Lua < 5.2 doesn't call `__len` automatically!
len = function (t)
  local m = getmetamethod (t, "__len")
  return m and m (t) or #t
end


getmetamethod = function (x, n)
  local m = (getmetatable (x) or {})[n]
  if callable (m) then return m end
end


vcompare = function (a, b)
  return compare (split (a, "%."), split (b, "%."))
end



--[[ ============= ]]--
--[[ Internal API. ]]--
--[[ ============= ]]--


-- For efficient use within stdlib, these functions have no type-checking.
-- In debug mode, type-checking wrappers are re-exported from the public-
-- facing modules as necessary.
--
-- Also, to provide some sanity, we mirror the subtable layout of stdlib
-- public API here too, which means everything looks relatively normal
-- when importing the functions into stdlib implementation modules.
return {
  assert        = assert,
  elems         = elems,
  eval          = eval,
  getmetamethod = getmetamethod,
  ielems        = ielems,
  ipairs        = ipairs,
  ireverse      = ireverse,
  npairs        = npairs,
  pairs         = pairs,
  require       = require,
  ripairs       = ripairs,
  rnpairs       = rnpairs,

  tostring      = function (x) return render (x, tostring_vtable) end,

  type = function (x)
    return (getmetatable (x) or {})._type or io_type (x) or type (x)
  end,

  base = {
    copy      = copy,
    keysort   = keysort,
    last      = last,
    merge     = merge,
    mnemonic  = mnemonic,
    raise     = raise,
    sortkeys  = sortkeys,
    toqstring = toqstring,
  },

  debug = {
    argerror = argerror,
  },

  functional = {
    callable = callable,
    collect  = collect,
    nop      = function () end,
    reduce   = reduce,
  },

  io = {
    catfile = catfile,
  },

  list = {
    compare = compare,
  },

  object = {
    Module    = Module,
    mapfields = mapfields,
  },

  operator = {
    len = len,
  },

  package = {
    dirsep = dirsep,
  },

  string = {
    escape_pattern = escape_pattern,
    pickle         = pickle,
    render         = render,
    split          = split,
  },

  table = {
    insert = insert,
    invert = invert,
    maxn   = maxn,
    unpack = unpack,
  },

  tree = {
    leaves = leaves,
  },
}
