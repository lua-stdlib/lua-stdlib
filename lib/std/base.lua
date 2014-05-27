------
-- @module std.base

local typeof = type

-- Doc-commented in container.lua
local function prototype (o)
  return (getmetatable (o) or {})._type or type (o)
end


local init = require "std.debug_init"

local _ARGCHECK = init._DEBUG
if type (init._DEBUG) == "table" then
  _ARGCHECK = init._DEBUG.argcheck
  if _ARGCHECK == nil then _ARGCHECK= true end
end

local argcheck, argerror, argscheck

if not _ARGCHECK then

  local function nop () end

  -- Turn off argument checking if _DEBUG is false, or a table containing
  -- a false valued `argcheck` field.

  argcheck  = nop
  argscheck = nop

else

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


  -- Doc-commented in debug.lua
  function argcheck (name, i, expected, actual, level)
    level = level or 2
    if prototype (expected) ~= "table" then expected = {expected} end

    -- Check actual has one of the types from expected
    local ok, actualtype = false, prototype (actual)
    for i, check in ipairs (expected) do
      if check == "any" then
        expected[i] = "any value"
        if actual ~= nil then
          ok = true
        end

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

      elseif check == "function" then
        if actualtype == "function" or
            (getmetatable (actual) or {}).__call ~= nil
        then
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
      argerror (name, i, expected .. " expected, got " .. actualtype, level + 1)
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
  argscheck ("std.base.deprecate",
             {"function", {"string", "nil"}, {"string", "nil"}},
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


-- Doc-commented in list.lua...
local function elems (l)
  argcheck ("std.list.elems", 1, {"List", "table"}, l)

  local n = 0
  return function (l)
           n = n + 1
           if n <= #l then
             return l[n]
           end
         end,
  l, true
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


-- Doc-commented in table.lua...
local function metamethod (x, n)
  argscheck ("std.table.metamethod", {{"object", "table"}, "string"}, {x, n})

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
  argcheck   = argcheck,
  argerror   = argerror,
  argscheck  = argscheck,
  deprecate  = deprecate,
  elems      = elems,
  leaves     = leaves,
  metamethod = metamethod,
  prototype  = prototype,
}


return M
