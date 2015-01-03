--[[--
 Additions to the core debug module.

 The module table returned by `std.debug` also contains all of the entries
 from the core debug table.  An hygienic way to import this module, then, is
 simply to override the core `debug` locally:

    local debug = require "std.debug"

 The behaviour of the functions in this module are controlled by the value
 of the global `_DEBUG`.  Not setting `_DEBUG` prior to requiring **any** of
 stdlib's modules is equivalent to having `_DEBUG = true`.

 The first line of Lua code in production quality projects that use stdlib
 should be either:

     _DEBUG = false

 or alternatively, if you need to be careful not to damage the global
 environment:

     local init = require "std.debug_init"
     init._DEBUG = false

 This mitigates almost all of the overhead of argument typechecking in
 stdlib API functions.

 @module std.debug
]]


local debug_init = require "std.debug_init"
local base       = require "std.base"

local _DEBUG      = debug_init._DEBUG
local argerror    = base.argerror
local split, tostring = base.split, base.tostring
local insert, last, len, maxn = base.insert, base.last, base.len, base.maxn
local ipairs, pairs = base.ipairs, base.pairs
local unpack = table.unpack or unpack

local M


-- Return a deprecation message if _DEBUG.deprecate is `nil`, otherwise "".
local function DEPRECATIONMSG (version, name, extramsg, level)
  if level == nil then level, extramsg = extramsg, nil end
  extramsg = extramsg or "and will be removed entirely in a future release"

  local _, where = pcall (function () error ("", level + 3) end)
  if _DEBUG.deprecate == nil then
    return (where .. string.format ("%s was deprecated in release %s, %s.\n",
                                    name, tostring (version), extramsg))
  end

  return ""
end


-- Define deprecated functions when _DEBUG.deprecate is not "truthy",
-- and write `DEPRECATIONMSG` output to stderr.
local function DEPRECATED (version, name, extramsg, fn)
  if fn == nil then fn, extramsg = extramsg, nil end

  if not _DEBUG.deprecate then
    return function (...)
      io.stderr:write (DEPRECATIONMSG (version, name, extramsg, 2))
      return fn (...)
    end
  end
end


--- Extend `debug.setfenv` to unwrap functables correctly.
-- @tparam function|functable fn target function
-- @tparam table env new function environment
-- @treturn function *fn*

local _setfenv = debug.setfenv

local function setfenv (fn, env)
  -- Unwrap functable:
  if type (fn) == "table" then
    fn = fn.call or (getmetatable (fn) or {}).__call
  end

  if _setfenv then
    return _setfenv (fn, env)

  else
    -- From http://lua-users.org/lists/lua-l/2010-06/msg00313.html
    local name
    local up = 0
    repeat
      up = up + 1
      name = debug.getupvalue (fn, up)
    until name == '_ENV' or name == nil
    if name then
      debug.upvaluejoin (fn, up, function () return name end, 1)
      debug.setupvalue (fn, up, env)
    end

    return fn
  end
end


--- Extend `debug.getfenv` to unwrap functables correctly.
-- @tparam int|function|functable fn target function, or stack level
-- @treturn table environment of *fn*
local getfenv = getfenv or function (fn)
  -- Unwrap functable:
  if type (fn) == "table" then
    fn = fn.call or (getmetatable (fn) or {}).__call
  elseif type (fn) == "number" then
    fn = debug.getinfo (fn + 1, "f").func
  end

  local name, env
  local up = 0
  repeat
    up = up + 1
    name, env = debug.getupvalue (fn, up)
  until name == '_ENV' or name == nil
  return env
end


local function toomanyargmsg (name, expect, actual)
  local fmt = "bad argument #%d to '%s' (no more than %d argument%s expected, got %d)"
  return string.format (fmt, expect + 1, name, expect, expect == 1 and "" or "s", actual)
end


local argcheck, argscheck  -- forward declarations

