--[[--
 Additions to the core io module.

 The module table returned by `std.io` also contains all of the entries from
 the core `io` module table.  An hygienic way to import this module, then,
 is simply to override core `io` locally:

    local io = require "std.io"

 @module std.io
]]


local base = require "std.base"

local package = {
  dirsep  = string.match (package.config, "^([^\n]+)\n"),
}

local argerror, export, lambda, leaves, split =
      base.argerror, base.export, base.lambda, base.leaves, base.split


local M = { "std.io" }



--[[ ================= ]]--
--[[ Helper Functions. ]]--
--[[ ================= ]]--


--- Get an input file handle.
-- @tparam[opt=io.input()] file|string h file handle or name
-- @return file handle, or nil on error
local function input_handle (h)
  if h == nil then
    return io.input ()
  elseif type (h) == "string" then
    return io.open (h)
  end
  return h
end



--[[ ================= ]]--
--[[ Module Functions. ]]--
--[[ ================= ]]--


--- Slurp a file handle.
-- @function slurp
-- @tparam[opt=io.input()] file|string file file handle or name;
--   if file is a file handle, that file is closed after reading
-- @return contents of file or handle, or nil if error
-- @see process_files
-- @usage contents = slurp (filename)
local slurp = export (M, "slurp (file|string|nil)", function (file)
  local h, err = input_handle (file)
  if h == nil then argerror ("std.io.slurp", 1, err, 2) end

  if h then
    local s = h:read ("*a")
    h:close ()
    return s
  end
end)


--- Read a file or file handle into a list of lines.
-- The lines in the returned list are not `\n` terminated.
-- @function readlines
-- @tparam[opt=io.input()] file|string file file handle or name;
--   if file is a file handle, that file is closed after reading
-- @treturn list lines
-- @usage list = readlines "/etc/passwd"
export (M, "readlines (file|string|nil)", function (file)
  local h, err = input_handle (file)
  if h == nil then argerror ("std.io.readlines", 1, err, 2) end

  local l = {}
  for line in h:lines () do
    l[#l + 1] = line
  end
  h:close ()
  return l
end)


--- Write values adding a newline after each.
-- @function writelines
-- @tparam[opt=io.output()] file h open writable file handle;
--   the file is **not** closed after writing
-- @tparam string|number ... values to write (as for write)
-- @usage writelines (io.stdout, "first line", "next line")
local writelines = export (M,
"writelines (file|string|number?, string|number?*)",
function (h, ...)
  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for v in leaves (ipairs, {...}) do
    h:write (v, "\n")
  end
end)


--- Overwrite core methods and metamethods with `std` enhanced versions.
--
-- Adds @{readlines} and @{writelines} metamethods to core file objects.
-- @function monkey_patch
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the `std.io` module table
-- @usage local io = require "std.io".monkey_patch ()
export (M, "monkey_patch (table?)", function (namespace)
  namespace = namespace or _G

  local file_metatable = getmetatable (namespace.io.stdin)
  file_metatable.readlines  = M.readlines
  file_metatable.writelines = M.writelines

  return M
end)


--- Split a directory path into components.
-- Empty components are retained: the root directory becomes `{"", ""}`.
-- @function splitdir
-- @param path path
-- @return list of path components
-- @see catdir
-- @usage dir_components = splitdir (filepath)
export (M, "splitdir (string)", function (path)
  return split (path, package.dirsep)
end)


--- Concatenate one or more directories and a filename into a path.
-- @function catfile
-- @string ... path components
-- @treturn string path
-- @see catdir
-- @see splitdir
-- @usage filepath = catfile ("relative", "path", "filename")
export (M, "catfile (string*)", function (...)
  return table.concat ({...}, package.dirsep)
end)


--- Concatenate directory names into a path.
-- @function catdir
-- @string ... path components
-- @return path without trailing separator
-- @see catfile
-- @usage dirpath = catdir ("", "absolute", "directory")
export (M, "catdir (string*)", function (...)
  return table.concat ({...}, package.dirsep):gsub("^$", package.dirsep)
end)


--- Perform a shell command and return its output.
-- @function shell
-- @string c command
-- @treturn string output, or nil if error
-- @see os.execute
-- @usage users = shell [[cat /etc/passwd | awk -F: '{print $1;}']]
export (M, "shell (string)", function (c)
  return slurp (io.popen (c))
end)


------
-- Signature of @{process_files} callback function.
-- @function process_files_callback
-- @string[opt] filename filename
-- @int[opt] i argument number of *filename*
-- @see process_files


--- Process files specified on the command-line.
-- Each filename is made the default input source with `io.input`, and
-- then the filename and argument number are passed to the callback
-- function. In list of filenames, `-` means `io.stdin`.  If no
-- filenames were given, behave as if a single `-` was passed.
-- @todo Make the file list an argument to the function.
-- @function process_files
-- @tparam function fn @{process_files_callback} function for each file
--  argument
-- @see process_files_callback
-- @usage #! /usr/bin/env lua
-- -- minimal cat command
-- local io = require "std.io"
-- io.process_files (function () io.write (io.slurp ()) end)
export (M, "process_files (function)", function (fn)
  fn = type (fn) == "string" and lambda (fn) or fn

  -- N.B. "arg" below refers to the global array of command-line args
  if #arg == 0 then
    arg[#arg + 1] = "-"
  end
  for i, v in ipairs (arg) do
    if v == "-" then
      io.input (io.stdin)
    else
      io.input (v)
    end
    fn (v, i)
  end
end)


--- Give warning with the name of program and file (if any).
-- If there is a global `prog` table, prefix the message with
-- `prog.name` or `prog.file`, and `prog.line` if any.  Otherwise
-- if there is a global `opts` table, prefix the message with
-- `opts.program` and `opts.line` if any.  @{std.optparse:parse}
-- returns an `opts` table that provides the required `program`
-- field, as long as you assign it back to `_G.opts`.
-- @function warn
-- @string msg format string
-- @param ... additional arguments to plug format string specifiers
-- @see std.optparse:parse
-- @see die
-- @usage
--   local OptionParser = require "std.optparse"
--   local parser = OptionParser "eg 0\nUsage: eg\n"
--   _G.arg, _G.opts = parser:parse (_G.arg)
--   if not _G.opts.keep_going then
--     require "std.io".warn "oh noes!"
--   end
local warn = export (M, "warn (string, any?*)", function (msg, ...)
  local prefix = ""
  if (prog or {}).name then
    prefix = prog.name .. ":"
    if prog.line then
      prefix = prefix .. tostring (prog.line) .. ":"
    end
  elseif (prog or {}).file then
    prefix = prog.file .. ":"
    if prog.line then
      prefix = prefix .. tostring (prog.line) .. ":"
    end
  elseif (opts or {}).program then
    prefix = opts.program .. ":"
    if opts.line then
      prefix = prefix .. tostring (opts.line) .. ":"
    end
  end
  if #prefix > 0 then prefix = prefix .. " " end
  writelines (io.stderr, prefix .. string.format (msg, ...))
end)


--- Die with error.
-- This function uses the same rules to build a message prefix
-- as @{warn}.
-- @function die
-- @string msg format string
-- @param ... additional arguments to plug format string specifiers
-- @see warn
-- @usage die ("oh noes! (%s)", tostring (obj))
export (M, "die (string, any?*)", function (...)
  warn (...)
  error ()
end)


for k, v in pairs (io) do
  M[k] = M[k] or v
end

return M
