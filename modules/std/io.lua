-- I/O

module ("std.io", package.seeall)

require "std.base"


-- @func io.readLines: Read a file into a list of lines and close it
--   @param [h]: file handle or name [io.input ()]
-- @returns
--   @param l: list of lines
function io.readLines (h)
  if h == nil then
    h = io.input ()
  elseif type (h) == "string" then
    h = io.open (h)
  end
  local l = {}
  for line in h:lines () do
    table.insert (l, line)
  end
  h:close ()
  return l
end

-- @func io.writeLine: Write values adding a newline after each
--   @param [h]: file handle [io.output ()]
--   @param ...: values to write (as for write)
function io.writeLine (h, ...)
  if io.type (h) ~= "file" then
    table.insert (arg, 1, h)
    h = io.output ()
  end
  for _, v in ipairs (arg) do
    h:write (v, "\n")
  end
end

-- @func io.changeSuffix: Change the suffix of a filename
--   @param from: suffix to change (".-" for any suffix)
--   @param to: suffix to replace with
--   @param name: file name to change
-- @returns
--   @param name_: file name with new suffix
function io.changeSuffix (from, to, name)
  return string.gsub (name, "%." .. from .. "$", "") .. "." .. to
end

-- @func io.addSuffix: Add a suffix to a filename if not already present
--   @param suff: suffix to add
--   @param name: file name to change
-- @returns
--   @param name_: file name with new suffix
function io.addSuffix (suff, name)
  return io.changeSuffix (suff, suff, name)
end

-- @func io.shell: Perform a shell command and return its output
--   @param c: command
-- @returns
--   @param o: output, or nil if error
function io.shell (c)
  local h = io.popen (c)
  local o
  if h then
    o = h:read ("*a")
    h:close ()
  end
  return o
end

-- @func io.processFiles: Process files specified on the command-line
-- If no files given, process io.stdin; in list of files, "-" means
-- io.stdin
--   @param f: function to process files with
--     @param name: the name of the file being read
--     @param i: the number of the argument
function io.processFiles (f)
  if table.getn (arg) == 0 then
    table.insert (arg, "-")
  end
  for i, v in ipairs (arg) do
    if v == "-" then
      io.input (io.stdin)
    else
      io.input (v)
    end
    prog.file = v
    f (v, i)
  end
end
