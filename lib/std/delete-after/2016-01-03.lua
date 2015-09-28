--[[--
 Provide at least one year of support for deprecated APIs, or at
 least one release cycle if that is longer.

 When `_DEBUG.deprecate` is `true` we don`t even load this support, in
 which case `require`ing this module returns `false`.

 Otherwise, return a table of all functions deprecated in the given
 `RELEASE` and earlier, going back at least one year.  The table is
 keyed on the original module to enable merging deprecated APIs back
 into their previous namespaces - this is handled automatically by the
 documented modules according to the contents of `_DEBUG`.

 In some release after the date of this module, it will be removed and
 these APIs will not be available any longer.
]]


local RELEASE	= "41.0.0"

local M		= false

if not require "std.debug_init"._DEBUG.deprecate then

  local getmetatable	= getmetatable
  local pairs		= pairs
  local type		= type

  local coroutine_yield	= coroutine.yield
  local coroutine_wrap	= coroutine.wrap
  local math_ceil	= math.ceil
  local math_max	= math.max
  local table_unpack	= table.unpack or unpack

  local _, deprecated	= {
    -- Adding anything else here will probably cause a require loop.
    maturity		= require "std.maturity",
    std			= require "std.base",
    strict		= require "std.strict",
  }

  -- Merge in deprecated APIs from previous release if still available.
  _.ok, deprecated	= pcall (require, "std.delete-after.2015-05.01")
  if not _.ok then deprecated = {} end


  -- Dangerous :-o Hope we don't need to deprecate anything in
  -- std.operator any time in the next year or so...
  local operator	= require "std.operator"

  local _assert		= _.std.assert
  local _ipairs		= _.std.ipairs
  local _pairs		= _.std.pairs
  local _require	= _.std.require
  local _tostring	= _.std.tostring
  local DEPRECATED	= _.maturity.DEPRECATED
  local eval		= _.std.eval
  local ielems		= _.std.ielems
  local ireverse	= _.std.ireverse
  local ripairs		= _.std.ripairs

  -- Only the above symbols are used below this line.
  local _, _ENV		= nil, _.strict {}


  --[[ ========== ]]--
  --[[ Death Row! ]]--
  --[[ ========== ]]--

  local function callable (x)
    if type (x) == "function" then return x end
    return (getmetatable (x) or {}).__call
  end


  local function getmetamethod (x, n)
    local m = (getmetatable (x) or {})[n]
    if callable (m) then return m end
  end


  local function len (t)
    local m = getmetamethod (t, "__len")
    return m and m (t) or #t
  end


  local function depair (proto, ls)
    local t = {}
    for _, v in _ipairs (ls) do
      t[v[1]] = v[2]
    end
    return t
  end


  local function elems (proto, ...)
    return ielems (...)
  end


  local function enpair (proto, t)
    local ls = proto {}
    for i, v in _pairs (t) do
      ls[#ls + 1] = proto {i, v}
    end
    return ls
  end


  local function filter (proto, pfn, l)
    local r = proto {}
    for _, e in _ipairs (l) do
      if pfn (e) then
        r[#r + 1] = e
      end
    end
    return r
  end


  local function fold (fn, d, ifn, ...)
    local nextfn, state, k = ifn (...)
    local t = {nextfn (state, k)}

    local r = d
    while t[1] ~= nil do
      r = fn (r, t[#t])
      t = {nextfn (state, t[1])}
    end
    return r
  end


  local function reduce (fn, d, ifn, ...)
    local argt = {...}
    if not callable (ifn) then
      ifn, argt = _pairs, {ifn, ...}
    end

    local nextfn, state, k = ifn (table_unpack (argt))
    local t = {nextfn (state, k)}	-- table of iteration 1

    local r = d				-- initialise accumulator
    while t[1] ~= nil do		-- until iterator returns nil
      k = t[1]
      r = fn (r, table_unpack (t))	-- pass all iterator results to fn
      t = {nextfn (state, k)}		-- maintain loop invariant
    end
    return r
  end


  local function foldl (proto, fn, d, t)
    if t == nil then
      local tail = {}
      for i = 2, len (d) do tail[#tail + 1] = d[i] end
      d, t = d[1], tail
    end
    return reduce (fn, d, ielems, t)
  end


  local function foldr (proto, fn, d, t)
    if t == nil then
      local u, last = {}, len (d)
      for i = 1, last - 1 do u[#u + 1] = d[i] end
      d, t = d[last], u
    end
    return reduce (function (x, y) return fn (y, x) end, d, ielems, ireverse (t))
  end


  local function index_key (proto, f, l)
    local r = {}
    for i, v in _ipairs (l) do
      local k = v[f]
      if k then
        r[k] = i
      end
    end
    return r
  end


  local function index_value (proto, f, l)
    local r = {}
    for i, v in _ipairs (l) do
      local k = v[f]
      if k then
        r[k] = v
      end
    end
    return r
  end


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


  local function flatten (proto, l)
    local r = proto {}
    for v in leaves (_ipairs, l) do
      r[#r + 1] = v
    end
    return r
  end


  local function map (proto, fn, l)
    local r = proto {}
    for _, e in _ipairs (l) do
      local v = fn (e)
      if v ~= nil then
        r[#r + 1] = v
      end
    end
    return r
  end


  local function map_with (proto, fn, ls)
    return map (proto, function (...) return fn (table_unpack (...)) end, ls)
  end


  local function project (proto, x, l)
    return map (proto, function (t) return t[x] end, l)
  end


  local function relems (proto, l) return ielems (ireverse (l)) end


  local function reverse (proto, l) return proto (ireverse (l)) end


  local function shape (proto, s, l)
    l = flatten (proto, l)
    -- Check the shape and calculate the size of the zero, if any
    local size = 1
    local zero
    for i, v in _ipairs (s) do
      if v == 0 then
        if zero then -- bad shape: two zeros
          return nil
        else
          zero = i
        end
      else
        size = size * v
      end
    end
    if zero then
      s[zero] = math_ceil (len (l) / size)
    end
    local function fill (i, d)
      if d > len (s) then
        return l[i], i + 1
      else
        local r = proto {}
        for j = 1, s[d] do
          local e
          e, i = fill (i, d + 1)
          r[#r + 1] = e
        end
        return r, i
      end
    end
    return (fill (1, 1))
  end


  local function totable (x)
    local m = getmetamethod (x, "__totable")
    if m then
      return m (x)
    elseif type (x) == "table" then
      return x
    elseif type (x) == "string" then
      local t = {}
      x:gsub (".", function (c) t[#t + 1] = c end)
      return t
    else
      return nil
    end
  end


  local function transpose (proto, ls)
    local rs, lenls, dims = proto {}, len (ls), map (proto, len, ls)
    if len (dims) > 0 then
      for i = 1, math_max (table_unpack (dims)) do
        rs[i] = proto {}
        for j = 1, lenls do
          rs[i][j] = ls[j][i]
        end
      end
    end
    return rs
  end


  local function zip_with (proto, ls, fn)
    return map_with (proto, fn, transpose (proto, ls))
  end


  -- Ensure deprecated APIs observe _DEBUG warning standards.
  local function X (old, new, fn)
    if fn ~= nil then new = "use '" .. new .. "' instead" end
    return DEPRECATED (RELEASE, "'std." .. old .. "'", new, fn)
  end

  local function DEPRECATEOP (old, new)
    return X ("functional.op[" .. old .. "]", "std.operator." .. new, operator[new])
  end

  local function acyclic_merge (dest, src)
    for k, v in pairs (src) do
      if type (v) == "table" then
        dest[k] = dest[k] or {}
        if type (dest[k]) == "table" then acyclic_merge (dest[k], v) end
      else
        dest[k] = dest[k] or v
      end
    end
    return dest
  end

  M = acyclic_merge ({
    functional = {
      eval = X ("functional.eval", "std.eval", eval),
      fold = X ("functional.fold", "std.functional.reduce", fold),
      op = {
        ["[]"]  = DEPRECATEOP ("[]",  "get"),
        ["+"]   = DEPRECATEOP ("+",   "sum"),
        ["-"]   = DEPRECATEOP ("-",   "diff"),
        ["*"]   = DEPRECATEOP ("*",   "prod"),
        ["/"]   = DEPRECATEOP ("/",   "quot"),
        ["and"] = DEPRECATEOP ("and", "conj"),
        ["or"]  = DEPRECATEOP ("or",  "disj"),
        ["not"] = DEPRECATEOP ("not", "neg"),
        ["=="]  = DEPRECATEOP ("==",  "eq"),
        ["~="]  = DEPRECATEOP ("~=",  "neq"),
      },
    },

    list = {
      depair      = X ("list.depair", depair),
      elems       = X ("list.elems", "std.ielems", elems),
      enpair      = X ("list.enpair", enpair),
      filter      = X ("list.filter", "std.functional.filter", filter),
      flatten     = X ("list.flatten", "std.functional.flatten", flatten),
      foldl       = X ("list.foldl", "std.functional.foldl", foldl),
      foldr       = X ("list.foldr", "std.functional.foldr", foldr),
      index_key   = DEPRECATED (RELEASE, "'std.list.index_key'",
                      "compose 'std.functional.filter' and 'std.table.invert' instead",
                      index_key),
      index_value = DEPRECATED (RELEASE, "'std.list.index_value'",
                      "compose 'std.functional.filter' and 'std.table.invert' instead",
                      index_value),
      map         = X ("list.map", "std.functional.map", map),
      map_with    = X ("list.map_with'", "std.functional.map_with", map_with),
      project     = X ("list.project", "std.table.project", project),
      relems      = DEPRECATED (RELEASE, "'std.list.relems'",
                      "compose 'std.ielems' and 'std.ireverse' instead", relems),
      reverse     = DEPRECATED (RELEASE, "'std.list.reverse'",
                      "compose 'std.list' and 'std.ireverse' instead", reverse),
      shape       = X ("list.shape", "std.table.shape", shape),
      transpose   = X ("list.transpose", "std.functional.zip", transpose),
      zip_with    = X ("list.zip_with", "std.functional.zip_with", zip_with),
    },

    string = {
      assert = X ("string.assert", "std.assert", _assert),
      require_version = X ("string.require_version", "std.require", _require),
      tostring = X ("string.tostring", "std.tostring", _tostring),
    },

    table = {
      metamethod = X ("table.metamethod", "std.getmetamethod", getmetamethod),
      ripairs = X ("table.ripairs", "std.ripairs", ripairs),
      totable = X ("table.totable", "std.pairs", totable),
    },

    methods = {
      list = {
        elems       = X ("list:elems", "std.ielems", elems),
        enpair      = X ("list:enpair", enpair),
        filter      = X ("std.list:filter", "std.functional.filter",
                         function (proto, self, p) return filter (proto, p, self) end),
        flatten     = X ("list:flatten", "std.functional.flatten", flatten),
        foldl       = X ("list:foldl", "std.functional.foldl", function (proto, self, fn, e)
	                   if e ~= nil then return foldl (proto, fn, e, self) end
	                   return foldl (proto, fn, self)
	                 end),
        foldr       = X ("list:foldr", "std.functional.foldr", function (proto, self, fn, e)
	                   if e ~= nil then return foldr (proto, fn, e, self) end
	                   return foldr (proto, fn, self)
	                 end),
        index_key   = X ("list:index_key",
	                 function (proto, self, fn) return index_key (proto, fn, self) end),
        index_value = X ("list:index_value",
	                 function (proto, self, fn) return index_value (proto, fn, self) end),
        map         = X ("list:map", "std.functional.map",
	                 function (proto, self, fn) return map (proto, fn, self) end),
        project     = X ("list:project", "std.table.project",
	                 function (proto, self, x) return project (proto, x, self) end),
        relems      = X ("list:relems",  relems),
        reverse     = DEPRECATED (RELEASE, "'std.list:reverse'",
                        "compose 'std.list' and 'std.ireverse' instead", reverse),
        shape       = X ("list:shape", "std.table.shape",
	                 function (proto, t, l) return shape (proto, l, t) end),
      },
    },
  },
  deprecated)

end

return M
