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


local base = require "std.base.string"
local callable = require "std.base.functional".callable
local copy, render, split = base.copy, base.render, base.split



local function len (t)
  -- Lua < 5.2 doesn't call `__len` automatically!
  local m = (getmetatable (t) or {}).__len
  return m and m (t) or #t
end


--[[ ====================== ]]--
--[[ Documented in std.lua. ]]--
--[[ ====================== ]]--


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




--[[ ======================== ]]--
--[[ Documented in table.lua. ]]--
--[[ ======================== ]]--


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



--[[ ====================== ]]--
--[[ Documented in std.lua. ]]--
--[[ ====================== ]]--


--- Return a List object by splitting version string on periods.
-- @string version a period delimited version string
-- @treturn List a list of version components
local function version_to_list (version)
  return require "std.list" (split (version, "%."))
end


--- Extract a list of period delimited integer version components.
-- @tparam table module returned from a `require` call
-- @string pattern to capture version number from a string
--   (default: `"([%.%d]+)%D*$"`)
-- @treturn List a list of version components
local function module_version (module, pattern)
  local version = module.version or module._VERSION
  return version_to_list (version:match (pattern or "([%.%d]+)%D*$"))
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


local function eval (s)
  return loadstring ("return " .. s)()
end


local function require_version (module, min, too_big, pattern)
  local m = require (module)
  if min then
    assert (module_version (m, pattern) >= version_to_list (min))
  end
  if too_big then
    assert (module_version (m, pattern) < version_to_list (too_big))
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



--[[ ================== ]]--
--[[ Argument Checking. ]]--
--[[ ================== ]]--


local debug_init = require "std.debug_init"

local _ARGCHECK  = debug_init._ARGCHECK
local _DEBUG     = debug_init._DEBUG


local argcheck, argerror, argscheck  -- forward declarations


local toomanyarg_fmt =
      "too many arguments to '%s' (no more than %d expected, got %d)"


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
-- for i,v in argpairs {"one", nil, "three"} do print (i, v) end
local function argpairs (t)
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
  for _, v in argpairs {...} do
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
local function formaterror (expectedtypes, actual, index)
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

  if index then
    actualtype = actualtype .. " at index " .. tostring (index)
  end

  -- Tidy up expected types for display.
  local expectedstr = expectedtypes
  if type (expectedtypes) == "table" then
    local t = {}
    for i, v in ipairs (expectedtypes) do
      if v == "func" then
        t[i] = "function"
      elseif v == "any" then
        t[i] = "any value"
      elseif not index then
        t[i] = v:match "(%S+) of %S+" or v
      else
        t[i] = v
      end
    end
    expectedstr = concat (t):
                  gsub ("#table", "non-empty table"):
	          gsub ("#list", "non-empty list"):
                  gsub ("(%S+ of %S+)", "%1s"):
		  gsub ("(%S+ of %S+)ss", "%1s")
  end

  return expectedstr .. " expected, got " .. actualtype
end


--- Compare *check* against type of *actual*
-- @string check extended type name expected
-- @param actual object being typechecked
-- @treturn boolean `true` if *actual* is of type *check*, otherwise
--   `false`
local function checktype (check, actual)
  local actualtype = prototype (actual)
  if check == "#table" then
    if actualtype == "table" and next (actual) then
      return true
    end

  elseif check == "any" then
    if actual ~= nil then
      return true
    end

  elseif check == "file" then
    if io.type (actual) == "file" then
      return true
    end

  elseif check == "function" or check == "func" then
    if actualtype == "function" or
        (getmetatable (actual) or {}).__call ~= nil
    then
       return true
    end

  elseif check == "int" then
    if actualtype == "number" and actual == math.floor (actual) then
      return true
    end

  elseif check == "list" or check == "#list" then
    if actualtype == "table" or actualtype == "List" then
      local len, count = #actual, 0
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

  elseif type (check) == "string" and check:sub (1, 1) == ":" then
    if check == actual then
      return true
    end

  elseif check == actualtype then
    return true
  end

  return false
end


