--[[--
 Additions to the io module.
 @module std.io
]]

local base    = require "std.base"
local string  = require "std.string"

local package = {
  dirsep  = string.match (package.config, "^([^\n]+)\n"),
}

local argcheck = base.argcheck

local M -- forward declaration


-- Get an input file handle.
-- @tparam[opt=io.input()] file|string h file handle or name
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
-- @tparam[opt=io.input()] file|string h file handle or name
-- @return contents of file or handle, or nil if error
local function slurp (h)
  argcheck ("std.io.slurp", 1, {"file", "string", "nil"}, h)

  h = input_handle (h)
  if h then
    local s = h:read ("*a")
    h:close ()
    return s
  end
end


--- Read a file or file handle into a list of lines.
-- @tparam[opt=io.input()] file|string h file handle or name
-- if h is a file, that file is closed after reading
-- @return list of lines
local function readlines (h)
  argcheck ("std.io.readlines", 1, {"file", "string", "nil"}, h)

  h = input_handle (h)
  local l = {}
  for line in h:lines () do
    l[#l + 1] = line
  end
  h:close ()
  return l
end


--- Write values adding a newline after each.
-- @tparam[opt=io.output()] file|string h file handle or name
-- @param ... values to write (as for write)
local function writelines (h, ...)
  argcheck ("std.io.writelines", 1, {"file", "string", "nil"}, h)

  if io.type (h) ~= "file" then
    io.write (h, "\n")
    h = io.output ()
  end
  for v in base.leaves (ipairs, {...}) do
    h:write (v, "\n")
  end
end


--- Overwrite core methods and metamethods with `std` enhanced versions.
--
-- Adds `readlines` and `writelines` metamethods to core file objects.
-- @tparam[opt=_G] table namespace where to install global functions
-- @treturn table the module table
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
local function splitdir (path)
  argcheck ("std.io.splitdir", 1, "string", path)

  return string.split (path, package.dirsep)
end


--- Concatenate one or more directories and a filename into a path.
-- @string ... path components
-- @treturn string path
local function catfile (...)
  local t = {...}
  for i, v in ipairs (t) do
    argcheck ("std.io.catfile", i, "string", v)
  end

  return table.concat (t, package.dirsep)
end


--- Concatenate two or more directories into a path, removing the trailing slash.
-- @param ... path components
-- @return path
local function catdir (...)
  t = {...}
  for i, v in ipairs (t) do
    argcheck ("std.io.catdir", i, "string", v)
  end

  return (string.gsub (table.concat (t, package.dirsep), "^$", package.dirsep))
end


--- Perform a shell command and return its output.
-- @param c command
-- @return output, or nil if error
local function shell (c)
  argcheck ("std.io.shell", 1, "string", c)

  return slurp (io.popen (c))
end


--- Process files specified on the command-line.
-- If no files given, process `io.stdin`; in list of files,
-- `-` means `io.stdin`.
-- @todo Make the file list an argument to the function.
-- @tparam function f function to process files with, which is passed
-- `(name, arg_no)`
local function process_files (f)
  argcheck ("std.io.process_files", 1, "function", f)

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
    f (v, i)
  end
end


--- Give warning with the name of program and file (if any).
-- If there is a global `prog` table, prefix the message with
-- `prog.name` or `prog.file`, and `prog.line` if any.  Otherwise
-- if there is a global `opts` table, prefix the message with
-- `opts.program` and `opts.line` if any.  @{std.optparse:parse}
-- returns an `opts` table that provides the required `program`
-- field, as long as you assign it back to `_G.opts`:
--
--     local OptionParser = require "std.optparse"
--     local parser = OptionParser "eg 0\nUsage: eg\n"
--     _G.arg, _G.opts = parser:parse (_G.arg)
--     if not _G.opts.keep_going then
--       require "std.io".warn "oh noes!"
--     end
--
-- @string msg format string
-- @param ... additional arguments to plug format string specifiers
-- @see std.optparse:parse
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
