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


local _ARGCHECK = require "std.debug_init"._ARGCHECK
local operator  = require "std.operator"


local argcheck, argerror, argscheck, prototype  -- forward declarations


--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


local toomanyarg_fmt =
      "too many arguments to '%s' (no more than %d expected, got %d)"


--- Construct a new Lambda functable.
-- The lambda string can be retrieved from functable `y` with `tostring (y)`,
-- or it can be executed with `y (args)`.
-- @string value lambda string
-- @func call compiled Lua function
-- @treturn table Lambda functable.
local function Lambda (value, call)
  return setmetatable ({ value = value, call = call },
  {
    _type = "Lambda",
    __call = function (self, ...) return call (...) end,
    __tostring = function (self) return 'Lambda "' .. value .. '"' end,
  })
end


--- Make a shallow copy of a table.
-- @tparam table t source table
-- @treturn table shallow copy of *t*
local function copy (t)
  local new = {}
  for k, v in pairs (t) do new[k] = v end
  return new
end


--- Concatenate a table of strings using ", " and " or " delimiters.
-- @tparam table alternatives a table of strings
-- @treturn string string of elements from alternatives delimited by ", "
--   and " or "
local function concat (alternatives)
  if #alternatives > 1 then
    local t = copy (alternatives)
    local top = table.remove (t)
    t[#t] = t[#t] .. " or " .. top
    alternatives = t
  end
  return table.concat (alternatives, ", ")
end


--- Normalize a list of type names.
-- @tparam table list of type names, trailing "?" as required
-- @treturn table a new list with "?" stripped, "nil" appended if so,
--   and with duplicates stripped.
local function normalize (t)
  local i, r, add_nil = 1, {}, false
  for _, v in ipairs (t) do
    local m = v:match "^(.+)%?$"
    if m then
      add_nil = true
      r[m] = r[m] or i
      i = i + 1
    elseif v then
      r[v] = r[v] or i
      i = i + 1
    end
  end
  if add_nil then
    r["nil"] = r["nil"] or i
  end

  -- Invert the return table.
  local t = {}
  for v, i in pairs (r) do t[i] = v end
  return t
end


--- Argument list length.
-- Like #table, but does not stop at the first nil value.
-- @tparam table t a table
-- @treturn int largest integer key in *t*
-- @usage tmax = arglen (t)
local function arglen (t)
  local len = 0
  for k in pairs (t) do
    if type (k) == "number" and k > len then len = k end
  end
  return len
end


--- Ordered iterator for integer keyed values.
-- Like ipairs, but does not stop at the first nil value.
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn table t
-- @usage
-- for i,v in opairs {"one", nil, "three"} do print (i, v) end
local function opairs (t)
  local i, max = 0, 0
  for k in pairs (t) do
    if type (k) == "number" and k > max then max = k end
  end
  return function (t)
	  i = i + 1
	  if i <= max then return i, t[i] end
	 end,
  t, true
end


--- Merge |-delimited type-specs, omitting duplicates.
-- @string ... type-specs
-- @treturn table list of merged and normalized type-specs
local function merge (...)
  local i, t = 1, {}
  for _, v in opairs {...} do
    v:gsub ("([^|]+)", function (m) t[i] = m; i = i + 1 end)
  end
  return normalize (t)
end


--- Calculate permutations of type lists with and without [optionals].
-- @tparam table types a list of expected types by argument position
-- @treturn table set of possible type lists
local function permutations (types)
  local p, sentinel = {{}}, {"optional arg"}
  for i, v in ipairs (types) do
    -- Remove sentinels before appending `v` to each list.
    for _, v in ipairs (p) do
      if v[#v] == sentinel then table.remove (v) end
    end

    local opt = v:match "%[(.+)%]"
    if opt == nil then
      -- Append non-optional type-spec to each permutation.
      for b = 1, #p do table.insert (p[b], v) end
    else
      -- Duplicate all existing permutations, and add optional type-spec
      -- to the unduplicated permutations.
      local o = #p
      for b = 1, o do
        p[b + o] = copy (p[b])
	table.insert (p[b], opt)
      end

      -- Leave a marker for optional argument in final position.
      for _, v in ipairs (p) do
	table.insert (v, sentinel)
      end
    end
  end

  -- Replace sentinels with "nil".
  for i, v in ipairs (p) do
    if v[#v] == sentinel then
      table.remove (v)
      if #v > 0 then
        v[#v] = v[#v] .. "|nil"
      else
	v[1] = "nil"
      end
    end
  end

  return p
end


--- Return index of the first mismatch between types and args, or `nil`.
-- @tparam table types a list of expected types by argument position
-- @tparam table args a table of arguments to compare
-- @treturn int|nil position of first mismatch in *types*
local function match (types, args, allargs)
  local typec, argc = #types, arglen (args)
  for i = 1, typec do
    local ok = pcall (argcheck, "pcall", i, types[i], args[i])
    if not ok then return i end
  end
  if allargs then
    for i = typec + 1, argc do
      local ok = pcall (argcheck, name, i, types[typec], args[i])
      if not ok then return i end
    end
  end
end


--- Format a type mismatch error.
-- @tparam table expectedtypes a table of matchable types
-- @string actual the actual argument to match with
-- @treturn string formatted *extramsg* for this mismatch for @{argerror}
local function formaterror (expectedtypes, actual)
  local actualtype = prototype (actual)

  -- Tidy up actual type for display.
  if actualtype == "nil" then
    actualtype = "no value"
  elseif actualtype == "string" and actual:sub (1, 1) == ":" then
    actualtype = actual
  elseif type (actual) == "table" and next (actual) == nil then
    local matchstr = "," .. table.concat (expectedtypes, ",") .. ","
    if actualtype == "table" and matchstr == ",#list," then
      actualtype = "empty list"
    elseif actualtype == "table" or matchstr:match ",#" then
      actualtype = "empty " .. actualtype
    end
  end

  -- Tidy up expected types for display.
  local t = {}
  for i, v in ipairs (expectedtypes) do
    if v == "func" then
      t[i] = "function"
    elseif v == "any" then
      t[i] = "any value"
    else
      t[i] = v
    end
  end

  local expectedstr = concat (t):
                      gsub ("#table", "non-empty table"):
	              gsub ("#list", "non-empty list")

  return expectedstr .. " expected, got " .. actualtype
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


-- Doc-commented in object.lua
function prototype (o)
  return (getmetatable (o) or {})._type or io.type (o) or type (o)
end


-- Doc-commented in functional.lua
local function lambda (l)
  local s

  -- Support operator table lookup.
  if operator[l] then
    return Lambda (l, operator[l])
  end

  -- Support "|args|expression" format.
  local args, body = string.match (l, "^|([^|]*)|%s*(.+)$")
  if args and body then
    s = "return function (" .. args .. ") return " .. body .. " end"
  end

  -- Support "=expression" format.
  if not s then
    body = l:match "^=%s*(.+)$"
    if body then
      s = [[
        return function (...)
          local _1,_2,_3,_4,_5,_6,_7,_8,_9 = (unpack or table.unpack) {...}
	  return ]] .. body .. [[
        end
      ]]
    end
  end

  local ok, fn
  if s then
    ok, fn = pcall (loadstring (s))
  end

  -- Diagnose invalid input.
  if not ok then
    return nil, "invalid lambda string '" .. l .. "'"
  end

  return Lambda (s, fn)
end


--- Split a string at a given separator.
-- Separator is a Lua pattern, so you have to escape active characters,
-- `^$()%.[]*+-?` with a `%` prefix to match a literal character in *s*.
-- @function split
-- @string s to split
-- @string[opt="%s+"] sep separator pattern
-- @return list of strings
local function split (s, sep)
  sep = sep or "%s+"
  local b, len, t, patt = 0, #s, {}, "(.-)" .. sep
  if sep == "" then patt = "(.)"; t[#t + 1] = "" end
  while b <= len do
    local e, n, m = string.find (s, patt, b + 1)
    t[#t + 1] = m or s:sub (b + 1, len)
    b = n or len + 1
  end
  return t
end


if _ARGCHECK then

  local typeof = type  -- free up `type` for use as a variable

  -- Doc-commented in debug.lua
  function argcheck (name, i, expected, actual, level)
    level = level or 2
    expected = normalize (split (expected, "|"))

    -- Check actual has one of the types from expected
    local ok, actualtype = false, prototype (actual)
    for i, check in ipairs (expected) do
      if check == "#table" then
        if actualtype == "table" and next (actual) then
          ok = true
        end

      elseif check == "any" then
        if actual ~= nil then
          ok = true
        end

      elseif check == "file" then
        if io.type (actual) == "file" then
          ok = true
        end

      elseif check == "function" or check == "func" then
        if actualtype == "function" or
            (getmetatable (actual) or {}).__call ~= nil or
	    (actualtype == "string" and lambda (actual) ~= nil)
        then
           ok = true
        end

      elseif check == "int" then
        if actualtype == "number" and actual == math.floor (actual) then
          ok = true
        end

      elseif check == "list" or check == "#list" then
        if actualtype == "table" then
          local len, count = #actual, 0
	  local i = next (actual)
	  repeat
	    if i ~= nil then count = count + 1 end
            i = next (actual, i)
          until i == nil or count > len
	  if count == len and (check == "list" or count > 0) then
            ok = true
	  end
        end

      elseif check == "object" then
        if actualtype ~= "table" and typeof (actual) == "table" then
          ok = true
        end

      elseif typeof (check) == "string" and check:sub (1, 1) == ":" then
	if check == actual then
	  ok = true
	end

      elseif check == actualtype then
        ok = true
      end

      if ok then break end
    end

    if not ok then
      argerror (name, i, formaterror (expected, actual), level + 1)
    end
  end


  -- Doc-commented in debug.lua
  function argscheck (name, expected, actual)
    if typeof (expected) ~= "table" then expected = {expected} end
    if typeof (actual) ~= "table" then actual = {actual} end

    for i, v in ipairs (expected) do
      argcheck (name, i, expected[i], actual[i], 3)
    end
  end

else

  local function nop () end

  -- Turn off argument checking if _DEBUG is false, or a table containing
  -- a false valued `argcheck` field.

  argcheck  = nop
  argscheck = nop

end


-- Doc-commented in debug.lua...
-- This function is not disabled by setting _DEBUG.
function argerror (name, i, extramsg, level)
  level = level or 1
  local s = string.format ("bad argument #%d to '%s'", i, name)
  if extramsg ~= nil then
    s = s .. " (" .. extramsg .. ")"
  end
  error (s, level + 1)
end


--- Write a deprecation warning to stderr on first call.
-- @func fn deprecated function
-- @string[opt] name function name for automatic warning message.
-- @string[opt] warnmsg full specified warning message (overrides *name*)
-- @return a function to show the warning on first call, and hand off to *fn*
-- @usage funcname = deprecate (function (...) ... end, "funcname")
local function deprecate (fn, name, warnmsg)
  argscheck ("std.base.deprecate", {"function", "string?", "string?"},
             {fn, name, warnmsg})

  if not (name or warnmsg) then
    error ("missing argument to 'std.base.deprecate' (2 or 3 arguments expected)", 2)
  end

  warnmsg = warnmsg or (name .. " is deprecated, and will go away in a future release.")
  local warnp = true
  return function (...)
    if warnp then
      local _, where = pcall (function () error ("", 4) end)
      io.stderr:write ((string.gsub (where, "(^w%*%.%w*%:%d+)", "%1")))
      io.stderr:write (warnmsg .. "\n")
      warnp = false
    end
    return fn (...)
  end
end


--- Export a function definition, optionally with argument type checking.
-- In addition to checking that each argument type matches the corresponding
-- element in the *types* table with `argcheck`, if the final element of
-- *types* ends with an asterisk, remaining unchecked arguments are checked
-- against that type.
-- @function export
-- @tparam table M module table
-- @string decl function type declaration string
-- @func fn value to store at *name* in *M*
-- @usage
-- export (M, "round (number, int?)", std.math.round)
local function export (M, decl, fn, ...)
  local inner = fn

  -- Parse "fname (argtype, argtype, argtype...)".
  local name, types
  if decl then
    name, types = decl:match "([%w_][%d%w_]*)%s+%((.*)%)"
  end

  -- When argument checking is enabled, wrap in type checking function.
  if _ARGCHECK then
    local fname = "std.base.export"
    local args = {M, decl, fn, ...}
    argscheck (fname, {"table", "string", "function"}, args)

    -- Check for other argument errors.
    if types == "" then
      types = {}
    elseif types then
      types = split (types, ",%s+")
    else
      name = decl:match "([%w_][%d%w_]*)"
    end
    if arglen (args) > 3 then
      error (string.format (toomanyarg_fmt, fname, 3, arglen (args)), 2)
    elseif type (M[1]) ~= "string" then
      argerror (fname, 1, "module name at index 1 expected, got no value")
    elseif name == nil then
      argerror (fname, 2, "function name expected")
    elseif types == nil then
      argerror (fname, 2, "argument type specifications expected")
    elseif #types < 1 then
      argerror (fname, 2, "at least 1 argument type expected, got 0")
    end

    local name = M[1] .. "." .. name

    -- If the final element of types ends with "*", then set max to a
    -- sentinel value to denote type-checking of *all* remaining
    -- unchecked arguments against that type-spec is required.
    local max, fin = #types, types[#types]:match "^(.+)%*$"
    if fin then
      max = math.huge
      types[#types] = fin
    end

    -- For optional arguments wrapped in square brackets, make sure
    -- type-specs allow for passing or omitting an argument of that
    -- type.
    local typec, type_specs = #types, permutations (types)

    fn = function (...)
      local args = {...}
      local argc, bestmismatch, at = arglen (args), 0, 0

      for i, types in ipairs (type_specs) do
	local mismatch = match (types, args, max == math.huge)
	if mismatch == nil then
	  bestmismatch = nil
          break -- every argument matched its type-spec
	end

	if mismatch > bestmismatch then bestmismatch, at = mismatch, i end
      end

      if bestmismatch ~= nil then
	-- Report an error for all possible types at bestmismatch index.
	local expected
	if max == math.huge and bestmismatch >= typec then
          expected = normalize (split (types[typec], "|"))
	else
	  local tables = {}
	  for i, types in ipairs (type_specs) do
            if types[bestmismatch] then
              tables[#tables + 1] = types[bestmismatch]
	    end
	  end
	  expected = merge (unpack (tables))
	end
	local i = bestmismatch
	argerror (name, i, formaterror (expected, args[i]), 2)
      end

      if argc > max then
        error (string.format (toomanyarg_fmt, name, max, argc), 2)
      end

      return inner (...)
    end
  end

  M[name] = fn

  return inner
end


--- An iterator over the integer keyed elements of a table.
-- @tparam table t a table
-- @treturn function iterator function
-- @treturn *t*
-- @return `true`
local function ielems (t)
  local n = 0
  return function (t)
           n = n + 1
           if n <= #t then
             return t[n]
           end
         end,
  t, true
end


--- Iterator returning leaf nodes from nested tables.
-- @tparam function it table iterator function
-- @tparam tree|table tr tree or tree-like table
-- @treturn function iterator function
-- @treturn tree|table the tree `tr`
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


--- Return given metamethod, if any, or nil.
-- @tparam std.object x object to get metamethod of
-- @string n name of metamethod to get
-- @treturn function|nil metamethod function or `nil` if no metamethod or
--   not a function
-- @usage lookup = getmetamethod (require "std.object", "__index")
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


local M = {
  argcheck       = argcheck,
  argerror       = argerror,
  arglen         = arglen,
  argscheck      = argscheck,
  deprecate      = deprecate,
  export         = export,
  getmetamethod  = getmetamethod,
  ielems         = ielems,
  lambda         = lambda,
  leaves         = leaves,
  prototype      = prototype,
  split          = split,
  toomanyarg_fmt = toomanyarg_fmt,
}


return M