if _ARGCHECK then

  -- Doc-commented in debug.lua
  function argcheck (name, i, expected, actual, level)
    level = level or 2
    expected = normalize (split (expected, "|"))

    -- Check actual has one of the types from expected
    local ok = false
    for _, expect in ipairs (expected) do
      local check, contents = expect:match "^(%S+) of (%S-)s?$"
      check = check or expect

      -- Does the type of actual check out?
      ok = checktype (check, actual)

      -- For "table of things", check all elements are a thing too.
      if ok and contents and type (actual) == "table" then
        for k, v in pairs (actual) do
          if not checktype (contents, v) then
            argerror (name, i, formaterror (expected, v, k), level + 1)
          end
        end
      end
      if ok then break end
    end

    if not ok then
      argerror (name, i, formaterror (expected, actual), level + 1)
    end
  end


  -- Doc-commented in debug.lua
  function argscheck (name, expected, actual)
    if type (expected) ~= "table" then expected = {expected} end
    if type (actual) ~= "table" then actual = {actual} end

    for i, v in ipairs (expected) do
      argcheck (name, i, expected[i], actual[i], 3)
    end
  end

else

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



--[[ ============ ]]--
--[[ Maintenance. ]]--
--[[ ============ ]]--


-- Lua 5.1 requires 'debug.setfenv' to change environment of C funcs;
local _setfenv = debug.setfenv


local function setfenv (f, t)
  -- Unwrap functable:
  if type (f) == "table" then
    f = f.call or (getmetatable (f) or {}).__call
  end

  if _setfenv then
    return _setfenv (f, t)

  else
    -- From http://lua-users.org/lists/lua-l/2010-06/msg00313.html
    local name
    local up = 0
    repeat
      up = up + 1
      name = debug.getupvalue (f, up)
    until name == '_ENV' or name == nil
    if name then
      debug.upvaluejoin (f, up, function () return name end, 1)
      debug.setupvalue (f, up, t)
    end

    return f
  end
end


-- From http://lua-users.org/lists/lua-l/2010-06/msg00313.html
local getfenv = getfenv or function(f)
  f = (type(f) == 'function' and f or debug.getinfo(f + 1, 'f').func)
  local name, val
  local up = 0
  repeat
    up = up + 1
    name, val = debug.getupvalue(f, up)
  until name == '_ENV' or name == nil
  return val
end


local dirsep, pathsep, path_mark = package.config:match "^(%S+)\n(%S+)\n(%S+)\n"
local pathpatt, markpatt = "[^" .. pathsep .. "]+", path_mark:gsub ("%p", "%%%0")

local function whatpath (name, src)
  local r
  package.path:gsub (pathpatt, function (s)
    local substituted = s:gsub (markpatt, (name:gsub ("%.", dirsep)))
    if substituted == src then r = name end
  end)
  return r
end


