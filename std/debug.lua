-- Debugging
-- Requires that the Lua debug library be available

-- TODO: Expand print to register printers for arbitrary tags: these
--   can either be a function from objects to strings, or a list of
--   fields to print. It would be good if luaswig could generate these
--   automatically

require "std/patch40.lua"
require "std/io/io.lua"
require "std/text/text.lua"
require "std/assert.lua" -- so that debug can be overridden


-- _DEBUG is either any true value (equivalent to {level = 1}), or a
-- table with the following keys:

-- level: debugging level [1]
-- call: do call trace debugging
-- std: do standard library debugging (run examples & test code)


-- print: Extend print to work better on tables
--   arg: objects to print
local _print = print
function print (...)
  for i = 1, getn (arg) do
    arg[i] = tostring (arg[i])
  end
  call (%_print, arg)
end

-- debug: Print a debugging message
--   [n]: debugging level [1]
--   ...: objects to print (as for print)
function debug (...)
  local level = 1
  if type (arg[1]) == "number" then
    level = arg[1]
    tremove (arg, 1)
  end
  if _DEBUG and
    ((type (_DEBUG) == "table" and type (_DEBUG.level) == "number" and
      _DEBUG.level >= level)
       or level <= 1) then
    writeLine (_STDERR, join ("\t", map (tostring, arg)))
  end
end

-- traceCall: Trace function calls
-- Use: setcallhook (traceCall), as below
-- based on test/trace-calls.lua from the 4.0 distribution
function traceCall (func)
  local t = getinfo (2)
  local name = t.name or "?"
  local s = ">>> "
  if t.what == "main" then
    if func == "call" then
      s = s .. "begin " .. t.source
    else
      s = s .. "end " .. t.source
    end
  else
    s = s .. func .. " " .. name
    if t.what == "Lua" then
      s = s .. " <" .. t.linedefined .. ":" .. t.source .. ">"
    else
      s = s .. " [" .. t.what .. "]"
    end
  end
  if t.currentline >= 0 then
    s = ":" .. t.currentline
  end
  writeLine (_STDERR, s)
end

-- Set hooks according to _DEBUG
if type (_DEBUG) == "table" and _DEBUG.call then
  setcallhook (traceCall)
end
