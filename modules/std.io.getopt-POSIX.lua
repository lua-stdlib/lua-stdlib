-- (nearly)-POSIX getopt
-- Translated from Svenne Panne's Haskell GetOpt, as used in GHC

require "std.assert"
require "std.text"
require "std.io.env"


-- TODO: See getopt.lua


-- Usage:
-- options = Options {list of Option {}}
-- processArgs ()

-- Assumes prog = {name, [banner,] [purpose,] [notes,] [usage]}

-- getOpt, usageInfo and dieWithUsage can be called directly (see
-- below, and the example at the end). Set _DEBUG.std to a non-nil
-- value to run the example.

-- Differences between POSIX getopt and this implementation:
--   * Short options may have their argument given in the form -o=a,
--     just like long options
--   * To enforce a coherent description of options and arguments,
--     there are explanation fields in the option/argument descriptor
--   * Error messages are more informative, but not POSIX compliant
--   * Adds a wrapper processArgs to simplify usage and support common
--     options

-- getOpt: perform argument processing
--   argIn: list of command-line args
--   options: options table
--   optsFirst: if true, stop processing at first non-option
--   inOrder: return opts and non-opts in order
-- returns
--   if not inOrder:
--     argOut: table of remaining non-options
--     optOut: table of option key-value list pairs
--     errors: table of error messages
--   otherwise:
--     argOut: table of option key-value pairs and non-options, in
--       parse order
--     nil: (no options)
--     errors: table of error messages
--   errors: list of error strings
function getOpt (argIn, options, optsFirst, inOrder)
  local noProcess
  local argOut, optOut, errors = {[0] = argIn[0]}, {}, {}
  local getArg = -- get an argument for option opt
    function (optTy, opt, arg)
      if optTy.arg == "None" then
        if arg then
          tinsert (%errors, errNoArg (opt))
        end
      else
        if not arg and %argIn[1] and strsub (%argIn[1], 1, 1) ~= "-"
        then
          arg = %argIn[1]
          tremove (%argIn, 1)
        end
        if not arg and optTy.arg == "Req" then
          tinsert (%errors, errReqArg (opt, optTy.var))
          return nil
        end
      end
      if optTy.func then
        return optTy.func (arg)
      end
      return arg or 1 -- make sure some value if no default function
    end
  local addOpt = -- add an option to optOut or argOut
    function (key, val)
      if not %inOrder then
        if %optOut[key] then
          tinsert (%optOut[key], val)
        else
          %optOut[key] = {val}
        end
      else
        tinsert (%argOut, {[key] = val})
      end
    end
  local shortOpt = -- parse a short option
    function (opt, arg)
      if %options.short[opt] then
        local o = %options.short[opt]
        %addOpt (o.long[1], %getArg (o.type, opt, arg))
      else tinsert (%errors, errUnrec (opt))
      end
    end
  local longOpt = -- parse a long option
    function (opt, arg)
      local o = findLongOpt (%options, opt)
      if o.type then
        %addOpt (o.long[1], %getArg (o.type, opt, arg))
      elseif getn (o) > 0 then
        tinsert (%errors, errAmbig (opt, o))
      else tinsert (%errors, errUnrec (opt))
      end
    end
  while argIn[1] do
    local v = argIn[1]
    tremove (argIn, 1)
    local _, _, dash, opt = strfind (v, "^(%-%-?)([^=-][^=]*)")
    local _, _, arg = strfind (v, "=(.*)$")
    if v == "--" then
      noProcess = 1
    elseif not dash or noProcess then -- non-opt
      tinsert (argOut, v)
      if optsFirst then
        noProcess = 1
      end
    elseif dash == "-" and options.short[strsub (opt, 1, 1)] then
      -- short options
      for i = 1, strlen (opt) - 1 do
        shortOpt (strsub (opt, i, i))
      end
      shortOpt (strsub (opt, -1), arg)
    elseif dash then -- long option
      longOpt (opt, arg)
    end
  end
  argOut.n = getn (argOut)
  if inOrder then
    return argOut, nil, errors
  end
  return argOut, optOut, errors
end


-- Options table type

Option = Object {_init = {
    "short", -- list of short names
    "long",  -- list of long names
    "type",  -- OptType
    "desc",  -- description of this option
}}

OptType = Object {_init = {
    "arg", -- type of argument: None, Req (uired), Opt (ional)
    "var", -- descriptive name for the argument
    "func" -- optional function to convert argument into actual
           -- argument (if omitted, argument is left as it is)
}}

-- Options table constructor: adds lookup tables for the long and
-- short options
function Options (t)
  local short, long = {}, {}
  for i = 1, getn (t) do
    for j, s in t[i].short do
      if short[s] then
        warn ("duplicate short option '%s'", s)
      end
      short[s] = t[i]
    end
    for j, l in t[i].long do
      long[l] = t[i]
    end
  end
  t.short = short
  t.long = long
  return t