local function getinfo (what, level)
  local fqfname, s, fn

  for i = 1, math.huge do
    s, fn = debug.getlocal (level + 1, i)

    if s == nil then
      break

    elseif s == what or fn == what then
      local t, src = {}, debug.getinfo (callable (fn), "S").source:gsub ("^@(.*)$", "%1")
      src:gsub ("/([^/]+)", function (m) t[#t + 1] = m:gsub ("%.lua", "") end)

      local tryme
      for i = #t, 1, -1 do
	tryme = tryme and (t[i] .. "." .. tryme) or t[i]
	if whatpath (tryme, src) then
	  fqfname = (tryme .. "." .. s):gsub ("^(std%.)base%.", "%1")
          break
	end
      end
      break

    end
  end

  return fqfname, fn
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
local function export (decl, ...)
  -- Parse "fname (argtype, argtype, argtype...)".
  local name, types = decl:match "([%w_][%d%w_]*)%s+%((.*)%)"
  if types == "" then
    types = {}
  elseif types then
    types = split (types, ",%s+")
  else
    name = decl:match "([%w_][%d%w_]*)"
  end
  local fqfname, inner = getinfo (name, 2)

  local fn = inner

  -- When argument checking is enabled, wrap in type checking function.
  if _ARGCHECK then
    -- If the final element of types ends with "*", then set max to a
    -- sentinel value to denote type-checking of *all* remaining
    -- unchecked arguments against that type-spec is required.
    local max, fin = #types, (types[#types] or ""):match "^(.+)%*$"
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

	-- For "table of things", check all elements are a thing too.
	if types[i] then
	  local check, contents = types[i]:match "^(%S+) of (%S-)s?$"
	  if contents and type (args[i]) == "table" then
	    for k, v in pairs (args[i]) do
	      if not checktype (contents, v) then
	        argerror (fqfname or name, i, formaterror (expected, v, k), 2)
	      end
	    end
	  end
        end

	-- Otherwise the argument type itself was mismatched.
	argerror (fqfname or name, i, formaterror (expected, args[i]), 2)
      end

      if argc > max then
        error (string.format (toomanyarg_fmt, fqfname or name, max, argc), 2)
      end

      -- Propagate outer environment to inner function.
      setfenv (inner, getfenv (1))

      return inner (...)
    end
  end

  return fn
end


-- Whether to show a deprecation warning the next time a give key is set.
local compat = {}


--- Determine whether *key* will show a deprecation warning on next access.
-- If `_DEBUG.compat` is not set, warn only the first time *fn* is called;
-- if `_DEBUG.compat` is false, warn every time *fn* is called;
-- otherwise don't write any warnings, and run *fn* normally.
-- @param key unique identifier for a deprecated API.
local function setcompat (key)
  compat[key] = (type (_DEBUG) == "table" and _DEBUG.compat == nil) or _DEBUG == true
end


--- Get the deprecation warning status for *key*.
-- @param key unique identifier for a deprecated API.
-- @treturn boolean whether to show a deprecation warning.
local function getcompat (key)
  if compat[key] == nil then
    -- Whether to warn on first access.
    compat[key] = (type (_DEBUG) == "table" and _DEBUG.compat) or _DEBUG == false
  end
  return compat[key]
end


--- Format a deprecation warning message.
-- @string version first deprecation release version
-- @string name function name for automatic warning message
-- @string[opt] extramsg additional warning text
-- @int level call stack level to blame for the error
-- @treturn string deprecation warning message
local function DEPRECATIONMSG (version, name, extramsg, level)
  if level == nil then level, extramsg = extramsg, nil end
  extramsg = extramsg or "and will be removed entirely in a future release"

  local _, where = pcall (function () error ("", level + 3) end)
  return (where .. string.format ("%s was deprecated in release %s, %s.\n",
                                  name, version, extramsg))
end


--- Write a deprecation warning to stderr.
-- If `_DEBUG.compat` is not set, warn only the first time *fn* is called;
-- if `_DEBUG.compat` is false, warn every time *fn* is called;
-- otherwise don't write any warnings, and run *fn* normally.
-- @string version first deprecation release version
-- @string name function name for automatic warning message
-- @string[opt] extramsg additional warning text
-- @func fn deprecated function
-- @return a function to show the warning on first call, and hand off to *fn*
-- @usage funcname = deprecate (function (...) ... end, "funcname")
local function DEPRECATED (version, name, extramsg, fn)
  if fn == nil then fn, extramsg = extramsg, nil end

  return function (...)
    if not getcompat (name) then
      io.stderr:write (DEPRECATIONMSG (version, name, extramsg, 2))
      setcompat (name)
    end
    return fn (...)
  end
end



--- Metamethods
-- @section Metamethods

return setmetatable ({
  "std.base",

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
  require  = require_version,
  tostring = tostring,

  -- object.lua --
  prototype = prototype,

  -- string.lua --
  render   = render,
  split    = split,

  -- table.lua --
  getmetamethod = getmetamethod,

  -- Argument Checking. --
  argcheck  = argcheck,
  argerror  = argerror,
  arglen    = arglen,
  argscheck = argscheck,

  -- Maintenance --
  DEPRECATED     = DEPRECATED,
  DEPRECATIONMSG = DEPRECATIONMSG,
  getcompat      = getcompat,
  setcompat      = setcompat,

  export         = export,
  len            = len,
  toomanyarg_fmt = toomanyarg_fmt,

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
