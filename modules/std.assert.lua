-- Assertions, warnings and errors

require "std.io.io"
require "std.text.text"


-- @func warn: Give warning with the name of program and file (if any)
--   @param ...: arguments for format
function warn (...)
  if prog.name then
    io.stderr:write (prog.name .. ":")
  end
  if prog.file then
    io.stderr:write (prog.file .. ":")
  end
  if prog.line then
    io.stderr:write (tostring (prog.line) .. ":")
  end
  if prog.name or prog.file or prog.line then
    io.stderr:write (" ")
  end
  writeLine (io.stderr, string.format (unpack (arg)))
end

-- @func die: Die with error
--   @param ...: arguments for format
function die (...)
  warn (unpack (arg))
  error (false)
end

-- @func assert: Die with error if value is false
-- Redefine assert to allow formatted arguments
--   @param v: value
--   @param ...: arguments for format
function assert (v, ...)
  if not v then
    error (string.format (unpack (arg or {""})))
  end
end

-- @func debug: Ignore a debugging message
-- (Loading debug overrides this)
function debug ()
end
