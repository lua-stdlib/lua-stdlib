-- Assertions, warnings and errors

-- TODO: Expand print to register printers for arbitrary tags: these
--   can either be a function from objects to strings, or a list of
--   fields to print. It would be good if luaswig could generate these
--   automatically

require "std/text/text.lua"
require "std/io/io.lua"


-- warn: Give warning with the name of program and file (if any)
--   s: string
function warn (s)
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
  writeLine (_STDERR, s)
end

-- die: Die with error
--   s: string
function die (s)
  warn (s)
  error ()
end

-- affirm: Die with error if value is false
--   v: value
--   s: string
function affirm (v, s)
  if not v then
    error (s)
  end
end

-- debug: Ignore a debugging message
function debug ()
end

-- warnf: Give formatted warning
--   f: format
--   ...: format argument
function warnf (...)
  warn (call (format, arg))
end

-- dief: Die with formatted error
--   f: format
--   ...: format argument
function dief (...)
  die (call (format, arg))
end

-- affirmf: Die with formatted error if value is false
--   v: value
--   f: format
--   ...: format argument
function affirmf (v, ...)
  affirm (v, call (format, arg))
end

-- debugf: Print a formatted debugging message
--   f: format
--   ...: format argument
function debugf (...)
  debug (call (format, arg))
end

-- print: Extend print to work better on tables
--   arg: objects to print
local _print = print
function print (...)
  for i = 1, getn (arg) do
    arg[i] = tostring (arg[i])
  end
  call (%_print, arg)
end
