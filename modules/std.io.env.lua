-- @module Environment

import "std.list"


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

-- @func readDir: Make a list of a directory's contents
--   @param d: directory
-- @returns
--   @param l: list of files
function io.readDir (d)
  local l = string.split ("\n",
                          string.chomp (shell ("ls -aU " .. d ..
                                               " 2>/dev/null")))
  table.remove (l, 1) -- remove . and ..
  table.remove (l, 1)
  return l
end
