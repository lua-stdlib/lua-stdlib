--[[
 General Lua Libraries for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2002-2018 stdlib authors
]]
--[[--
 Additions to the core io module.

 The module table returned by `std.io` also contains all of the entries from
 the core `io` module table.   An hygienic way to import this module, then,
 is simply to override core `io` locally:

      local io = require 'std.io'

 @corelibrary std.io
]]


local _ = require 'std._base'

local argscheck = _.typecheck and _.typecheck.argscheck
local catfile = _.io.catfile
local leaves = _.tree.leaves
local split = _.string.split

_ = nil


local _ENV = require 'std.normalize' {
   'io',
   _G = _G,  -- FIXME: don't use the host _G as an API!
   concat = 'table.concat',
   dirsep = 'package.dirsep',
   format = 'string.format',
   gsub = 'string.gsub',
   input = 'io.input',
   insert = 'table.insert',
   io_type = 'io.type',
   merge = 'table.merge',
   open = 'io.open',
   output = 'io.output',
   popen = 'io.popen',
   stderr = 'io.stderr',
   stdin = 'io.stdin',
   write = 'io.write',
}


--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local M


local function input_handle(h)
   if h == nil then
      return input()
   elseif type(h) == 'string' then
      return open(h)
   end
   return h
end


local function slurp(file)
   local h, err = input_handle(file)
   if h == nil then
      argerror('std.io.slurp', 1, err, 2)
   end

   if h then
      local s = h:read('*a')
      h:close()
      return s
   end
end


