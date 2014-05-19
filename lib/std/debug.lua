--[[--
 Additions to the debug module.

 The behaviour of the functions in this module are controlled by the value
 of the global `_DEBUG`.  Not setting `_DEBUG` prior to requiring any of
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

local init   = require "std.debug_init"
local io     = require "std.io"
local list   = require "std.list"
local Object = require "std.object"
local string = require "std.string"

local prototype = Object.prototype
local typeof    = type


--- Control std.debug function behaviour.
-- To activate debugging set _DEBUG either to any true value
-- (equivalent to {level = 1}), or as documented below.
-- @class table
-- @name _DEBUG
-- @field argcheck honor argcheck and argscheck calls
-- @field call do call trace debugging
-- @field level debugging level


--- Concatenate a table of strings using ", " and " or " delimiters.
-- @tparam table alternatives a table of strings
-- @treturn string string of elements from alternatives delimited by ", "
--   and " or "
local function concat (alternatives)
  local t, i = {}, 1
  while i < #alternatives do
    t[i] = alternatives[i]
    i = i + 1
  end
  if #alternatives > 1 then
    t[#t] = t[#t] .. " or " .. alternatives[#alternatives]
  else
    t = alternatives
  end
  return table.concat (t, ", ")
end


--- Print a debugging message.
-- @param n debugging level, defaults to 1
-- @param ... objects to print (as for print)
local function say (n, ...)
  local level = 1
  local arg = {n, ...}
  if type (arg[1]) == "number" then
    level = arg[1]
    table.remove (arg, 1)
  end
  if init._DEBUG and
    ((type (init._DEBUG) == "table" and type (init._DEBUG.level) == "number" and
      init._DEBUG.level >= level)
       or level <= 1) then
    io.writelines (io.stderr, table.concat (list.map (string.tostring, arg), "\t"))
  end
end

--- Trace function calls.
-- Use as debug.sethook (trace, "cr"), which is done automatically
-- when _DEBUG.call is set.
-- Based on test/trace-calls.lua from the Lua distribution.
-- @class function
-- @name trace
-- @param event event causing the call
local level = 0
local function trace (event)
  local t = debug.getinfo (3)
  local s = " >>> " .. string.rep (" ", level)
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
  io.writelines (io.stderr, s)
end

-- Set hooks according to init._DEBUG
if type (init._DEBUG) == "table" and init._DEBUG.call then
  debug.sethook (trace, "cr")
end


--- Raise a bad argument error.
-- Equivalent to luaL_argerror in the Lua C API. This function does not
-- return.  The `level` argument behaves just like the core `error`
-- function.
-- @string name function to callout in error message
-- @int i argument number
-- @string[opt] extramsg additional text to append to message inside parentheses
-- @int[opt=1] level call stack level to blame for the error
local function argerror (name, i, extramsg, level)
  level = level or 1
  local s = string.format ("bad argument #%d to '%s'", i, name)
  if extramsg ~= nil then
    s = s .. " (" .. extramsg .. ")"
  end
  return error (s, level + 1)
end


--- Check the type of an argument against expected types.
-- Equivalent to luaL_argcheck in the Lua C API.
-- Argument `actual` must match one of the types from in `expected`, each
-- of which can be the name of a primitive Lua type, a stdlib object type,
-- or one of the special options below:
--
--    #table    accept any non-empty table
--    list      accept a table with a non-empty array part
--    object    accept any std.Object derived type
--    any       accept any argument type
--
-- Call `argerror` if there is a type mismatch.
--
-- Normally, you should not need to use the `level` parameter, as the
-- default is to blame the caller of the function using `argcheck` in
-- error messages; which is almost certainly what you want.
-- @string name function to blame in error message
-- @int i argument number to blame in error message
-- @tparam table|string expected a list of acceptable argument types
-- @param actual argument passed
-- @int[opt=2] level call stack level to blame for the error
local function argcheck (name, i, expected, actual, level)
  level = level or 2
  if prototype (expected) ~= "table" then expected = {expected} end

  -- Check actual has one of the types from expected
  local ok, actualtype = false, prototype (actual)
  for _, check in ipairs (expected) do
    if check == "any" then
      ok = true

    elseif check == "#table" then
      if actualtype == "table" and next (actual) then
        ok = true
      end

    elseif check == "list" then
      if typeof (actual) == "table" and #actual > 0 then
	ok = true
      end

    elseif check == "object" then
      if actualtype ~= "table" and typeof (actual) == "table" then
        ok = true
      end

    elseif check == actualtype then
      ok = true
    end

    if ok then break end
  end

  if not ok then
    if actualtype == "nil" then
      actualtype = "no value"
    elseif actualtype == "table" and next (actual) == nil then
      actualtype = "empty table"
    elseif actualtype == "List" and #actual == 0 then
      actualtype = "empty List"
    end
    expected = concat (expected):gsub ("#table", "non-empty table")
    return argerror (name, i, expected .. " expected, got " .. actualtype, level)
  end
end


--- Check that all arguments match specified types.
-- @string name function to blame in error message
-- @tparam table|string expected a list of lists of acceptable argument types
-- @tparam table|any actual argument value, or table of argument values
local function argscheck (name, expected, actual)
  if typeof (expected) ~= "table" then expected = {expected} end
  if typeof (actual) ~= "table" then actual = {actual} end

  for i, v in ipairs (expected) do
    if v ~= "any" then
      argcheck (name, i, expected[i], actual[i], 3)
    end
  end
end


--- @export
local M = {
  argcheck  = argcheck,
  argerror  = argerror,
  argscheck = argscheck,
  say       = say,
  trace     = trace,
}


-- Turn off argument checking if _DEBUG is false, or a table containing
-- a false valued `argcheck` field.

local _ARGCHECK = init._DEBUG
if type (init._DEBUG) == "table" then
  _ARGCHECK = init._DEBUG.argcheck
  if _ARGCHECK == nil then _ARGCHECK= true end
end

if not _ARGCHECK then
  M.argcheck  = function () end
  M.argscheck = function () end
end


for k, v in pairs (debug) do
  M[k] = M[k] or v
end

--- Equivalent to calling `debug.say (1, ...)`
-- @function debug
-- @see say
local metatable = {
  __call = function (self, ...)
             say (1, ...)
           end,
}

return setmetatable (M, metatable)
