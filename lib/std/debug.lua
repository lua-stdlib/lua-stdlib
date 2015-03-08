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

local _DEBUG = debug_init._DEBUG
local argerror, raise = base.argerror, base.raise
local prototype, unpack = base.prototype, base.unpack
local copy, split, tostring = base.copy, base.split, base.tostring
local insert, last, len, maxn = base.insert, base.last, base.len, base.maxn
local ipairs, pairs = base.ipairs, base.pairs


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


local _getfenv = rawget (_G, "getfenv")

local getfenv = function (fn)
  fn = fn or 1

  -- Unwrap functable:
  if type (fn) == "table" then
    fn = fn.call or (getmetatable (fn) or {}).__call
  end

  if _getfenv then
    if type (fn) == "number" then fn = fn + 1 end

    -- Stack frame count is critical here, so ensure we don't optimise one
    -- away in LuaJIT...
    return _getfenv (fn), nil

  else
    if type (fn) == "number" then
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
end


local function resulterror (name, i, extramsg, level)
  level = level or 1
  raise ("result", "from", name, i, extramsg, level + 1)
end


local function extramsg_toomany (bad, expected, actual)
  local s = "no more than %d %s%s expected, got %d"
  return s:format (expected, bad, expected == 1 and "" or "s", actual)
end


--- Strip trailing ellipsis from final argument if any, storing maximum
-- number of values that can be matched directly in `t.maxvalues`.
-- @tparam table t table to act on
-- @string v element added to *t*, to match against ... suffix
-- @treturn table *t* with ellipsis stripped and maxvalues field set
local function markdots (t, v)
  return (v:gsub ("%.%.%.$", function () t.dots = true return "" end))
end


