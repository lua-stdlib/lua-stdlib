{["specify getopt"] = {
  before = function ()
    getopt = require "getopt"
    Option = getopt.Option
  end,


  {["describe getopt.getOpt ()"] = {
    before = function ()
      prog = {
        name = "getopt_spec.lua",
        options = { Option {{"verbose", "v"}, "verbosely list files"},
                    Option {{"output", "o"}, "dump to FILE", "Opt", "FILE"},
                    Option {{"name", "n"},
		             "only dump USER's files", "Req", "USER"},
                  }
      }

      function test (cmdLine)
        local nonOpts, opts, errors = getopt.getOpt (cmdLine, prog.options)
	if #errors == 0 then
	  return { options = opts, args = nonOpts }
	else
          return errors
        end
      end

      getopt.processArgs (prog)
    end,

    {["it recognizes a user defined option"] = function ()
      expect (test {"foo", "-v"}).should_equal (
          { options = { verbose = {1}}, args = { "foo" } })
    end},
    {["it treats -- as the end of the option list"] = function ()
      expect (test {"foo", "--", "-v"}).should_equal (
          { options = {}, args = { "foo", "-v" } })
    end},
    {["it captures a list of repeated option arguments"] = function ()
      expect (test {"-o", "-V", "-name", "bar", "--name=baz"}).should_equal (
          { options = { name = {"bar", "baz"}, version = {1}, output = {1}},
	    args = {} })
    end},
    {["it diagnoses unrecognized options"] = function ()
      expect (test {"-foo"}).should_contain "unrecognized option `-foo'"
    end},
  }},


  {["describe getopt.usageInfo ()"] = {
    {["context when specifying options"] = {
      before = function ()
	helppatt    = "%-h, %-%-help%s+print this help, then exit"
	versionpatt = "%-V, %-%-version%s+print version information, then exit"
	prog        = { name = "getopt_spec.lua", options = {} }
	options     = { Option {{"help", "?"}, "display this help"},
                        Option {{"version"}, "display version number"} }
        f           = getopt.usageInfo
      end,

      {["it provides a default version option"] = function ()
	getopt.processArgs (prog)
        expect (f ("", prog.options)).should_match (versionpatt)
      end},
      {["it allows the user to override the version option"] = function ()
        prog.options = options
	getopt.processArgs (prog)
	expect (f ("", prog.options)).should_not_match (versionpatt)
	expect (f ("", prog.options)).should_match ("  %-%-version%s+display")
      end},
      {["it provides a default help option"] = function ()
	getopt.processArgs (prog)
        expect (f ("", prog.options)).should_match (helppatt)
      end},
      {["it allows the user to override the help option"] = function ()
        prog.options = options
	getopt.processArgs (prog)
	expect (f ("", prog.options)).should_not_match (helppatt)
	expect (f ("", prog.options)).should_match ("%-%?, %-%-help%s+display")
      end},
    }},
  }},
}}
