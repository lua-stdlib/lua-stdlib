-- Environment

require "std.data.list"


-- shell: Perform a shell command and return its output
--   c: command
-- returns
--   o: output
function shell (c)
  local i = _INPUT
  readfrom ("|" .. c)
  local o = read ("*a")
  closefile (_INPUT)
  _INPUT = i
  return o
end

-- processFiles: Process files specified on the command-line
-- file name "-" means _STDIN
--   f: function to process files with
--     name: the name of the file being read
--     i: the number of the argument
function processFiles (f)
  for i = 1, getn (arg) do
    if arg[i] == "-" then
      readfrom ()
    else
      readfrom (arg[i])
    end
    prog.file = arg[i]
    f (arg[i], i)
  end
end

-- shift: Remove elements from the start of arg
--   [n]: number of elements to remove [1]
function shift (n)
  behead (arg, n)
end

-- readDir: Make a list of a directory's contents
--   d: directory
-- returns
--   l: list of files
function readDir (d)
  local l = split ("\n", chomp (shell ("ls -aU " .. d ..
                                       " 2>/dev/null")))
  tremove (l, 1) -- remove . and ..
  tremove (l, 1)
  return l
end
