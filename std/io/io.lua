-- I/O

require "std/data/code.lua"


-- EOL string
endOfLine = "\n"

-- writeLine: Write values adding a newline after each
--   [h]: file handle [_OUTPUT]
--   ...: values to write (as for write)
function writeLine (h, ...)
  if tag (h) ~= tag (_STDERR) then
    tinsert (arg, 1, h)
    h = _OUTPUT
  end
  for i = 1, getn (arg) do
    write (h, arg[i], endOfLine)
  end
end

-- readLines: Read _INPUT into a list of lines
-- returns
--   line: list of lines
function readLines ()
  local line = {}
  local l
  repeat
    l = read ("*l")
    if l then
      tinsert (line, l)
    end
  until l == nil
  return line
end

-- readFile: Read a file into a string
--   f: file name
-- returns
--   s: string
function readFile (f)
  local h = openfile (f, "r")
  if not h then
    error ("can't read " .. f)
  end
  local s = read (h, "*a")
  closefile (h)
  return s
end

-- evalFile: Read a file as a value
--   f: file name
-- returns
--   v: value
function evalFile (f)
  return eval (readFile (f))
end

-- Change the suffix of a filename
--   from: suffix to change [.-]
--   to: suffix to replace with
--   name: file name to change
-- returns
--   name_: file name with new suffix
function changeSuffix (from, to, name)
  local from = from or ".-"
  return gsub (name, "%." .. from .. "$", "") .. "." .. to
end

-- Add a suffix to a filename
--   suff: suffix to add
--   name: file name to change
-- returns
--   name_: file name with new suffix
function addSuffix (suff, name)
  return changeSuffix (suff, suff, name)
end