--- Calculate permutations of type lists with and without [optionals].
-- @tparam table t a list of expected types by argument position
-- @treturn table set of possible type lists
local function permute (t)
  if t[#t] then t[#t] = t[#t]:gsub ("%]%.%.%.$", "...]") end

  local p = {{}}
  for i, v in ipairs (t) do
    local optional = v:match "%[(.+)%]"

    if optional == nil then
      -- Append non-optional type-spec to each permutation.
      for b = 1, #p do
	insert (p[b], markdots (p[b], v))
      end
    else
      -- Duplicate all existing permutations, and add optional type-spec
      -- to the unduplicated permutations.
      local o = #p
      for b = 1, o do
        p[b + o] = copy (p[b])
        insert (p[b], markdots (p[b], optional))
      end
    end
  end
  return p
end


local function typesplit (types)
  if type (types) == "string" then
    types = split (types:gsub ("%s+or%s+", "|"), "%s*|%s*")
  end
  local r, seen, add_nil = {}, {}, false
  for _, v in ipairs (types) do
    local m = v:match "^%?(.+)$"
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
  for _, u in ipairs (tt) do
    t[#t + 1] = u[fkey]
  end

  -- split and remove duplicates
  local r, s = {}, {}
  for _, e in ipairs (t) do
    for _, v in ipairs (typesplit (e)) do
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


local function extramsg_mismatch (expectedtypes, actual, index)
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
    elseif check == "file" and io.type (actual) == "file" then
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


  local function empty (t) return not next (t) end

  -- Pattern to normalize: [types...] to [types]...
  local last_pat = "^%[([^%]%.]+)%]?(%.*)%]?"

  --- Diagnose mismatches between *valuelist* and type *permutations*.
  -- @tparam table valuelist list of actual values to be checked
  -- @tparam table argt table of precalculated values and handler functiens
  local function diagnose (valuelist, argt)
    local permutations = argt.permutations

    local bestmismatch, t = 0
    for i, typelist in ipairs (permutations) do
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
	local check, contents = typelist[i]:match "^(%S+) of (%S-)s?$"
	if contents and type (valuelist[i]) == "table" then
	  for k, v in pairs (valuelist[i]) do
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
    for _, expect in ipairs (expected) do
      local check, contents = expect:match "^(%S+) of (%S-)s?$"
      check = check or expect

      -- Does the type of actual check out?
      ok = checktype (check, actual)

      -- For "table of things", check all elements are a thing too.
      if ok and contents and type (actual) == "table" then
        for k, v in pairs (actual) do
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
    local fname, argtypes = decl:match (args_pat)
    if argtypes == "" then
      argtypes = {}
    elseif argtypes then
      argtypes = split (argtypes, "%s*,%s*")
    else
      fname = decl:match "^%s*([%w_][%.%:%d%w_]*)"
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
    local returntypes = decl:match "=>%s*(.+)%s*$"
    if returntypes then
      local i, permutations = 0, {}
      for _, group in ipairs (split (returntypes, "%s+or%s+")) do
	returntypes = split (group, ",%s*")
	for _, t in ipairs (permute (returntypes)) do
	  i = i + 1
          permutations[i] = t
	end
      end

      -- Ensure the longest permutation is first in the list.
      table.sort (permutations, function (a, b) return #a > #b end)

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
      if fname:find (":") then table.remove (argt, 1) end

      -- Diagnose bad inputs.
      diagnose (argt, input)

      -- Propagate outer environment to inner function.
      local x = math.max -- ??? getfenv(1) fails if we remove this ???
      setfenv (inner, getfenv (1))

      -- Execute.
      local results = {inner (...)}

      -- Diagnose bad outputs.
      if returntypes then
	diagnose (results, output)
      end

      return unpack (results, 1, maxn (results))
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
  -- as above, prepend a question mark to the list of types and omit the
  -- explicit "nil" entry:
  --
  --    argcheck ("table.copy", 2, "?boolean|:nometa", predicate)
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
  -- @see resulterror
  -- @see extramsg_mismatch
  -- @usage
  -- local function slurp (file)
  --   local h, err = input_handle (file)
  --   if h == nil then argerror ("std.io.slurp", 1, err, 2) end
  --   ...
  argerror = argerror,

  --- Wrap a function definition with argument type and arity checking.
  -- In addition to checking that each argument type matches the corresponding
  -- element in the *types* table with `argcheck`, if the final element of
  -- *types* ends with an ellipsis, remaining unchecked arguments are checked
  -- against that type:
  --
  --     format = argscheck ("string.format (string, ?any...)", string.format)
  --
  -- A colon in the function name indicates that the argument type list does
  -- not have a type for `self`:
  --
  --     format = argscheck ("string:format (?any...)", string.format)
  --
  -- If an argument can be omitted entirely, then put its type specification
  -- in square brackets:
  --
  --     insert = argscheck ("table.insert (table, [int], ?any)", table.insert)
  --
  -- Similarly return types can be checked with the same list syntax as
  -- arguments:
  --
  --     len = argscheck ("string.len (string) => int", string.len)
  --
  -- Additionally, variant return type lists can be listed like this:
  --
  --     open = argscheck ("io.open (string, ?string) => file or nil, string",
  --                       io.open)
  --
  -- @function argscheck
  -- @string decl function type declaration string
  -- @func inner function to wrap with argument checking
  -- @usage
  -- local case = argscheck ("std.functional.case (?any, #table) => [any...]",
  --   function (with, branches)
  --     ...
  -- end)
  argscheck = argscheck,

  --- Format a type mismatch error.
  -- @function extramsg_mismatch
  -- @string expected a pipe delimited list of matchable types
  -- @param actual the actual argument to match with
  -- @number[opt] index erroring container element index
  -- @treturn string formatted *extramsg* for this mismatch for @{argerror}
  -- @see argerror
  -- @see resulterror
  -- @usage
  --   if fmt ~= nil and type (fmt) ~= "string" then
  --     argerror ("format", 1, extramsg_mismatch ("?string", fmt))
  --   end
  extramsg_mismatch = function (expected, actual, index)
    return extramsg_mismatch (typesplit (expected), actual, index)
  end,

  --- Format a too many things error.
  -- @string bad the thing there are too many of
  -- @int expected maximum number of *bad* things expected
  -- @int actual actual number of *bad* things that triggered the error
  -- @see argerror
  -- @see resulterror
  -- @see extramsg_mismatch
  -- @usage
  --   if maxn (argt) > 7 then
  --     argerror ("sevenses", 8, extramsg_toomany ("argument", 7, maxn (argt)))
  --   end
  extramsg_toomany = extramsg_toomany,

  --- Extend `debug.getfenv` to unwrap functables correctly.
  -- @tparam int|function|functable fn target function, or stack level
  -- @treturn table environment of *fn*
  getfenv = getfenv,

  --- Compact permutation list into a list of valid types at each argument.
  -- Eliminate bracketed types by combining all valid types at each position
  -- for all permutations of *typelist*.
  -- @function parsetypes
  -- @tparam list types a normalized list of type names
  -- @treturn list valid types for each positional parameter
  parsetypes = parsetypes,

  --- Raise a bad result error.
  -- Like @{argerror} for bad results. This function does not
  -- return.  The `level` argument behaves just like the core `error`
  -- function.
  -- @string name function to callout in error message
  -- @int i argument number
  -- @string[opt] extramsg additional text to append to message inside parentheses
  -- @int[opt=1] level call stack level to blame for the error
  -- @usage
  -- local function slurp (file)
  --   local h, err = input_handle (file)
  --   if h == nil then argerror ("std.io.slurp", 1, err, 2) end
  --   ...
  resulterror = resulterror,

  --- Extend `debug.setfenv` to unwrap functables correctly.
  -- @tparam function|functable fn target function
  -- @tparam table env new function environment
  -- @treturn function *fn*
  setfenv = setfenv,

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

  --- Split a typespec string into a table of normalized type names.
  -- @tparam string|table either `"?bool|:nometa"` or `{"boolean", ":nometa"}`
  -- @treturn table a new list with duplicates removed and leading "?"s
  --   replaced by a "nil" element
  typesplit = typesplit,


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



--[[ =========== ]]--
--[[ Deprecated. ]]--
--[[ =========== ]]--


M.toomanyargmsg = DEPRECATED ("41.2.0", "debug.toomanyargmsg",
  "use 'debug.extramsg_toomany' instead",
  function (name, expect, actual)
    local s = "bad argument #%d to '%s' (no more than %d argument%s expected, got %d)"
    return s:format (expect + 1, name, expect, expect == 1 and "" or "s", actual)
  end)


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