local function readlines(file)
   local h, err = input_handle(file)
   if h == nil then
      argerror('std.io.readlines', 1, err, 2)
   end

   local l = {}
   for line in h:lines() do
      l[#l + 1] = line
   end
   h:close()
   return l
end


local function writelines(h, ...)
   if io_type(h) ~= 'file' then
      write(h, '\n')
      h = output()
   end
   for v in leaves(ipairs, {...}) do
      h:write(v, '\n')
   end
end


local function process_files(fn)
   -- N.B. 'arg' below refers to the global array of command-line args
   if len(arg) == 0 then
      insert(arg, '-')
   end
   for i, v in ipairs(arg) do
      if v == '-' then
         input(stdin)
      else
         input(v)
      end
      fn(v, i)
   end
end


local function warnfmt(msg, ...)
   local prefix = ''
   local prog = rawget(_G, 'prog') or {}
   local opts = rawget(_G, 'opts') or {}
   if prog.name then
      prefix = prog.name .. ':'
      if prog.line then
         prefix = prefix .. str(prog.line) .. ':'
      end
   elseif prog.file then
      prefix = prog.file .. ':'
      if prog.line then
         prefix = prefix .. str(prog.line) .. ':'
      end
   elseif opts.program then
      prefix = opts.program .. ':'
      if opts.line then
         prefix = prefix .. str(opts.line) .. ':'
      end
   end
   if #prefix > 0 then
      prefix = prefix .. ' '
   end
   return prefix .. format(msg, ...)
end


local function warn(msg, ...)
   writelines(stderr, warnfmt(msg, ...))
end



--[[ ================= ]]--
--[[ Public Interface. ]]--
--[[ ================= ]]--


local function X(decl, fn)
   return argscheck and argscheck('std.io.' .. decl, fn) or fn
end


M = {
   --- Diagnostic functions
   -- @section diagnosticfuncs

   --- Die with error.
   -- This function uses the same rules to build a message prefix
   -- as @{warn}.
   -- @function die
   -- @string msg format string
   -- @param ... additional arguments to plug format string specifiers
   -- @see warn
   -- @usage
   --    die('oh noes!(%s)', tostring(obj))
   die = X('die(string, [any...])', function(...)
      error(warnfmt(...), 0)
   end),

   --- Give warning with the name of program and file(if any).
   -- If there is a global `prog` table, prefix the message with
   -- `prog.name` or `prog.file`, and `prog.line` if any.   Otherwise
   -- if there is a global `opts` table, prefix the message with
   -- `opts.program` and `opts.line` if any.
   -- @function warn
   -- @string msg format string
   -- @param ... additional arguments to plug format string specifiers
   -- @see die
   -- @usage
   --    local OptionParser = require 'std.optparse'
   --    local parser = OptionParser 'eg 0\nUsage: eg\n'
   --    _G.arg, _G.opts = parser:parse(_G.arg)
   --    if not _G.opts.keep_going then
   --       require 'std.io'.warn 'oh noes!'
   --    end
   warn = X('warn(string, [any...])', warn),


   --- Path Functions
   -- @section pathfuncs

   --- Concatenate directory names into a path.
   -- @function catdir
   -- @string ... path components
   -- @return path without trailing separator
   -- @see catfile
   -- @usage
   --    dirpath = catdir('', 'absolute', 'directory')
   catdir = X('catdir(string...)', function(...)
      return(gsub(concat({...}, dirsep), '^$', dirsep))
   end),

   --- Concatenate one or more directories and a filename into a path.
   -- @function catfile
   -- @string ... path components
   -- @treturn string path
   -- @see catdir
   -- @see splitdir
   -- @usage
   --    filepath = catfile('relative', 'path', 'filename')
   catfile = X('catfile(string...)', catfile),

   --- Remove the last dirsep delimited element from a path.
   -- @function dirname
   -- @string path file path
   -- @treturn string a new path with the last dirsep and following
   --    truncated
   -- @usage
   --    dir = dirname '/base/subdir/filename'
   dirname = X('dirname(string)', function(path)
      return(gsub(path, catfile('', '[^', ']*$'), ''))
   end),

   --- Split a directory path into components.
   -- Empty components are retained: the root directory becomes `{'', ''}`.
   -- @function splitdir
   -- @param path path
   -- @return list of path components
   -- @see catdir
   -- @usage
   --    dir_components = splitdir(filepath)
   splitdir = X('splitdir(string)', function(path)
      return split(path, dirsep)
   end),


   --- IO Functions
   -- @section iofuncs

   --- Process files specified on the command-line.
   -- Each filename is made the default input source with `io.input`, and
   -- then the filename and argument number are passed to the callback
   -- function. In list of filenames, `-` means `io.stdin`.   If no
   -- filenames were given, behave as if a single `-` was passed.
   -- @todo Make the file list an argument to the function.
   -- @function process_files
   -- @tparam fileprocessor fn function called for each file argument
   -- @usage
   --    #! /usr/bin/env lua
   --    -- minimal cat command
   --    local io = require 'std.io'
   --    io.process_files(function() io.write(io.slurp()) end)
   process_files = X('process_files(function)', process_files),

   --- Read a file or file handle into a list of lines.
   -- The lines in the returned list are not `\n` terminated.
   -- @function readlines
   -- @tparam[opt=io.input()] file|string file file handle or name;
   --    if file is a file handle, that file is closed after reading
   -- @treturn list lines
   -- @usage
   --    list = readlines '/etc/passwd'
   readlines = X('readlines(?file|string)', readlines),

   --- Perform a shell command and return its output.
   -- @function shell
   -- @string c command
   -- @treturn string output, or nil if error
   -- @see os.execute
   -- @usage
   --    users = shell [[cat /etc/passwd | awk -F: '{print $1;}']]
   shell = X('shell(string)', function(c) return slurp(popen(c)) end),

   --- Slurp a file handle.
   -- @function slurp
   -- @tparam[opt=io.input()] file|string file file handle or name;
   --    if file is a file handle, that file is closed after reading
   -- @return contents of file or handle, or nil if error
   -- @see process_files
   -- @usage
   --    contents = slurp(filename)
   slurp = X('slurp(?file|string)', slurp),

   --- Write values adding a newline after each.
   -- @function writelines
   -- @tparam[opt=io.output()] file h open writable file handle;
   --    the file is **not** closed after writing
   -- @tparam string|number ... values to write(as for write)
   -- @usage
   --    writelines(io.stdout, 'first line', 'next line')
   writelines = X('writelines(?file|string|number, [string|number...])', writelines),
}


return merge(io, M)



--- Types
-- @section Types

--- Signature of @{process_files} callback function.
-- @function fileprocessor
-- @string filename filename
-- @int i argument number of *filename*
-- @usage
--    local fileprocessor = function(filename, i)
--       io.write(tostring(i) .. ':\n===\n' .. io.slurp(filename) .. '\n')
--    end
--    io.process_files(fileprocessor)
