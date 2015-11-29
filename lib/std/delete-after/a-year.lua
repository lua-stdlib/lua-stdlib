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


local RELEASE	= "upcoming"


local M		= false

if not require "std.debug_init"._DEBUG.deprecate then

  local error		= error
  local getmetatable	= getmetatable
  local next		= next
  local pairs		= pairs
  local pcall		= pcall
  local select		= select
  local type		= type

  local io_stderr	= io.stderr
  local io_type		= io.type
  local math_ceil	= math.ceil
  local math_floor	= math.floor
  local math_max	= math.max
  local string_find	= string.find
  local string_format	= string.format
  local string_gsub	= string.gsub
  local string_match	= string.match
  local table_concat	= table.concat
  local table_insert	= table.insert
  local table_maxn	= table.maxn
  local table_remove	= table.remove
  local table_sort	= table.sort
  local table_unpack	= table.unpack or unpack

  local _, deprecated	= {
    -- Adding anything else here will probably cause a require loop.
    debug_init		= require "std.debug_init",
    maturity		= require "std.maturity",
    std			= require "std.base",
    strict		= require "std.strict",
  }

  -- Merge in deprecated APIs from previous release if still available.
  _.ok, deprecated = pcall (require, "std.delete-after.2016-03-08")
  if not _.ok then deprecated = {} end


  local _DEBUG		= _.debug_init._DEBUG
  local _getfenv	= _.std.debug.getfenv
  local _ipairs		= _.std.ipairs
  local _pairs		= _.std.pairs
  local _setfenv	= _.std.debug.setfenv
  local _tostring	= _.std.tostring
  local DEPRECATED	= _.maturity.DEPRECATED
  local DEPRECATIONMSG	= _.maturity.DEPRECATIONMSG
  local copy		= _.std.base.copy
  local leaves		= _.std.tree.leaves
  local len		= _.std.operator.len
  local nop		= _.std.functional.nop
  local sortkeys	= _.std.base.sortkeys
  local split		= _.std.string.split
  local unpack		= _.std.table.unpack

  -- Only the above symbols are used below this line.
  local _, _ENV		= nil, _.strict {}


  local maxn = table_maxn or function (t)
    local n = 0
    for k in pairs (t) do
      if type (k) == "number" and k > n then n = k end
    end
    return n
  end


  --[[ ========== ]]--
  --[[ Death Row! ]]--
  --[[ ========== ]]--


  local function raise (bad, to, name, i, extramsg, level)
    level = level or 1
    local s = string_format ("bad %s #%d %s '%s'", bad, i, to, name)
    if extramsg ~= nil then
      s = s .. " (" .. extramsg .. ")"
    end
    error (s, level + 1)
  end


  local function argerror (name, i, extramsg, level)
    level = level or 1
    raise ("argument", "to", name, i, extramsg, level + 1)
  end


  local function resulterror (name, i, extramsg, level)
    level = level or 1
    raise ("result", "from", name, i, extramsg, level + 1)
  end


  local function extramsg_toomany (bad, expected, actual)
    local s = "no more than %d %s%s expected, got %d"
    return string_format (s, expected, bad, expected == 1 and "" or "s", actual)
  end


  --- Concatenate a table of strings using ", " and " or " delimiters.
  -- @tparam table alternatives a table of strings
  -- @treturn string string of elements from alternatives delimited by ", "
  --   and " or "
  local function concat (alternatives)
    if len (alternatives) > 1 then
      local t = copy (alternatives)
      local top = table_remove (t)
      t[#t] = t[#t] .. " or " .. top
      alternatives = t
    end
    return table_concat (alternatives, ", ")
  end


  local function _type (x)
    return (getmetatable (x) or {})._type or io_type (x) or type (x)
  end


  local function extramsg_mismatch (expectedtypes, actual, index)
    local actualtype = _type (actual) or type (actual)

    -- Tidy up actual type for display.
    if actualtype == "nil" then
      actualtype = "no value"
    elseif actualtype == "string" and actual:sub (1, 1) == ":" then
      actualtype = actual
    elseif type (actual) == "table" and next (actual) == nil then
      local matchstr = "," .. table_concat (expectedtypes, ",") .. ","
      if actualtype == "table" and matchstr == ",#list," then
	actualtype = "empty list"
      elseif actualtype == "table" or matchstr:match ",#" then
	actualtype = "empty " .. actualtype
      end
    end

    if index then
      actualtype = actualtype .. " at index " .. _tostring (index)
    end

    -- Tidy up expected types for display.
    local expectedstr = expectedtypes
    if type (expectedtypes) == "table" then
      local t = {}
      for i, v in _ipairs (expectedtypes) do
	if v == "func" then
	  t[i] = "function"
	elseif v == "bool" then
	  t[i] = "boolean"
	elseif v == "any" then
	  t[i] = "any value"
	elseif v == "file" then
	  t[i] = "FILE*"
	elseif not index then
	  t[i] = v:match "(%S+) of %S+" or v
	else
	  t[i] = v
	end
      end
      expectedstr = (concat (t) .. " expected"):
		    gsub ("#table", "non-empty table"):
		    gsub ("#list", "non-empty list"):
		    gsub ("(%S+ of [^,%s]-)s? ", "%1s "):
		    gsub ("(%S+ of [^,%s]-)s?,", "%1s,"):
		    gsub ("(s, [^,%s]-)s? ", "%1s "):
		    gsub ("(s, [^,%s]-)s?,", "%1s,"):
		    gsub ("(of .-)s? or ([^,%s]-)s? ", "%1s or %2s ")
    end

    return expectedstr .. ", got " .. actualtype
  end


  --- Strip trailing ellipsis from final argument if any, storing maximum
  -- number of values that can be matched directly in `t.maxvalues`.
  -- @tparam table t table to act on
  -- @string v element added to *t*, to match against ... suffix
  -- @treturn table *t* with ellipsis stripped and maxvalues field set
  local function markdots (t, v)
    return (string_gsub (v, "%.%.%.$", function () t.dots = true return "" end))
  end


  --- Calculate permutations of type lists with and without [optionals].
  -- @tparam table t a list of expected types by argument position
  -- @treturn table set of possible type lists
  local function permute (t)
    if t[#t] then t[#t] = string_gsub (t[#t], "%]%.%.%.$", "...]") end

    local p = {{}}
    for i, v in _ipairs (t) do
      local optional = string_match (v, "%[(.+)%]")

      if optional == nil then
	-- Append non-optional type-spec to each permutation.
	for b = 1, #p do
	  table_insert (p[b], markdots (p[b], v))
	end
      else
	-- Duplicate all existing permutations, and add optional type-spec
	-- to the unduplicated permutations.
	local o = #p
	for b = 1, o do
	  p[b + o] = copy (p[b])
	  table_insert (p[b], markdots (p[b], optional))
	end
      end
    end
    return p
  end


  local function typesplit (types)
    if type (types) == "string" then
      types = split (string_gsub (types, "%s+or%s+", "|"), "%s*|%s*")
    end
    local r, seen, add_nil = {}, {}, false
    for _, v in _ipairs (types) do
      local m = string_match (v, "^%?(.+)$")
      if m then
	add_nil, v = true, m
      end
      if not seen[v] then
	r[#r + 1] = v
	seen[v] = true
      end
    end
    if add_nil then
      r[#r + 1] = "nil"
    end
    return r
  end


  local function projectuniq (fkey, tt)
    -- project
    local t = {}
    for _, u in _ipairs (tt) do
      t[#t + 1] = u[fkey]
    end

    -- split and remove duplicates
    local r, s = {}, {}
    for _, e in _ipairs (t) do
      for _, v in _ipairs (typesplit (e)) do
	if s[v] == nil then
	  r[#r + 1], s[v] = v, true
	end
      end
    end
    return r
  end


  local function parsetypes (types)
    local r, permutations = {}, permute (types)
    for i = 1, #permutations[1] do
      r[i] = projectuniq (i, permutations)
    end
    r.dots = permutations[1].dots
    return r
  end



  local argcheck, argscheck  -- forward declarations

  if _DEBUG.argcheck then

    --- Return index of the first mismatch between types and values, or `nil`.
    -- @tparam table typelist a list of expected types
    -- @tparam table valuelist a table of arguments to compare
    -- @treturn int|nil position of first mismatch in *typelist*
    local function match (typelist, valuelist)
      local n = #typelist
      for i = 1, n do  -- normal parameters
	local ok = pcall (argcheck, "pcall", i, typelist[i], valuelist[i])
	if not ok then return i end
      end
      for i = n + 1, maxn (valuelist) do -- additional values against final type
	local ok = pcall (argcheck, "pcall", i, typelist[n], valuelist[i])
	if not ok then return i end
      end
    end


    --- Compare *check* against type of *actual*
    -- @string check extended type name expected
    -- @param actual object being typechecked
    -- @treturn boolean `true` if *actual* is of type *check*, otherwise
    --   `false`
    local function checktype (check, actual)
      if check == "any" and actual ~= nil then
	return true
      elseif check == "file" and io_type (actual) == "file" then
	return true
      end

      local actualtype = type (actual)
      if check == actualtype then
	return true
      elseif check == "bool" and actualtype == "boolean" then
	return true
      elseif check == "#table" then
	if actualtype == "table" and next (actual) then
	  return true
	end
      elseif check == "function" or check == "func" then
	if actualtype == "function" or
	    (getmetatable (actual) or {}).__call ~= nil
	then
	   return true
	end
      elseif check == "int" then
	if actualtype == "number" and actual == math_floor (actual) then
	  return true
	end
      elseif type (check) == "string" and check:sub (1, 1) == ":" then
	if check == actual then
	  return true
	end
      end

      actualtype = _type (actual)
      if check == actualtype then
	return true
      elseif check == "list" or check == "#list" then
	if actualtype == "table" or actualtype == "List" then
	  local len, count = len (actual), 0
	  local i = next (actual)
	  repeat
	    if i ~= nil then count = count + 1 end
	    i = next (actual, i)
	  until i == nil or count > len
	  if count == len and (check == "list" or count > 0) then
	    return true
	  end
	end
      elseif check == "object" then
	if actualtype ~= "table" and type (actual) == "table" then
	  return true
	end
      end

      return false
    end


    local function empty (t) return not next (t) end

    -- Pattern to normalize: [types...] to [types]...
    local last_pat = "^%[([^%]%.]+)%]?(%.*)%]?"

    --- Diagnose mismatches between *valuelist* and type *permutations*.
    -- @tparam table valuelist list of actual values to be checked
    -- @tparam table argt table of precalculated values and handler functiens
    local function diagnose (valuelist, argt)
      local permutations = argt.permutations

      local bestmismatch, t = 0
      for i, typelist in _ipairs (permutations) do
	local mismatch = match (typelist, valuelist)
	if mismatch == nil then
	  bestmismatch, t = nil, nil
	  break -- every *valuelist* matched types from this *typelist*
	elseif mismatch > bestmismatch then
	  bestmismatch, t = mismatch, permutations[i]
	end
      end

      if bestmismatch ~= nil then
	-- Report an error for all possible types at bestmismatch index.
	local i, expected = bestmismatch
	if t.dots and i > #t then
	  expected = typesplit (t[#t])
	else
	  expected = projectuniq (i, permutations)
	end

	-- This relies on the `permute()` algorithm leaving the longest
	-- possible permutation (with dots if necessary) at permutations[1].
	local typelist = permutations[1]

	-- For "container of things", check all elements are a thing too.
	if typelist[i] then
	  local check, contents = string_match (typelist[i], "^(%S+) of (%S-)s?$")
	  if contents and type (valuelist[i]) == "table" then
	    for k, v in _pairs (valuelist[i]) do
	      if not checktype (contents, v) then
		argt.badtype (i, extramsg_mismatch (expected, v, k), 3)
	      end
	    end
	  end
	end

	-- Otherwise the argument type itself was mismatched.
	if t.dots or #t >= maxn (valuelist) then
	  argt.badtype (i, extramsg_mismatch (expected, valuelist[i]), 3)
	end
      end

      local n, t = maxn (valuelist), t or permutations[1]
      if t and t.dots == nil and n > #t then
	argt.badtype (#t + 1, extramsg_toomany (argt.bad, #t, n), 3)
      end
    end


    function argcheck (name, i, expected, actual, level)
      level = level or 2
      expected = typesplit (expected)

      -- Check actual has one of the types from expected
      local ok = false
      for _, expect in _ipairs (expected) do
	local check, contents = string_match (expect, "^(%S+) of (%S-)s?$")
	check = check or expect

	-- Does the type of actual check out?
	ok = checktype (check, actual)

	-- For "table of things", check all elements are a thing too.
	if ok and contents and type (actual) == "table" then
	  for k, v in _pairs (actual) do
	    if not checktype (contents, v) then
	      argerror (name, i, extramsg_mismatch (expected, v, k), level + 1)
	    end
	  end
	end
	if ok then break end
      end

      if not ok then
	argerror (name, i, extramsg_mismatch (expected, actual), level + 1)
      end
    end


    -- Pattern to extract: fname ([types]?[, types]*)
    local args_pat = "^%s*([%w_][%.%:%d%w_]*)%s*%(%s*(.*)%s*%)"

    function argscheck (decl, inner)
      -- Parse "fname (argtype, argtype, argtype...)".
      local fname, argtypes = string_match (decl, args_pat)
      if argtypes == "" then
	argtypes = {}
      elseif argtypes then
	argtypes = split (argtypes, "%s*,%s*")
      else
	fname = string_match (decl, "^%s*([%w_][%.%:%d%w_]*)")
      end

      -- Precalculate vtables once to make multiple calls faster.
      local input, output = {
	bad          = "argument",
	badtype      = function (i, extramsg, level)
			 level = level or 1
			 argerror (fname, i, extramsg, level + 1)
		       end,
	permutations = permute (argtypes),
      }

      -- Parse "... => returntype, returntype, returntype...".
      local returntypes = string_match (decl, "=>%s*(.+)%s*$")
      if returntypes then
	local i, permutations = 0, {}
	for _, group in _ipairs (split (returntypes, "%s+or%s+")) do
	  returntypes = split (group, ",%s*")
	  for _, t in _ipairs (permute (returntypes)) do
	    i = i + 1
	    permutations[i] = t
	  end
	end

	-- Ensure the longest permutation is first in the list.
	table_sort (permutations, function (a, b) return #a > #b end)

	output = {
	  bad          = "result",
	  badtype      = function (i, extramsg, level)
			   level = level or 1
			   resulterror (fname, i, extramsg, level + 1)
			 end,
	  permutations = permutations,
	}
      end

      return function (...)
	local argt = {...}

	-- Don't check type of self if fname has a ':' in it.
	if string_find (fname, ":") then table_remove (argt, 1) end

	-- Diagnose bad inputs.
	diagnose (argt, input)

	-- Propagate outer environment to inner function.
	local x = math_max -- ??? FIXME: getfenv(1) fails if we remove this ???
	_setfenv (inner, _getfenv (1))

	-- Execute.
	local results = {inner (...)}

	-- Diagnose bad outputs.
	if returntypes then
	  diagnose (results, output)
	end

	return unpack (results)
      end
    end

  else

    -- Turn off argument checking if _DEBUG is false, or a table containing
    -- a false valued `argcheck` field.

    argcheck  = nop
    argscheck = function (decl, inner) return inner end

  end


  local function collect (ifn, ...)
    local argt, r = {...}, {}

    -- How many return values from ifn?
    local arity = 1
    for e, v in ifn (table_unpack (argt)) do
      if v then arity, r = 2, {} break end
      -- Build an arity-1 result table on first pass...
      r[#r + 1] = e
    end

    if arity == 2 then
      -- ...oops, it was arity-2 all along, start again!
      for k, v in ifn (table_unpack (argt)) do
        r[k] = v
      end
    end

    return r
  end


  local function flatten (t)
    return collect (leaves, _ipairs, t)
  end


  local function ireverse (t)
    local oob = 1
    while t[oob] ~= nil do
      oob = oob + 1
    end

    local r = {}
    for i = 1, oob - 1 do r[oob - i] = t[i] end
    return r
  end


  local function okeys (t)
    local r = {}
    for k in _pairs (t) do r[#r + 1] = k end
    return sortkeys (r)
  end


  local function shape (dims, t)
    t = flatten (t)
    -- Check the shape and calculate the size of the zero, if any
    local size = 1
    local zero
    for i, v in _ipairs (dims) do
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
      dims[zero] = math_ceil (len (t) / size)
    end
    local function fill (i, d)
      if d > len (dims) then
        return t[i], i + 1
      else
        local r = {}
        for j = 1, dims[d] do
          local e
          e, i = fill (i, d + 1)
          r[#r + 1] = e
        end
        return r, i
      end
    end
    return (fill (1, 1))
  end


  local function _type (x)
    return (getmetatable (x) or {})._type or io_type (x) or type (x)
  end


  -- Ensure deprecated APIs observe _DEBUG warning standards.
  local function X (old, new, fn)
    return DEPRECATED (RELEASE, "'std." .. old .. "'", "use 'std." .. new .. "' instead", fn)
  end

  local function XX (base, fn)
    return DEPRECATED (RELEASE, "'std.debug." .. base .. "'", "use 'std.argcheck." .. base .. "' instead", fn) or nil
  end

  local function result_pack (...)
    return {n = select ("#", ...), ...}
  end

  local function result_unpack (v)
    return table_unpack (v, 1, v.n)
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
    debug = {
      argcheck = XX ("argcheck", function (name, i, expected, actual, level)
	-- Add 2 to the level, this anonymous function and XX, being
	-- careful not to let tail call elimination remove a stack
	-- frame:
        local r = result_pack (argcheck (name, i, expected, actual, (level or 1) + 2))
	return result_unpack (r)
      end),
      argerror = XX ("argerror", function (name, i, extramsg, level)
        local r = result_pack (argerror (name, i, extramsg, (level or 1) + 2))
	return result_unpack (r)
      end),
      argscheck = XX ("argscheck", argscheck),
      extramsg_mismatch = XX ("extramsg_mismatch", function (expected, actual, index)
        local r = result_pack (extramsg_mismatch (typesplit (expected), actual, index))
	return result_unpack (r)
      end),
      extramsg_toomany = XX ("extramsg_toomany", extramsg_toomany),
      parsetypes = XX ("parsetypes", parsetypes),
      resulterror = XX ("resulterror", function (name, i, extramsg, level)
        local r = result_pack (resulterror (name, i, extramsg, (level or 1) + 2))
	return result_unpack (r)
      end),
      typesplit = XX ("typesplit", typesplit),
    },

    object = {
      type = function (x)
        local r = (getmetatable (x) or {})._type
	if r == nil then
	  io_stderr:write (DEPRECATIONMSG (RELEASE,
            "non-object argument to 'std.object.type'",
            [[check for 'type (x) == "table"' before calling 'std.object.type (x)' instead]],
	    2))
	 end
	 return r or io_type (x) or type (x)
      end,
    },

    std = {
      ireverse = X ("ireverse", "functional.ireverse", ireverse),
    },

    table = {
      flatten = X ("table.flatten", "functional.flatten", flatten),
      len = X ("table.len", "operator.len", len),
      okeys = DEPRECATED (RELEASE, "'std.table.okeys'", "compose 'std.table.keys' and 'std.table.sort' instead", okeys),
      shape = X ("table.shape", "functional.shape", shape),
    },

    methods = {
      object = {
        prototype = DEPRECATED (RELEASE, "'std.object.prototype'", "use 'std.functional.any (std.object.type, io.type, type)' instead", _type),
        type = DEPRECATED (RELEASE, "'std.object.type'", "use 'std.functional.any (std.object.type, io.type, type)' instead", _type),
      },
    },
  },
  deprecated)

end

return M
