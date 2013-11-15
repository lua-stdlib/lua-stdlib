--- Additions to the io module

local package = require "std.package"
local string  = require "std.string"
local tree    = require "std.tree"


-- Get an input file handle.
-- @param h file handle or name (default: <code>io.input ()</code>)
-- @return file handle, or nil on error
local function input_handle (h)
  if h == nil then
    h = io.input ()
  elseif type (h) == "string" then
    h = io.open (h)
  end
  return h
end

--- Slurp a file handle.
-- @param h file handle or name (default: <code>io.input ()</code>)
-- @return contents of file or handle, or nil if error
local function slurp (h)
  h = input_handle (h)
  if h then
    local s = h:read ("*a")
    h:close ()
    return s
  end
end

--- Read a file or file handle into a list of lines.
-- @param h file handle or name (default: <code>io.input ()</code>);
-- if h is a handle, the file is closed after reading
-- @return list of lines
local function readlines (h)
  h = input_handle (h)
  local l = {}
  for line in h:lines () do
    table.insert (l, line)
  end
  h:close ()
  return l
end

--- Write values adding a newline after each.
-- @param h file handle (default: <code>io.output ()</code>
-- @param ... values to write (as for write)
local function writelines (h, ...)
  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for v in tree.ileaves ({...}) do
    h:write (v, "\n")
  end
end

--- Split a directory path into components.
-- Empty components are retained: the root directory becomes <code>{"", ""}</code>.
-- @param path path
-- @return list of path components
local function splitdir (path)
  return string.split (path, package.dirsep)
end

--- Concatenate one or more directories and a filename into a path.
-- @param ... path components
-- @return path
local function catfile (...)
  return table.concat ({...}, package.dirsep)
end

--- Concatenate two or more directories into a path, removing the trailing slash.
-- @param ... path components
-- @return path
local function catdir (...)
  return (string.gsub (catfile (...), "^$", package.dirsep))
end

--- Perform a shell command and return its output.
-- @param c command
-- @return output, or nil if error
local function shell (c)
  return slurp (io.popen (c))
end

--- Process files specified on the command-line.
-- If no files given, process <code>io.stdin</code>; in list of files,
-- <code>-</code> means <code>io.stdin</code>.
-- <br>FIXME: Make the file list an argument to the function.
-- @param f function to process files with, which is passed
-- <code>(name, arg_no)</code>
local function process_files (f)
  -- N.B. "arg" below refers to the global array of command-line args
  if #arg == 0 then
    table.insert (arg, "-")
  end
  for i, v in ipairs (arg) do
    if v == "-" then
      io.input (io.stdin)
    else
      io.input (v)
    end
    f (v, i)
  end
end

--- Give warning with the name of program and file (if any).
-- @param ... arguments for format
local function warn (...)
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
  writelines (io.stderr, string.format (...))
end

--- Die with error.
-- @param ... arguments for format
local function die (...)
  warn (...)
  error ()
end


local M = {
  catdir        = catdir,
  catfile       = catfile,
  die           = die,
  process_files = process_files,
  readlines     = readlines,
  shell         = shell,
  slurp         = slurp,
  splitdir      = splitdir,
  warn          = warn,
  writelines    = writelines,

  -- camelCase compatibility.
  processFiles  = process_files,
}

for k, v in pairs (io) do
  M[k] = M[k] or v
end

return M
