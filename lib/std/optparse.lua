--[[--
 Parse and process command line options.

     local OptionParser = require "std.optparse"
     local parser = OptionParser (spec)
     _G.arg, opts = parser:parse (_G.arg)

 The string `spec` passed to `OptionParser` must be a specially formatted
 help text, of the form:

     any text VERSION
     Additional lines of text to show when the --version
     option is passed.

     Several lines or paragraphs are permitted.

     Usage: PROGNAME

     Banner text.

     Optional long description text to show when the --help
     option is passed.

     Several lines or paragraphs of long description are permitted.

     Options:

       -h, --help               display this help, then exit
           --version            display version information, then exit
       -b                       a short option with no long option
           --long               a long option with no short option
           --another-long       a long option with internal hypen
           --true               a Lua keyword as an option name
       -v, --verbose            a combined short and long option
       -n, --dryrun, --dry-run  several spellings of the same option
       -u, --name=USER          require an argument
       -o, --output=[FILE]      accept an optional argument
       --                       end of options

    Footer text.  Several lines or paragraphs are permitted.

    Please report bugs at bug-list@yourhost.com

 Most often, everything else is handled automatically.  After calling
 `parser:parse` as shown above, `_G.arg` will contain unparsed arguments,
 usually filenames or similar, and `opts` will be a table of parsed
 option values. The keys to the table are the long-options with leading
 hyphens stripped, and non-word characters turned to `_`.  For example
 if `--another-long` had been found in `_G.arg` then `opts` would
 have a key named `another_long`.  If there is no long option name, then
 the short option is used, e.g. `opts.b` will be set.  The values saved
 in those keys are controlled by the option handler, usually just `true`
 or the option argument string as appropriate.

 On those occasions where more complex processing is required, handlers
 can be replaced or added using parser:@{on}.

 @classmod std.optparse
]]


local OptionParser -- forward declaration


------
-- Customized parser for your options.
-- @table parser


--[[ ----------------- ]]--
--[[ Helper Functions. ]]--
--[[ ----------------- ]]--


local optional, required


--- Normalise an argument list.
-- Separate short options, remove `=` separators from
-- `--long-option=optarg` etc.
-- @function normalise
-- @tparam table arglist list of arguments to normalise
-- @treturn table normalised argument list
local function normalise (self, arglist)
  -- First pass: Normalise to long option names, without '=' separators.
  local normal = {}
  local i = 0
  while i < #arglist do
    i = i + 1
    local opt = arglist[i]

    -- Split '--long-option=option-argument'.
    if opt:sub (1, 2) == "--" then
      local x = opt:find ("=", 3, true)
      if x then
        table.insert (normal, opt:sub (1, x - 1))
        table.insert (normal, opt:sub (x + 1))
      else
        table.insert (normal, opt)
      end

    elseif opt:sub (1, 1) == "-" and string.len (opt) > 2 then
      local rest
      repeat
        opt, rest = opt:sub (1, 2), opt:sub (3)

        table.insert (normal, opt)

        -- Split '-xyz' into '-x -yz', and reiterate for '-yz'
        if self[opt].handler ~= optional and
           self[opt].handler ~= required then
	  if string.len (rest) > 0 then
            opt = "-" .. rest
	  else
	    opt = nil
	  end

        -- Split '-xshortargument' into '-x shortargument'.
        else
          table.insert (normal, rest)
          opt = nil
        end
      until opt == nil
    else
      table.insert (normal, opt)
    end
  end

  normal[-1], normal[0]  = arglist[-1], arglist[0]
  return normal
end


--- Store `value` with `opt`.
-- @function set
-- @string opt option name
-- @param value option argument value
local function set (self, opt, value)
  local key = self[opt].key

  if type (self.opts[key]) == "table" then
    table.insert (self.opts[key], value)
  elseif self.opts[key] ~= nil then
    self.opts[key] = { self.opts[key], value }
  else
    self.opts[key] = value
  end
end



--[[ ============= ]]--
--[[ Option Types. ]]--
--[[ ============= ]]--


--- Option at `arglist[i]` can take an argument.
-- Argument is accepted only if there is a following entry that does not
-- begin with a '-'.
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt=true] value either a function to process the option
--   argument, or a default value if encountered without an optarg
-- @treturn int index of next element of `arglist` to process
function optional (self, arglist, i, value)
  if i + 1 <= #arglist and arglist[i + 1]:sub (1, 1) ~= "-" then
    return self:required (arglist, i, value)
  end

  if type (value) == "function" then
    value = value (self, opt, nil)
  elseif value == nil then
    value = true
  end

  set (self, arglist[i], value)
  return i + 1
end


