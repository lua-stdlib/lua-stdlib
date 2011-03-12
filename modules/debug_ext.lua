-- @module debug

-- Adds to the existing debug module

module ("debug", package.seeall)

require "debug_init"
require "io_ext"
require "string_ext"

-- To activate debugging set _DEBUG either to any true value
-- (equivalent to {level = 1}), or a table with the following members:

-- level: debugging level
-- call: do call trace debugging
-- std: do standard library debugging (run examples & test code)


-- @func say: Print a debugging message
--   @param [n]: debugging level [1]
--   ...: objects to print (as for print)
function say (...)
  local level = 1
  local arg = {...}
  if type (arg[1]) == "number" then
    level = arg[1]
    table.remove (arg, 1)
  end
  if _DEBUG and
    ((type (_DEBUG) == "table" and type (_DEBUG.level) == "number" and
      _DEBUG.level >= level)
       or level <= 1) then
    io.writeLine (io.stderr, table.concat (list.map (tostring, arg), "\t"))
  end
end

-- Expose say as global function `debug'
getmetatable (_M).__call =
   function (self, ...)
     say (...)
   end

-- @func traceCall: Trace function calls
--   @param event: event causing the call
-- Use: debug.sethook (trace, "cr"), as below
-- based on test/trace-calls.lua from the Lua distribution
local level = 0
function trace (event)
  local t = getinfo (3)
  local s = " >>> " .. string.rep (" ", level)
  if t ~= nil and t.currentline >= 0 then
    s = s .. t.short_src .. ":" .. t.currentline .. " "
  end
  t = getinfo (2)
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
  io.writeLine (io.stderr, s)
end

-- Set hooks according to _DEBUG
if type (_DEBUG) == "table" and _DEBUG.call then
  sethook (trace, "cr")
end
