-- getopt
-- Simplified getopt, based on Svenne Panne's Haskell GetOpt

require "std/patch40.lua"
require "std/assert.lua"
require "std/text.lua"
require "std/data/object.lua"
require "std/io/env.lua"


-- TODO: Wrap all messages; do all wrapping in processArgs, not
-- usageInfo; use sdoc-like library


-- Usage:

-- options = Options {Option {...} ...}
-- processArgs ()

-- Assumes prog = {name[, banner] [, purpose] [, notes] [, usage]}

-- options take a single dash, but may have a double dash
-- arguments may be given as -opt=arg or -opt arg
-- if an option taking an argument is given multiple times, only the
-- last value is returned; missing arguments are returned as 1

-- getOpt, usageInfo and dieWithUsage can be called directly (see
-- below, and the example at the end). Set _DEBUG.std to a non-nil
-- value to run the example.


-- getOpt: perform argument processing
--   argIn: list of command-line args
--   options: options table
-- returns
--   argOut: table of remaining non-options
--   optOut: table of option key-value list pairs
--   errors: table of error messages
function getOpt (argIn, options)
  local noProcess = nil
  local argOut, optOut, errors = {[0] = argIn[0]}, {}, {}
  -- get an argument for option opt
  local getArg =
    function (o, opt, arg, oldarg)
      if o.type == nil then
        if arg ~= nil then
          tinsert (%errors, errNoArg (opt))
        end
      else
        if arg == nil and %argIn[1] and
          strsub (%argIn[1], 1, 1) ~= "-" then
          arg = %argIn[1]
          tremove (%argIn, 1)
        end
        if arg == nil and o.type == "Req" then
          tinsert (%errors, errReqArg (opt, o.var))
          return nil
        end
      end
      if o.func then
        return o.func (arg, oldarg)
      end
      return arg or 1 -- make sure arg has a value
    end
  -- parse an option
  local parseOpt =
    function (opt, arg)
      local o = %options.name[opt]
      if o ~= nil then
        %optOut[o.name[1]] = %getArg (o, opt, arg, %optOut[o.name[1]])
      else
        tinsert (%errors, errUnrec (opt))
      end
    end
  while argIn[1] do
    local v = argIn[1]
    tremove (argIn, 1)
    local _, _, dash, opt = strfind (v, "^(%-%-?)([^=-][^=]*)")
    local _, _, arg = strfind (v, "=(.*)$")
    if v == "--" then
      noProcess = 1
    elseif dash == nil or noProcess then -- non-option
      tinsert (argOut, v)
    else -- option
      parseOpt (opt, arg)
    end
  end
  argOut.n = getn (argOut)
  return argOut, optOut, errors
end


-- Options table type

Option = Object {_init = {
    "name", -- list of names
    "desc", -- description of this option
    "type", -- type of argument (if any): Req (uired), Opt (ional)
    "var",  -- descriptive name for the argument
    "func"  -- optional function (newarg, oldarg) to convert argument
    -- into actual argument, (if omitted, argument is left as it
    -- is)
}}

-- Options table constructor: adds lookup tables for the option names
function Options (t)
  local name = {}
  for i = 1, getn (t) do
    for j, s in t[i].name do
      if name[s] then
        warn ("duplicate option '" .. s .. "'")
      end
      name[s] = t[i]
    end
  end
  t.name = name
  return t
end


-- Error and usage information formatting

-- errNoArg: argument when there shouldn't be one
--  optStr: option string
-- returns
--  err: option error
function errNoArg (optStr)
  return "option `" .. optStr .. "' doesn't take an argument"
end

-- errReqArg: required argument missing
--  optStr: option string
--  desc: argument description
-- returns
--  err: option error
function errReqArg (optStr, desc)
  return "option `" .. optStr .. "' requires an argument `" .. desc ..
    "'"
end

-- errUnrec: unrecognized option
--  optStr: option string
-- returns
--  err: option error
function errUnrec (optStr)
  return "unrecognized option `-" .. optStr .. "'"
end