--- Option at `arglist[i}` requires an argument.
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt] value either a function to process the option argument,
--   or a forced value to replace the user's option argument.
-- @treturn int index of next element of `arglist` to process
function required (self, arglist, i, value)
  local opt = arglist[i]
  if i + 1 > #arglist then
    self:opterr ("option '" .. opt .. "' requires an argument")
    return i + 1
  end

  if type (value) == "function" then
    value = value (self, opt, arglist[i + 1])
  elseif value == nil then
    value = arglist[i + 1]
  end

  set (self, opt, value)
  return i + 2
end


--- Finish option processing
-- Usually indicated by `--` at `arglist[i]`.
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @treturn int index of next element of `arglist` to process
local function finished (self, arglist, i)
  for opt = i + 1, #arglist do
    table.insert (self.unrecognised, arglist[opt])
  end
  return 1 + #arglist
end


--- Option at `arglist[i]` is a boolean switch.
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt] value either a function to process the option argument,
--   or a value to store when this flag is encountered
-- @treturn int index of next element of `arglist` to process
local function flag (self, arglist, i, value)
  if type (value) == "function" then
    value = value (self, opt, true)
  elseif value == nil then
    value = true
  end

  set (self, arglist[i], value)
  return i + 1
end


--- Option should display help text, then exit.
-- @function help
local function help (self)
  print (self.helptext)
  os.exit (0)
end


--- Option should display version text, then exit.
-- @function version
local function version (self)
  print (self.versiontext)
  os.exit (0)
end



--[[ =============== ]]--
--[[ Argument Types. ]]--
--[[ =============== ]]--


--- Map various option strings to equivalent Lua boolean values.
-- @table boolvals
-- @field false false
-- @field 0 false
-- @field no false
-- @field n false
-- @field true true
-- @field 1 true
-- @field yes true
-- @field y true
local boolvals = {
  ["false"] = false, ["true"]  = true,
  ["0"]     = false, ["1"]     = true,
  no        = false, yes       = true,
  n         = false, y         = true,
}


--- Return a Lua boolean equivalent of various `optarg` strings.
-- Report an option parse error if `optarg` is not recognised.
-- @string opt option name
-- @string[opt="1"] optarg option argument, must be a key in @{boolvals}
-- @treturn bool `true` or `false`
local function boolean (self, opt, optarg)
  if optarg == nil then optarg = "1" end -- default to truthy
  local b = boolvals[tostring (optarg):lower ()]
  if b == nil then
    return self:opterr (optarg .. ": Not a valid argument to " ..opt[1] .. ".")
  end
  return b
end


--- Report an option parse error unless `optarg` names an
-- existing file.
-- @fixme this only checks whether the file has read permissions
-- @string opt option name
-- @string optarg option argument, must be an existing file
-- @treturn `optarg`
local function file (self, opt, optarg)
  local h, errmsg = io.open (optarg, "r")
  if h == nil then
    return self:opterr (optarg .. ": " .. errmsg)
  end
  h:close ()
  return optarg
end



--[[ =============== ]]--
--[[ Option Parsing. ]]--
--[[ =============== ]]--


--- Report an option parse error, then exit with status 2.
-- @string msg error message
local function opterr (self, msg)
  local prog = self.program
  -- Ensure final period.
  if msg:match ("%.$") == nil then msg = msg .. "." end
  io.stderr:write (prog .. ": error: " .. msg .. "\n")
  io.stderr:write (prog .. ": Try '" .. prog .. " --help' for help.\n")
  os.exit (2)
end


------
-- Function signature of an option handler for @{on}.
-- @function on_handler
-- @tparam table arglist list of arguments
-- @int i index of last processed element of `arglist`
-- @param[opt=nil] value additional `value` registered with @{on}
-- @treturn int index of next element of `arglist` to process


