--[[--
 Additions to the core io module.

 The module table returned by `std.io` also contains all of the entries from
 the core `io` module table.  An hygienic way to import this module, then,
 is simply to override core `io` locally:

    local io = require "std.io"

 @module std.io
]]


local base  = require "std.base"
local debug = require "std.debug"

local argerror = debug.argerror
local catfile, dirsep, insert, len, leaves, split =
  base.catfile, base.dirsep, base.insert, base.len, base.leaves, base.split
local ipairs, pairs = base.ipairs, base.pairs
local setmetatable  = debug.setmetatable



local M, monkeys


local function input_handle (h)
  if h == nil then
    return io.input ()
  elseif type (h) == "string" then
    return io.open (h)
  end
  return h
end


local function slurp (file)
  local h, err = input_handle (file)
  if h == nil then argerror ("std.io.slurp", 1, err, 2) end

  if h then
    local s = h:read ("*a")
    h:close ()
    return s
  end
end


local function readlines (file)
  local h, err = input_handle (file)
  if h == nil then argerror ("std.io.readlines", 1, err, 2) end

  local l = {}
  for line in h:lines () do
    l[#l + 1] = line
  end
  h:close ()
  return l
end


local function writelines (h, ...)
  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for v in leaves (ipairs, {...}) do
    h:write (v, "\n")
  end
end


local function monkey_patch (namespace)
  namespace = namespace or _G
  namespace.io = base.copy (namespace.io or {}, monkeys)

  if namespace.io.stdin then
    local mt = getmetatable (namespace.io.stdin) or {}
    mt.readlines  = M.readlines
    mt.writelines = M.writelines
    setmetatable (namespace.io.stdin, mt)
  end

  return M
end


local function process_files (fn)
  -- N.B. "arg" below refers to the global array of command-line args
  if len (arg) == 0 then
    insert (arg, "-")
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


local function warnfmt (msg, ...)
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
  return prefix .. string.format (msg, ...)
end


local function warn (msg, ...)
  writelines (io.stderr, warnfmt (msg, ...))
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X (decl, fn)
  return debug.argscheck ("std.io." .. decl, fn)
end


M = {
  --- Concatenate directory names into a path.
  -- @function catdir
  -- @string ... path components
  -- @return path without trailing separator
  -- @see catfile
  -- @usage dirpath = catdir ("", "absolute", "directory")
  catdir = X ("catdir (string...)", function (...)
	        return (table.concat ({...}, dirsep):gsub("^$", dirsep))
	      end),

  --- Concatenate one or more directories and a filename into a path.
  -- @function catfile
  -- @string ... path components
  -- @treturn string path
  -- @see catdir
  -- @see splitdir
  -- @usage filepath = catfile ("relative", "path", "filename")
  catfile = X ("catfile (string...)", base.catfile),

  --- Die with error.
  -- This function uses the same rules to build a message prefix
  -- as @{warn}.
  -- @function die
  -- @string msg format string
  -- @param ... additional arguments to plug format string specifiers
  -- @see warn
  -- @usage die ("oh noes! (%s)", tostring (obj))
  die = X ("die (string, [any...])", function (...)
	     error (warnfmt (...), 0)
           end),

  --- Remove the last dirsep delimited element from a path.
  -- @function dirname
  -- @string path file path
  -- @treturn string a new path with the last dirsep and following
  --   truncated
  -- @usage dir = dirname "/base/subdir/filename"
  dirname = X ("dirname (string)", function (path)
                 return (path:gsub (catfile ("", "[^", "]*$"), ""))
	       end),

  --- Overwrite core `io` methods with `std` enhanced versions.
  --
  -- Also adds @{readlines} and @{writelines} metamethods to core file objects.
  -- @function monkey_patch
  -- @tparam[opt=_G] table namespace where to install global functions
  -- @treturn table the `std.io` module table
  -- @usage local io = require "std.io".monkey_patch ()
  monkey_patch = X ("monkey_patch (?table)", monkey_patch),

  --- Process files specified on the command-line.
  -- Each filename is made the default input source with `io.input`, and
  -- then the filename and argument number are passed to the callback
  -- function. In list of filenames, `-` means `io.stdin`.  If no
  -- filenames were given, behave as if a single `-` was passed.
  -- @todo Make the file list an argument to the function.
  -- @function process_files
  -- @tparam fileprocessor fn function called for each file argument
  -- @usage
  -- #! /usr/bin/env lua
  -- -- minimal cat command
  -- local io = require "std.io"
  -- io.process_files (function () io.write (io.slurp ()) end)
  process_files = X ("process_files (function)", process_files),

  --- Read a file or file handle into a list of lines.
  -- The lines in the returned list are not `\n` terminated.
  -- @function readlines
  -- @tparam[opt=io.input()] file|string file file handle or name;
  --   if file is a file handle, that file is closed after reading
  -- @treturn list lines
  -- @usage list = readlines "/etc/passwd"
  readlines = X ("readlines (?file|string)", readlines),

  --- Perform a shell command and return its output.
  -- @function shell
  -- @string c command
  -- @treturn string output, or nil if error
  -- @see os.execute
  -- @usage users = shell [[cat /etc/passwd | awk -F: '{print $1;}']]
  shell = X ("shell (string)", function (c) return slurp (io.popen (c)) end),

  --- Slurp a file handle.
  -- @function slurp
  -- @tparam[opt=io.input()] file|string file file handle or name;
  --   if file is a file handle, that file is closed after reading
  -- @return contents of file or handle, or nil if error
  -- @see process_files
  -- @usage contents = slurp (filename)
  slurp = X ("slurp (?file|string)", slurp),

  --- Split a directory path into components.
  -- Empty components are retained: the root directory becomes `{"", ""}`.
  -- @function splitdir
  -- @param path path
  -- @return list of path components
  -- @see catdir
  -- @usage dir_components = splitdir (filepath)
  splitdir = X ("splitdir (string)",
                function (path) return split (path, dirsep) end),

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
  warn = X ("warn (string, [any...])", warn),

  --- Write values adding a newline after each.
  -- @function writelines
  -- @tparam[opt=io.output()] file h open writable file handle;
  --   the file is **not** closed after writing
  -- @tparam string|number ... values to write (as for write)
  -- @usage writelines (io.stdout, "first line", "next line")
  writelines = X ("writelines (?file|string|number, [string|number...])", writelines),
}


monkeys = base.copy ({}, M)  -- before deprecations and core merge


return base.merge (M, io)



--- Types
-- @section Types

--- Signature of @{process_files} callback function.
-- @function fileprocessor
-- @string filename filename
-- @int i argument number of *filename*
-- @usage
-- local fileprocessor = function (filename, i)
--   io.write (tostring (i) .. ":\n===\n" .. io.slurp (filename) .. "\n")
-- end
-- io.process_files (fileprocessor)
