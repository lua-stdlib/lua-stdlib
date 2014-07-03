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


local _DEBUG     = require "std.debug_init"._DEBUG

local base       = require "std.base"
local functional = require "std.functional"
local string     = require "std.string"

local export = base.export
local M      = { "std.debug" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Stringify a list of objects, then tabulate the resulting list of strings.
-- @tparam table list of elements
-- @treturn string tab delimited string
-- @usage s = tabify {...}
local tabify = functional.compose (
        -- map (elementfn, iterfn, unnbound_table_arg)
        functional.bind (functional.map, {string.tostring, base.ielems}),
        -- table.concat (unbound_strbuf_table, "\t")
        functional.bind (table.concat, {[2] = "\t"}))



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Control std.debug function behaviour.
-- To activate debugging set _DEBUG either to any true value
-- (equivalent to {level = 1}), or as documented below.
-- @class table
-- @name _DEBUG
-- @field argcheck honor argcheck and argscheck calls
-- @field call do call trace debugging
-- @field level debugging level
-- @usage _DEBUG = { argcheck = false, level = 9 }


--- Print a debugging message to `io.stderr`.
-- Display arguments passed through `std.string.tostring` and separated by tab
-- characters when `_DEBUG` is `true` and *n* is 1 or less; or `_DEBUG.level`
-- is a number greater than or equal to *n*.  If `_DEBUG` is false or
-- nil, nothing is written.
-- @int[opt=1] n debugging level, smaller is higher priority
-- @param ... objects to print (as for print)
-- @usage
-- local _DEBUG = require "std.debug_init"._DEBUG
-- _DEBUG.level = 3
-- say (2, "_DEBUG table contents:", _DEBUG)
function M.say (n, ...)
  local level = 1
  local arg = {n, ...}
  if type (arg[1]) == "number" then
    level = arg[1]
    table.remove (arg, 1)
  end
  if _DEBUG and
    ((type (_DEBUG) == "table" and type (_DEBUG.level) == "number" and
      _DEBUG.level >= level)
       or level <= 1) then
    io.stderr:write (tabify (arg) .. "\n")
  end
end


local level = 0

--- Trace function calls.
-- Use as debug.sethook (trace, "cr"), which is done automatically
-- when `_DEBUG.call` is set.
-- Based on test/trace-calls.lua from the Lua distribution.
-- @function trace
-- @string event event causing the call
-- @usage
-- _DEBUG = { call = true }
-- local debug = require "std.debug"
function M.trace (event)
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
  io.stderr:write (s .. "\n")
end

-- Set hooks according to _DEBUG
if type (_DEBUG) == "table" and _DEBUG.call then
  debug.sethook (M.trace, "cr")
end


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
M.argerror = base.argerror

--[[
 Puc-Rio Lua 5.1 messes up tail-call elimination in the argcheck wrapper,
 and this function has to count stack frames correctly and so breaks in
 that case.  After 5.1 support is dropped, we can enable the
 following:

export (M, "argerror (string, int, string?, int?)", base.argerror)
]]


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
M.argcheck = base.argcheck

--[[
 Puc-Rio Lua 5.1 messes up tail-call elimination in the argcheck wrapper,
 and this function has to count stack frames correctly and so breaks in
 that case.  After 5.1 support is dropped, we can enable the
 following:

export (M, "argcheck (string, int, string, any?, int?)", base.argcheck)
]]

--- Check that all arguments match specified types.
-- @function argscheck
-- @string name function to blame in error message
-- @tparam table expected a list of acceptable argument types
-- @tparam table actual table of argument values
-- @usage
-- local function curry (f, n)
--   argscheck ("std.functional.curry", {"function", "int"}, {f, n})
--   ...
M.argscheck = base.argscheck

--[[
 Puc-Rio Lua 5.1 messes up tail-call elimination in the argcheck wrapper,
 and this function has to count stack frames correctly and so breaks in
 that case.  After 5.1 support is dropped, we can enable the
 following:

export (M, "argscheck (string, #list, table)", base.argscheck)
]]


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