if _DEBUG.argcheck then

  local copy, prototype = base.copy, base.prototype

  --- Concatenate a table of strings using ", " and " or " delimiters.
  -- @tparam table alternatives a table of strings
  -- @treturn string string of elements from alternatives delimited by ", "
  --   and " or "
  local function concat (alternatives)
    if len (alternatives) > 1 then
      local t = copy (alternatives)
      local top = table.remove (t)
      t[#t] = t[#t] .. " or " .. top
      alternatives = t
    end
    return table.concat (alternatives, ", ")
  end


  --- Normalize a list of type names.
  -- @tparam table t list of type names, trailing "?" as required
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
        if last (v) == sentinel then table.remove (v) end
      end

      local opt = v:match "%[(.+)%]"
      if opt == nil then
        -- Append non-optional type-spec to each permutation.
        for b = 1, len (p) do insert (p[b], v) end
      else
        -- Duplicate all existing permutations, and add optional type-spec
        -- to the unduplicated permutations.
        local o = len (p)
        for b = 1, o do
          p[b + o] = copy (p[b])
	  insert (p[b], opt)
        end

        -- Leave a marker for optional argument in final position.
        for _, v in ipairs (p) do
	  insert (v, sentinel)
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
  -- @tparam boolean allargs whether to match all arguments
  -- @treturn int|nil position of first mismatch in *types*
  local function match (types, args, allargs)
    local typec, argc = len (types), maxn (args)
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
  -- @number[opt] index erroring container element index
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
	elseif v == "file" then
          t[i] = "FILE*"
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
    if check == "any" and actual ~= nil then
      return true
    elseif check == "file" and io.type (actual) == "file" then
      return true
    end

    local actualtype = type (actual)
    if check == actualtype then
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
      if actualtype == "number" and actual == math.floor (actual) then
        return true
      end
    elseif type (check) == "string" and check:sub (1, 1) == ":" then
      if check == actual then
        return true
      end
    end

    actualtype = prototype (actual)
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


  function argscheck (decl, inner)
    -- Parse "fname (argtype, argtype, argtype...)".
    local fname, types = decl:match "([%w_][%.%d%w_]*)%s+%(%s*(.*)%s*%)"
    if types == "" then
      types = {}
    elseif types then
      types = split (types, ",%s*")
    else
      fname = decl:match "([%w_][%.%d%w_]*)"
    end

    -- If the final element of types ends with "*", then set max to a
    -- sentinel value to denote type-checking of *all* remaining
    -- unchecked arguments against that type-spec is required.
    local max, fin = len (types), (last (types) or ""):match "^(.+)%*$"
    if fin then
      max = math.huge
      types[len (types)] = fin
    end

    -- For optional arguments wrapped in square brackets, make sure
    -- type-specs allow for passing or omitting an argument of that
    -- type.
    local typec, type_specs = len (types), permutations (types)

    return function (...)
      local args = {...}
      local argc, bestmismatch, at = maxn (args), 0, 0

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
              insert (tables, types[bestmismatch])
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
	        argerror (fname, i, formaterror (expected, v, k), 2)
	      end
	    end
	  end
        end

	-- Otherwise the argument type itself was mismatched.
	argerror (fname, i, formaterror (expected, args[i]), 2)
      end

      if argc > max then
        error (toomanyargmsg (fname, max, argc), 2)
      end

      -- Propagate outer environment to inner function.
      setfenv (inner, getfenv (1))

      return inner (...)
    end
  end

else

  -- Turn off argument checking if _DEBUG is false, or a table containing
  -- a false valued `argcheck` field.

  argcheck  = base.nop
  argscheck = function (decl, inner) return inner end

end


local function say (n, ...)
  local level, argt = n, {...}
  if type (n) ~= "number" then
    level, argt = 1, {n, ...}
  end
  if _DEBUG.level ~= math.huge and
      ((type (_DEBUG.level) == "number" and _DEBUG.level >= level) or level <= 1)
  then
    local t = {}
    for k, v in pairs (argt) do t[k] = tostring (v) end
    io.stderr:write (table.concat (t, "\t") .. "\n")
  end
end


local level = 0

local function trace (event)
  local t = debug.getinfo (3)
  local s = " >>> "
  for i = 1, level do s = s .. " " end
  if t ~= nil and t.currentline >= 0 then
    s = s .. t.short_src .. ":" .. t.currentline .. " "
  end
  t = debug.getinfo (2)
  if event == "call" then
    level = level + 1
  else
    level = math.max (level - 1, 0)
  end
  if t.what == "main" then
    if event == "call" then
      s = s .. "begin " .. t.short_src
    else
      s = s .. "end " .. t.short_src
    end
  elseif t.what == "Lua" then
    s = s .. event .. " " .. (t.name or "(Lua)") .. " <" ..
      t.linedefined .. ":" .. t.short_src .. ">"
  else
    s = s .. event .. " " .. (t.name or "(C)") .. " [" .. t.what .. "]"
  end
  io.stderr:write (s .. "\n")
end

-- Set hooks according to _DEBUG
if type (_DEBUG) == "table" and _DEBUG.call then
  debug.sethook (trace, "cr")
end



M = {
  --- Provide a deprecated function definition according to _DEBUG.deprecate.
  -- You can check whether your covered code uses deprecated functions by
  -- setting `_DEBUG.deprecate` to  `true` before loading any stdlib modules,
  -- or silence deprecation warnings by setting `_DEBUG.deprecate = false`.
  -- @function DEPRECATED
  -- @string version first deprecation release version
  -- @string name function name for automatic warning message
  -- @string[opt] extramsg additional warning text
  -- @func fn deprecated function
  -- @return a function to show the warning on first call, and hand off to *fn*
  -- @usage
  -- M.op = DEPRECATED ("41", "'std.functional.op'", std.operator)
  DEPRECATED = DEPRECATED,

  --- Format a deprecation warning message.
  -- @function DEPRECATIONMSG
  -- @string version first deprecation release version
  -- @string name function name for automatic warning message
  -- @string[opt] extramsg additional warning text
  -- @int level call stack level to blame for the error
  -- @treturn string deprecation warning message, or empty string
  -- @usage
  -- io.stderr:write (DEPRECATIONMSG ("42", "multi-argument 'module.fname'", 2))
  DEPRECATIONMSG = DEPRECATIONMSG,

  --- Check the type of an argument against expected types.
  -- Equivalent to luaL_argcheck in the Lua C API.
  --
  -- Call `argerror` if there is a type mismatch.
  --
  -- Argument `actual` must match one of the types from in `expected`, each
  -- of which can be the name of a primitive Lua type, a stdlib object type,
  -- or one of the special options below:
  --
  --    #table    accept any non-empty table
  --    any       accept any non-nil argument type
  --    file      accept an open file object
  --    function  accept a function, or object with a __call metamethod
  --    int       accept an integer valued number
  --    list      accept a table where all keys are a contiguous 1-based integer range
  --    #list     accept any non-empty list
  --    object    accept any std.Object derived type
  --    :foo      accept only the exact string ":foo", works for any :-prefixed string
  --
  -- The `:foo` format allows for type-checking of self-documenting
  -- boolean-like constant string parameters predicated on `nil` versus
  -- `:option` instead of `false` versus `true`.  Or you could support
  -- both:
  --
  --    argcheck ("table.copy", 2, "boolean|:nometa|nil", nometa)
  --
  -- A very common pattern is to have a list of possible types including
  -- "nil" when the argument is optional.  Rather than writing long-hand
  -- as above, append a question mark to at least one of the list types
  -- and omit the explicit "nil" entry:
  --
  --    argcheck ("table.copy", 2, "boolean|:nometa?", predicate)
  --
  -- Normally, you should not need to use the `level` parameter, as the
  -- default is to blame the caller of the function using `argcheck` in
  -- error messages; which is almost certainly what you want.
  -- @function argcheck
  -- @string name function to blame in error message
  -- @int i argument number to blame in error message
  -- @string expected specification for acceptable argument types
  -- @param actual argument passed
  -- @int[opt=2] level call stack level to blame for the error
  -- @usage
  -- local function case (with, branches)
  --   argcheck ("std.functional.case", 2, "#table", branches)
  --   ...
  argcheck = argcheck,

  --- Raise a bad argument error.
  -- Equivalent to luaL_argerror in the Lua C API. This function does not
  -- return.  The `level` argument behaves just like the core `error`
  -- function.
  -- @function argerror
  -- @string name function to callout in error message
  -- @int i argument number
  -- @string[opt] extramsg additional text to append to message inside parentheses
  -- @int[opt=1] level call stack level to blame for the error
  -- @usage
  -- local function slurp (file)
  --   local h, err = input_handle (file)
  --   if h == nil then argerror ("std.io.slurp", 1, err, 2) end
  --   ...
  argerror = argerror,

  --- Wrap a function definition with argument type and arity checking.
  -- In addition to checking that each argument type matches the corresponding
  -- element in the *types* table with `argcheck`, if the final element of
  -- *types* ends with an asterisk, remaining unchecked arguments are checked
  -- against that type.
  -- @function argscheck
  -- @string decl function type declaration string
  -- @func inner function to wrap with argument checking
  -- @usage
  -- M.square = argscheck ("util.square (number)", function (n) return n * n end)
  argscheck = argscheck,

  --- Print a debugging message to `io.stderr`.
  -- Display arguments passed through `std.tostring` and separated by tab
  -- characters when `_DEBUG` is `true` and *n* is 1 or less; or `_DEBUG.level`
  -- is a number greater than or equal to *n*.  If `_DEBUG` is false or
  -- nil, nothing is written.
  -- @function say
  -- @int[opt=1] n debugging level, smaller is higher priority
  -- @param ... objects to print (as for print)
  -- @usage
  -- local _DEBUG = require "std.debug_init"._DEBUG
  -- _DEBUG.level = 3
  -- say (2, "_DEBUG table contents:", _DEBUG)
  say = say,

  --- Format a standard "too many arguments" error message.
  -- @fixme remove this wart!
  -- @function toomanyargmsg
  -- @string name function name
  -- @number expect maximum number of arguments accepted
  -- @number actual number of arguments received
  -- @treturn string standard "too many arguments" error message
  -- @usage
  -- if table.maxn {...} > 1 then
  --   io.stderr:write ("module.fname", 7, table.maxn {...})
  -- ...
  toomanyargmsg = toomanyargmsg,

  --- Trace function calls.
  -- Use as debug.sethook (trace, "cr"), which is done automatically
  -- when `_DEBUG.call` is set.
  -- Based on test/trace-calls.lua from the Lua distribution.
  -- @function trace
  -- @string event event causing the call
  -- @usage
  -- _DEBUG = { call = true }
  -- local debug = require "std.debug"
  trace = trace,


  -- Private:
  _setdebug = function (t)
    for k, v in pairs (t) do
      if v == "nil" then v = nil end
      _DEBUG[k] = v
    end
  end,
}


for k, v in pairs (debug) do
  M[k] = M[k] or v
end

--- Equivalent to calling `debug.say (1, ...)`
-- @function debug
-- @see say
-- @usage
-- local debug = require "std.debug"
-- debug "oh noes!"
local metatable = {
  __call = function (self, ...)
             M.say (1, ...)
           end,
}

return setmetatable (M, metatable)



--- Control std.debug function behaviour.
-- To declare debugging state, set _DEBUG either to `false` to disable all
-- runtime debugging; to any "truthy" value (equivalent to enabling everything
-- except *call*, or as documented below.
-- @class table
-- @name _DEBUG
-- @tfield[opt=true] boolean argcheck honor argcheck and argscheck calls
-- @tfield[opt=false] boolean call do call trace debugging
-- @field[opt=nil] deprecate if `false`, deprecated APIs are defined,
--   and do not issue deprecation warnings when used; if `nil` issue a
--   deprecation warning each time a deprecated api is used; any other
--   value causes deprecated APIs not to be defined at all
-- @tfield[opt=1] int level debugging level
-- @usage _DEBUG = { argcheck = false, level = 9 }
