-- Assertions, warnings and errors

require "std/io/io.lua"
require "std/text/text.lua"


-- @func warn: Give warning with the name of program and file (if any)
--   @param ...: arguments for format
function warn (...)
  if prog.name then
    write (_STDERR, prog.name .. ":")
  end
  if prog.file then
    write (_STDERR, prog.file .. ":")
  end
  if prog.line then
    write (_STDERR, tostring (prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    write (_STDERR, " ")
  end
  writeLine (_STDERR, format (arg))
end

-- @func die: Die with error
--   @param ...: arguments for format
function die (...)
  warn (arg)
  error ()
end

-- @func assert: Die with error if value is false
-- Redefine assert to allow formatted arguments
--   @param v: value
--   @param ...: arguments for format
function assert (v, ...)
  if not v then
    error (call (format, arg or {""}))
  end
end

-- @func debug: Ignore a debugging message
-- (Loading debug overrides this)
function debug ()
end