-- usageInfo: produce usage info for the given options
--   header: header string
--   optDesc: option descriptors
--   pageWidth: width to format to [78]
-- returns
--   mess: formatted string
function usageInfo (header, optDesc, pageWidth)
  pageWidth = pageWidth or 78
  -- format the usage info for a single option
  -- returns {opts, desc}: options, description
  local fmtOpt =
    function (opt)
      local fmtName =
        function (o)
          return "-" .. o
        end
      local fmtArg =
        function ()
          if %opt.type == nil then
            return ""
          elseif %opt.type == "Req" then
            return "=" .. %opt.var
          else
            return "[=" .. %opt.var .. "]"
          end
        end
      local textName = map (fmtName, opt.name)
      textName[1] = textName[1] .. fmtArg ()
      return {join (", ",
                    {join (", ", textName)}), opt.desc}
    end
  local sameLen =
    function (xs)
      local n = max (map (strlen, xs))
      for i, v in xs do
        xs[i] = strsub (v .. strrep (" ", n), 1, n)
      end
      return xs, n
    end
  local paste =
    function (x, y)
      return "  " .. x .. "  " .. y
    end
  local wrapper =
    function (w, i)
      return function (s)
               return wrap (s, %w, %i, 0)
             end
    end
  local optText = ""
  if getn (optDesc) > 0 then
    local cols = unzip (map (fmtOpt, optDesc))
    local width
    cols[1], width = sameLen (cols[1])
    cols[2] = map (wrapper (pageWidth, width + 4), cols[2])
    optText = endOfLine .. join (endOfLine,
                                 mapWith (paste,
                                          unzip ({sameLen (cols[1]),
                                                   cols[2]})))
  end
  return header .. optText
end

-- dieWithUsage: die emitting a usage message
function dieWithUsage ()
  local name = prog.name
  prog.name = nil
  die (usageInfo ("Usage: " .. name .. " " ..
                  (prog.usage or "[OPTION...] FILE...") .. endOfLine ..
                    ((prog.purpose and prog.purpose .. endOfLine)
                     or ""),
                  options) ..
         ((prog.notes and endofLine .. endOfLine .. prog.notes) or ""))
end


-- processArgs: simple getOpt wrapper
-- adds -version/-v and -help/-h/-? automatically; stops program
-- if there was an error or -help was used
function processArgs ()
  local totArgs = getn (arg)
  options = Options (concat
                     (options or {},
                      {Option {{"version", "v"},
                          "show program version"},
                        Option {{"help", "h", "?"},
                          "show this help"}}
                      ))
  local errors
  arg, opt, errors = getOpt (arg, options)
  if (opt.version or opt.help) and prog.banner then
    write (_STDERR, prog.banner .. endOfLine)
  end
  if getn (errors) > 0 or opt.help then
    local name = prog.name
    prog.name = nil
    if getn (errors) > 0 then
      warn (join (endOfLine, errors) .. endOfLine)
    end
    prog.name = name
    dieWithUsage ()
  end
end


-- A small and hopefully enlightening example:
if type (_DEBUG) == "table" and _DEBUG.std then
  
  function out (o)
    return o or _STDOUT
  end

  options = Options {
    Option {{"verbose", "v"}, "verbosely list files"},
    Option {{"version", "release", "V", "?"}, "show version info"},
    Option {{"output", "o"}, "dump to FILE", "Opt", "FILE", out},
    Option {{"name", "n"}, "only dump USER's files", "Req", "USER"},
  }

  function test (cmdLine)
    local nonOpts, opts, errors = getOpt (cmdLine, options)
    if getn (errors) == 0 then
      print ("options=" .. tostring (opts) ..
             "  args=" .. tostring (nonOpts) .. endOfLine)
    else
      print (join (endOfLine, errors) .. endOfLine ..
             usageInfo ("Usage: foobar [OPTION...] FILE...", options))
    end
  end

  prog = {name = "foobar"} -- in case of errors
  -- example runs:
  test {"foo", "-v"}
  -- options={verbose=1}  args={1=foo,n=1}
  test {"foo", "--", "-v"}
  -- options={}  args={1=foo,2=-v,n=2}
  test {"-o", "-?", "-name", "bar", "--name=baz"}
  -- options={output=userdata(?): 0x????????,version=1,name=baz}  args={}
  test {"-foo"}
  -- unrecognized option `foo'
  -- Usage: foobar [OPTION...] FILE...
  --   -verbose, -v                verbosely list files
  --   -version, -release, -V, -?  show version info
  --   -output[=FILE], -o          dump to FILE
  --   -name=USER, -n              only dump USER's files

end