--- Add an option handler.
-- @function on
-- @tparam[string|table] opts name of the option, or list of option names
-- @tparam on_handler handler function to call when any of `opts` is
--   encountered
-- @param value additional value passed to @{on_handler}
local function on (self, opts, handler, value)
  if type (opts) == "string" then opts = { opts } end
  handler = handler or flag -- unspecified options behave as flags

  normal = {}
  for _, optspec in ipairs (opts) do
    optspec:gsub ("(%S+)",
                  function (opt)
                    -- 'x' => '-x'
                    if string.len (opt) == 1 then
                      opt = "-" .. opt

                    -- 'option-name' => '--option-name'
                    elseif opt:match ("^[^%-]") ~= nil then
                      opt = "--" .. opt
                    end

                    if opt:match ("^%-[^%-]+") ~= nil then
                      -- '-xyz' => '-x -y -z'
                      for i = 2, string.len (opt) do
                        table.insert (normal, "-" .. opt:sub (i, i))
                      end
                    else
                      table.insert (normal, opt)
                    end
                  end)
  end

  -- strip leading '-', and convert non-alphanums to '_'
  key = normal[#normal]:match ("^%-*(.*)$"):gsub ("%W", "_")

  for _, opt in ipairs (normal) do
    self[opt] = { key = key, handler = handler, value = value }
  end
end


------
-- Parsed options table, with a key for each encountered option, each
-- with value set by that option's @{on_handler}.
-- @table opts


--- Parse `arglist`.
-- @tparam table arglist list of arguments
-- @treturn table a list of unrecognised `arglist` elements
-- @treturn opts parsing results
local function parse (self, arglist)
  self.unrecognised = {}

  arglist = normalise (self, arglist)

  local i = 1
  while i > 0 and i <= #arglist do
    local opt = arglist[i]

    if self[opt] == nil then
      table.insert (self.unrecognised, opt)
      i = i + 1

      -- Following non-'-' prefixed argument is an optarg.
      if i <= #arglist and arglist[i]:match "^[^%-]" then
        table.insert (self.unrecognised, arglist[i])
        i = i + 1
      end

    -- Run option handler functions.
    else
      assert (type (self[opt].handler) == "function")

      i = self[opt].handler (self, arglist, i, self[opt].value)
    end
  end

  return self.unrecognised, self.opts
end


--- @export
local methods = {
  boolean  = boolean,
  file     = file,
  finished = finished,
  flag     = flag,
  help     = help,
  optional = optional,
  required = required,
  version  = version,

  on     = on,
  opterr = opterr,
  parse  = parse,
}



--- Take care not to register duplicate handlers.
-- @param current current handler value
-- @param new new handler value
-- @return `new` if `current` is nil
local function set_handler (current, new)
  assert (current == nil, "only one handler per option")
  return new
end


--- Instantiate a new parser.
-- Read the documented options from `spec` and return a new parser that
-- can be passed to @{parse} for parsing those options from an argument
-- list.
-- @static
-- @string spec option parsing specification
-- @treturn parser a parser for options described by `spec`
function OptionParser (spec)
  local parser = setmetatable ({ opts = {} }, { __index = methods })

  parser.versiontext, parser.version, parser.helptext, parser.program =
    spec:match ("^([^\n]-(%S+)\n.-)%s*([Uu]sage: (%S+).-)%s*$")

  if parser.versiontext == nil then
    error ("OptionParser spec argument must match '<version>\\n" ..
           "...Usage: <program>...'")
  end

  -- Collect helptext lines that begin with two or more spaces followed
  -- by a '-'.
  local specs = {}
  parser.helptext:gsub ("\n  %s*(%-[^\n]+)",
                        function (spec) table.insert (specs, spec) end)

  -- Register option handlers according to the help text.
  for _, spec in ipairs (specs) do
    local options, handler = {}

    -- Loop around each '-' prefixed option on this line.
    while spec:sub (1, 1) == "-" do

      -- Capture end of options processing marker.
      if spec:match "^%-%-,?%s" then
        handler = set_handler (handler, finished)

      -- Capture optional argument in the option string.
      elseif spec:match "^%-[%-%w]+=%[.+%],?%s" then
        handler = set_handler (handler, optional)

      -- Capture required argument in the option string.
      elseif spec:match "^%-[%-%w]+=%S+,?%s" then
        handler = set_handler (handler, required)

      -- Capture any specially handled arguments.
      elseif spec:match "^%-%-help,?%s" then
        handler = set_handler (handler, help)

      elseif spec:match "^%-%-version,?%s" then
        handler = set_handler (handler, version)
      end

      -- Consume argument spec, now that it was processed above.
      spec = spec:gsub ("^(%-[%-%w]+)=%S+%s", "%1 ")

      -- Consume short option.
      local _, c = spec:gsub ("^%-([-%w]),?%s+(.*)$",
                              function (opt, rest)
                                if opt == "-" then opt = "--" end
                                table.insert (options, opt)
                                spec = rest
                              end)

      -- Be careful not to consume more than one option per iteration,
      -- otherwise we might miss a handler test at the next loop.
      if c == 0 then
        -- Consume long option.
        spec:gsub ("^%-%-([%-%w]+),?%s+(.*)$",
                   function (opt, rest)
                     table.insert (options, opt)
                     spec = rest
                   end)
      end
    end

    -- Unless specified otherwise, treat each option as a flag.
    parser:on (options, handler or flag)
  end

  return parser
end


-- Support calling the returned table:
return setmetatable (methods, {
  __call = function (_, ...)
             return OptionParser (...)
           end,
})