end

-- findLongOpt: find long options corresponding to a given prefix
--   options: table to search
--   opt: option prefix
-- returns
--   match: match (if only one) or table of matches
function findLongOpt (options, opt)
  local len, match = strlen (opt), {}
  for i, v in options.long do
    if strsub (i, 1, len) == opt then
      tinsert (match, v)
    end
  end
  if getn (match) == 1 then
    return match[1]
  end
  return match
end


-- Error and usage information formatting

-- errAmbig: ambiguous option
--  optStr: option string
--  optTypes: option descriptions
-- returns
--  err: option error
function errAmbig (optStr, optTypes)
  local header = "option `" .. optStr ..
    "' is ambiguous; could be one of:"
  return usageInfo (header, optTypes)
end

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
  return "unrecognized option `" .. optStr .. "'"
end


-- usageInfo: produce usage info for the given options
--   header: header string
--   optDesc: option descriptors
--   pageWidth: width to format to [78]
-- returns
--   mess: formatted string
function usageInfo (header, optDesc, pageWidth)
  pageWidth = pageWidth or 78
  local fmtOpt = -- format the usage info for a single option
    -- returns {opts, desc}: short and long options, description
    function (opt)
      local fmtShort =
        function (c)
          return "-" .. c
        end
      function fmtLong (o)
        local arg = %opt.type.arg
        if arg == "None" then
          return "--" .. o
        end
        if arg == "Req" then
          return "--" .. o .. "=" .. %opt.type.var
        end
        return "--" .. o .. "[=" .. %opt.type.var .. "]"
      end
      return {join (", ",
                    {join (", ", map (fmtShort, opt.short)),
                      join (", ", map (fmtLong, opt.long))}),
        opt.desc}
    end
  local sameLen =
    function (xs)
      local n = call (max, map (strlen, xs))
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
    cols[2] = map (wrapper (pageWidth - width - 4, width + 4),
                   cols[2])
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
                    ((prog.purpose and prog.purpose .. endOfLine) or ""),
                  options) ..
         ((prog.notes and endOfLine ..endOfLine .. prog.notes) or ""))
end


-- processArgs: simple getOpt wrapper
-- adds --version/-v and --help/-h/-? automatically; stops program
-- if there was an error or --help was used
function processArgs ()
  local totArgs = getn (arg)
  options = Options (concat (options or {},
                             {Option ({"v"}, {"version"},
                                      OptType ("None"),
                                       "show program version"),
                               Option ({"h", "?"}, {"help"},
                                       OptType ("None"),
                                       "show this help")}))
  local errors
  arg, opt, errors = getOpt (arg, options)
  if (opt.version or totArgs == 0) and prog.banner then
    write (_STDERR, prog.banner .. endOfLine)
  end
  if getn (errors) > 0 or totArgs == 0 or opt.help then
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

  options = Options {
    Option ({"v"}, {"verbose"}, OptType ("None"),
            "verbosely list files"),
    Option ({"V", "?"}, {"version", "release"}, OptType ("None"),
            "show version info"),
    Option ({"o"}, {"output"}, OptType ("Opt", "FILE", out),
            "use FILE for dump"),
    Option ({"n"}, {"name"}, OptType ("Req", "USER"),
            "only dump USER's files")
  }

  function out (o)
    return o or _STDOUT
  end

  function test (cmdLine, optsFirst, inOrder)
    local opts, nonOpts, errors = getOpt (cmdLine, options, optsFirst,
                                          inOrder)
    if getn (errors) == 0 then
      print ("options=" .. tostring (opts) ..
             "  args=" .. tostring (nonOpts) .. endOfLine)
    else
      print (join (endOfLine, errors) .. endOfLine ..
             usageInfo ("Usage: foobar [OPTION...] FILE...", options))
    end
  end
  
  -- example runs:
  test ({"foo", "-v"}, 1)
  -- options={}  args={1=foo,2=-v,n=2}
  test {"foo", "-v"}
  -- options={verbose={1=1}}  args={1=foo,n=1}
  test ({"foo", "-v"}, nil, 1)
  -- options=nil  args={1=foo,2={verbose=1},n=2}
  test {"foo", "--", "-v"}
  -- options={}  args={1=foo,2=-v,n=2}
  test {"-?o", "--name", "bar", "--na=baz"}
  -- options={output=stdout,version=1,name={1=bar,2=baz,n=2}}  args={}
  test {"--ver", "foo"}
  -- option `--ver' is ambiguous; could be one of:
  --   -v      --verbose             verbosely list files
  --   -V, -?  --version, --release  show version info   
  -- Usage: foobar [OPTION...] files...
  --   -v        --verbose             verbosely list files  
  --   -V, -?    --version, --release  show version info     
  --   -o[FILE]  --output[=FILE]       use FILE for dump     
  --   -n USER   --name=USER           only dump USER's files

end
