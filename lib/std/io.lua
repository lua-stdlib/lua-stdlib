--[[--
 Additions to the core io module.

 The module table returned by `std.io` also contains all of the entries from
 the core io table.  An hygienic way to import this module, then, is simply
 to override the core `io` locally:

    local io = require "std.io"

 @module std.io
]]


local _ARGCHECK = require "std.debug_init"._ARGCHECK

local base = require "std.base"

local package = {
  dirsep  = string.match (package.config, "^([^\n]+)\n"),
}

local argcheck, argerror, leaves, split =
      base.argcheck, base.argerror, base.leaves, base.split


local M -- forward declaration



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



--[[ ============== ]]--
--[[ API Functions. ]]--
--[[ ============== ]]--


--- Slurp a file handle.
-- @tparam[opt=io.input()] file|string file file handle or name
--   if file is a file handle, that file is closed after reading
-- @return contents of file or handle, or nil if error
-- @see std.io.process_files
-- @usage contents = slurp (filename)
local function slurp (file)
  argcheck ("std.io.slurp", 1, {"file", "string", "nil"}, file)

  local h, err = input_handle (file)
  if h == nil then argerror ("std.io.slurp", 1, err, 2) end

  if h then
    local s = h:read ("*a")
    h:close ()
    return s
  end
end


--- Read a file or file handle into a list of lines.
-- @tparam[opt=io.input()] file|string file file handle or name
--   if file is a file handle, that file is closed after reading
-- @return list of lines
-- @usage list = readlines "/etc/passwd"
local function readlines (file)
  argcheck ("std.io.readlines", 1, {"file", "string", "nil"}, file)

  local h, err = input_handle (file)
  if h == nil then argerror ("std.io.readlines", 1, err, 2) end

  local l = {}
  for line in h:lines () do
    l[#l + 1] = line
  end
  h:close ()
  return l
end


--- Write values adding a newline after each.
-- @tparam[opt=io.output()] file h file handle or name
--   the file is **not** closed after writing
-- @param ... values to write (as for write)
-- @usage writelines (io.stdout, "first line", "next line")
local function writelines (h, ...)
  argcheck ("std.io.writelines", 1, {"file", "string", "nil"}, h)

  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for v in leaves (ipairs, {...}) do
    h:write (v, "\n")
  end
end


--- Overwrite core methods and metamethods with `std` enhanced versions.
--
-- Adds `readlines` and `writelines` metamethods to core file objects.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
-- @usage local io = require "std.io".monkey_patch ()
local function monkey_patch (namespace)
  argcheck ("std.io.monkey_patch", 1, "table", namespace)

  namespace = namespace or _G

  assert (type (namespace) == "table",
          "bad argument #1 to 'monkey_patch' (table expected, got " .. type (namespace) .. ")")

  local file_metatable = getmetatable (namespace.io.stdin)
  file_metatable.readlines  = readlines
  file_metatable.writelines = writelines

  return M
end


--- Split a directory path into components.
-- Empty components are retained: the root directory becomes `{"", ""}`.
-- @param path path
-- @return list of path components
-- @see std.io.catdir
-- @usage dir_components = splitdir (filepath)
local function splitdir (path)
  argcheck ("std.io.splitdir", 1, "string", path)

  return split (path, package.dirsep)
end


--- Concatenate one or more directories and a filename into a path.
-- @string ... path components
-- @treturn string path
-- @see std.io.catdir
-- @see std.io.splitdir
-- @usage filepath = catfile ("relative", "path", "filename")
local function catfile (...)
  local t = {...}
  if _ARGCHECK then
    if #t == 0 then
      argcheck ("std.io.catfile", 1, "string", nil)
    end
    for i, v in ipairs (t) do
      argcheck ("std.io.catfile", i, "string", v)
    end
  end

  return table.concat (t, package.dirsep)
end


--- Concatenate directory names into a path.
-- @param ... path components
-- @return path without trailing separator
-- @see std.io.catfile
-- @usage dirpath = catdir ("", "absolute", "directory")
local function catdir (...)
  local t = {...}
  if _ARGCHECK then
    for i, v in ipairs (t) do
      argcheck ("std.io.catdir", i, "string", v)
    end
  end

  return (string.gsub (table.concat (t, package.dirsep), "^$", package.dirsep))
end


--- Perform a shell command and return its output.
-- @string c command
-- @treturn string output, or nil if error
-- @see std.io.slurp
-- @see os.execute
-- @usage users = shell [[cat /etc/passwd | awk -F: '{print $1;}']]
local function shell (c)
  argcheck ("std.io.shell", 1, "string", c)

  return slurp (io.popen (c))
end


------
-- Signature of `process_files` callback function.
-- @function process_files_callback
-- @string[opt] filename filename
-- @int[opt] i argument number of *filename*


--- Process files specified on the command-line.
-- Each filename is made the default input source with `io.input`, and
-- then the filename and argument number are passed to the callback
-- function. In list of filenames, `-` means `io.stdin`.  If no
-- filenames were given, behave as if a single `-` was passed.
-- @todo Make the file list an argument to the function.
-- @tparam process_files_callback fn callback function for each file
--  argument
-- @see std.io.process_files_callback
-- @usage #! /usr/bin/env lua
-- -- minimal cat command
-- local io = require "std.io"
-- io.process_files (function () io.write (io.slurp ()) end)
local function process_files (fn)
  argcheck ("std.io.process_files", 1, "function", fn)

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
end


--- Give warning with the name of program and file (if any).
-- If there is a global `prog` table, prefix the message with
-- `prog.name` or `prog.file`, and `prog.line` if any.  Otherwise
-- if there is a global `opts` table, prefix the message with
-- `opts.program` and `opts.line` if any.  @{std.optparse:parse}
-- returns an `opts` table that provides the required `program`
-- field, as long as you assign it back to `_G.opts`.
-- @string msg format string
-- @param ... additional arguments to plug format string specifiers
-- @see std.optparse:parse
-- @see std.io.die
-- @usage
--   local OptionParser = require "std.optparse"
--   local parser = OptionParser "eg 0\nUsage: eg\n"
--   _G.arg, _G.opts = parser:parse (_G.arg)
--   if not _G.opts.keep_going then
--     require "std.io".warn "oh noes!"
--   end
local function warn (msg, ...)
  argcheck ("std.io.warn", 1, "string", msg)

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
end


--- Die with error.
-- This function uses the same rules to build a message prefix
-- as @{std.io.warn}.
-- @string msg format string
-- @param ... additional arguments to plug format string specifiers
-- @see std.io.warn
-- @usage die ("oh noes! (%s)", tostring (obj))
local function die (msg, ...)
  argcheck ("std.io.die", 1, "string", msg)

  warn (msg, ...)
  error ()
end


--- @export
M = {
  catdir        = catdir,
  catfile       = catfile,
  die           = die,
  monkey_patch  = monkey_patch,
  process_files = process_files,
  readlines     = readlines,
  shell         = shell,
  slurp         = slurp,
  splitdir      = splitdir,
  warn          = warn,
  writelines    = writelines,
}

for k, v in pairs (io) do
  M[k] = M[k] or v
end

return M
