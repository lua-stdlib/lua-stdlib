-- I/O

require "std.data.code"


-- EOL string
endOfLine = "\n"

-- @func writeLine: Write values adding a newline after each
--   @param [h]: file handle [_OUTPUT]
--   @param ...: values to write (as for write)
function writeLine (h, ...)
  if tag (h) ~= tag (_STDERR) then
    tinsert (arg, 1, h)
    h = _OUTPUT
  end
  for i = 1, getn (arg) do
    write (h, arg[i], endOfLine)
  end
end

-- @func withFileOrHandle: Generalise a file function
-- Turns a function accepting a file handle to one that accepts a file
-- handle or name, defaulting to _INPUT/_OUTPUT, and opens and closes
-- the given file if necessary.
--   @param fun: function
--     @param h: handle
--     @param ...: other arguments (as below)
--   returns
--     @param ...: return values
--   @param def: default file handle (must be "_INPUT" or "_OUTPUT")
--   @param [fh]: file handle or name [def]
--   @param ...: other arguments to fun
function withFileOrHandle (fun, def, fh, ...)
  local h = fh or getglobal (def)
  if type (fh) == "string" then
    local mode
    if def == "_INPUT" then
      mode = "r"
    elseif def == "_OUTPUT" then
      mode = "w"
    else
      error ("bad default stream " .. def)
    end
    h = openfile (fh, mode)
    if not h then
      error ("cannot open " .. fh)
    end
  end
  tinsert (arg, 1, h)
  local ret = pack (call (fun, arg))
  if type (fh) == "string" then
    closefile (h)
  end
  return unpack (ret)
end
  
-- @func readLines: Read a file as a list of lines
--   @param [f]: file handle or name [_INPUT]
-- returns
--   @param line: list of lines
readLines = curry (withFileOrHandle,
                   function (h)
                     local line = {}
                     local l
                     repeat
                       l = read (h, "*l")
                       tinsert (line, l)
                     until l == nil
                     line.n = line.n - 1
                     return line
                   end,
                   "_INPUT")

-- @func readFile: Read a file into a string
--   @param [f]: file handle or name [_INPUT]
-- returns
--   @param s: string
readFile = curry (withFileOrHandle,
                  function (h)
                    return read (h, "*a")
                  end,
                  "_INPUT")
                  
-- @func evalFile: Read a file as a value
--   @param [f]: file handle or name [_INPUT]
-- returns
--   v: value
function evalFile (f)
  return eval (readFile (f))
end

-- @func changeSuffix: Change the suffix of a filename
--   @param from: suffix to change [.-]
--   @param to: suffix to replace with
--   @param name: file name to change
-- returns
--   @param name_: file name with new suffix
function changeSuffix (from, to, name)
  local from = from or ".-"
  return gsub (name, "%." .. from .. "$", "") .. "." .. to
end

-- @func addSuffix: Add a suffix to a filename
--   @param suff: suffix to add
--   @param name: file name to change
-- returns
--   @param name_: file name with new suffix
function addSuffix (suff, name)
  return changeSuffix (suff, suff, name)
end
