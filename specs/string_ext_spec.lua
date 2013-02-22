{["specify string_ext"] = {
  before = function ()
    unextended = require "string_ext"

    subject = "a string \n\n"
  end,


  {["describe .. operator"] = {
    {["it concatenates string arguments"] = function ()
      target = "a string \n\n another string"
      expect (subject .. " another string").should_be (target)
    end},
    {["it stringifies non-string arguments"] = function ()
      argument = { "a table" }
      expect (subject .. argument).should_be (string.format ("%s%s", subject, tostring (argument)))
    end},
    {["it stringifies nil arguments"] = function ()
      argument = nil
      expect (subject .. argument).should_be (string.format ("%s%s", subject, tostring (argument)))
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = subject .. " concatenate something"
      expect (subject).should_be (original)
    end},
  }},


  {["describe string.caps ()"] = {
    before = function ()
      f = string.caps
    end,

    {["it capitalises words of a string"] = function ()
      target = "A String \n\n"
      expect (f (subject)).should_be (target)
    end},
    {["it changes only the first letter of each word"] = function ()
      expect (f "a stRiNg").should_be "A StRiNg"
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject)
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.chomp ()"] = {
    before = function ()
      f = string.chomp
    end,

    {["it removes a single trailing newline from a string"] = function ()
      target = "a string \n"
      expect (f (subject)).should_be (target)
    end},
    {["it doesn't change a string with no trailing newline"] = function ()
      subject = "a string "
      expect (f (subject)).should_be (subject)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject)
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.escape_pattern ()"] = {
    before = function ()
      f = string.escape_pattern
    end,

    {["it inserts a % before any non-alphanumeric in a string"] = function ()
      subject, target = "", ""
      for c = 32, 126 do
	s = string.char (c)
	subject = subject .. s
	if s:match ("%W") then target = target .. "%" end
	target = target .. s
      end
      expect (f (subject)).should_be (target)
    end},
    {["legacy escapePattern call is the same function"] = function ()
      expect (string.escapePattern).should_be (f)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject)
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.escape_shell ()"] = {
    before = function ()
      f = string.escape_shell
    end,

    {["it inserts a \\ before any shell metacharacters"] = function ()
      subject, target = "", ""
      for c = 32, 126 do
	s = string.char (c)
	subject = subject .. s
	if s:match ("[][ ()\\\"']") then target = target .. "\\" end
	target = target .. s
      end
      expect (f (subject)).should_be (target)
    end},
    {["legacy escapeShell call is the same function"] = function ()
      expect (string.escapeShell).should_be (f)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject)
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.finds ()"] = {
    before = function ()
      subject = "abcd"
      f = string.finds
    end,

    {["it creates a list of pattern captures"] = function ()
      target = { { 1, 2; capt = { "a", "b" } }, { 3, 4; capt = { "c", "d" } } }
      expect ({f (subject, "(.)(.)")}).should_equal ({ target })
    end},
    {["it creates an empty list where no captures are matched "] = function ()
      target = {}
      expect ({f (subject, "(x)")}).should_equal ({ target })
    end},
    {["it creates an empty list for a pattern without captures"] = function ()
      target = { { 1, 1; capt = {} } }
      expect ({f (subject, "a")}).should_equal ({ target })
    end},
    {["it starts the search at a specified index into the subject"] = function ()
      target = { { 8, 9; capt = { "a", "b" } }, { 10, 11; capt = { "c", "d" } } }
      expect ({f ("garbage" .. subject, "(.)(.)", 8)}).should_equal ({ target })
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, "...")
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  -- FIXME: This looks like a misfeature to me, let's remove it!
  {["describe string.format ()"] = {
    before = function ()
      subject = "string: %s, number: %d"
      f = string.format
    end,

    {["it returns a single argument without attempting formatting"] = function ()
      expect (f (subject)).should_be (subject)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject)
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil, "arg")
      expect ("string expected").should_error (f, { "a table" }, "arg")
    end},
  }},


  {["describe string.ltrim ()"] = {
    before = function ()
      subject = " \t\r\n  a  short  string  \t\r\n   "
      f = string.ltrim
    end,

    {["it removes whitespace from the start of a string"] = function ()
      target = "a  short  string  \t\r\n   "
      expect (f (subject)).should_equal (target)
    end},
    {["it supports custom removal patterns"] = function ()
      target = "\r\n  a  short  string  \t\r\n   "
      expect (f (subject, "[ \t\n]+")).should_equal (target)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, "%W")
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.numbertosi ()"] = {
    before = function ()
      f = string.numbertosi
    end,

    {["it returns a number using SI suffixes"] = function ()
      target = {"1e-9", "1y", "1z", "1a", "1f", "1p", "1n", "1mu", "1m", "1",
                "1k", "1M", "1G", "1T", "1P", "1E", "1Z", "1Y", "1e9"}
      subject = {}
      for n = -28, 28, 3 do
	m = 10 * (10 ^ n)
        table.insert (subject, f (m))
      end
      expect (subject).should_equal (target)
    end},
    {["it coerces string arguments to a number"] = function ()
      expect (f "1000").should_be "1k"
    end},
    {["it diagnoses non-numeric arguments"] = function ()
      expect ("attempt to perform arithmetic").should_error (f, nil)
      expect ("number expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.ordinal_suffix ()"] = {
    before = function ()
      f = string.ordinal_suffix
    end,

    {["it returns the English suffix for a number"] = function ()
      subject, target = {}, {}
      for n = -120, 120 do
        suffix = "th"
	m = math.abs (n) % 10
        if m == 1 and math.abs (n) % 100 ~= 11 then suffix = "st"
	elseif m == 2 and math.abs (n) % 100 ~= 12 then suffix = "nd"
        elseif m == 3 and math.abs (n) % 100 ~= 13 then suffix = "rd"
	end
        table.insert (target, n .. suffix)
        table.insert (subject, n .. f (n))
      end
      expect (subject).should_equal (target)
    end},
    {["legacy ordinalSuffix call is the same function"] = function ()
      expect (string.ordinalSuffix).should_be (f)
    end},
    {["it coerces string arguments to a number"] = function ()
      expect (f "-91").should_be "st"
    end},
    {["it diagnoses non-numeric arguments"] = function ()
      expect ("number expected").should_error (f, nil)
      expect ("number expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.pad ()"] = {
    before = function ()
      width = 20
      f = string.pad
    end,

    {["context when string is shorter than given width"] = {
      before = function ()
        subject = "short string"
      end,

      {["it right pads a string with spaces, to the given width"] = function ()
	target = "short string        "
        expect (f (subject, width)).should_be (target)
      end},
      {["it left pads a string with spaces, given a negative width"] = function ()
        width = -width
	target = "        short string"
        expect (f (subject, width)).should_be (target)
      end},
    }},
    {["context when string is longer than given width"] = {
      before = function ()
        subject = "a string that's longer than twenty characters"
      end,

      {["it truncates a string to the given width"] = function ()
	target = "a string that's long"
        expect (f (subject, width)).should_be (target)
      end},
      {["it left pads a string to given width with spaces"] = function ()
        width = -width
        target = "an twenty characters"
        expect (f (subject, width)).should_be (target)
      end},
    }},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, width)
      expect (subject).should_be (original)
    end},
    {["it coerces non-string arguments to a string"] = function ()
      expect (f ({ "a table" }, width)).should_contain "a table"
    end},
    {["it diagnoses non-numeric width arguments"] = function ()
      expect ("number expected").should_error (f, subject, nil)
      expect ("number expected").should_error (f, subject, { "a table" })
    end},
  }},


  {["describe string.rtrim ()"] = {
    before = function ()
      subject = " \t\r\n  a  short  string  \t\r\n   "
      f = string.rtrim
    end,

    {["it removes whitespace from the end of a string"] = function ()
      target = " \t\r\n  a  short  string"
      expect (f (subject)).should_equal (target)
    end},
    {["it supports custom removal patterns"] = function ()
      target = " \t\r\n  a  short  string  \t\r"
      expect (f (subject, "[ \t\n]+")).should_equal (target)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, "%W")
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.split ()"] = {
    before = function ()
      target = { "first", "the second one", "final entry" }
      subject = table.concat (target, ", ")
      f = string.split
    end,

    {["it makes a table of substrings delimitied by a separator"] = function ()
      expect (f (subject,  ", ")).should_equal (target)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, "e")
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, "a string", nil)
      expect ("string expected").should_error (f, nil, ",")
      expect ("string expected").should_error (f, { "a table" }, ",")
    end},
  }},


  {["describe string.tfind ()"] = {
    before = function ()
      subject = "abc"
      f = string.tfind
    end,

    {["it creates a list of pattern captures"] = function ()
      target = { 1, 3, { "a", "b", "c" } }
      expect ({f (subject, "(.)(.)(.)")}).should_equal (target)
    end},
    {["it creates an empty list where no captures are matched "] = function ()
      target = { nil, nil, {} }
      expect ({f (subject, "(x)(y)(z)")}).should_equal (target)
    end},
    {["it creates an empty list for a pattern without captures"] = function ()
      target = { 1, 1, {} }
      expect ({f (subject, "a")}).should_equal (target)
    end},
    {["it starts the search at a specified index into the subject"] = function ()
      target = { 8, 10, { "a", "b", "c" } }
      expect ({f ("garbage" .. subject, "(.)(.)(.)", 8)}).should_equal (target)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, "...")
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.trim ()"] = {
    before = function ()
      subject = " \t\r\n  a  short  string  \t\r\n   "
      f = string.trim
    end,

    {["it removes whitespace from each end of a string"] = function ()
      target = "a  short  string"
      expect (f (subject)).should_equal (target)
    end},
    {["it supports custom removal patterns"] = function ()
      target = "\r\n  a  short  string  \t\r"
      expect (f (subject, "[ \t\n]+")).should_equal (target)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, "%W")
      expect (subject).should_be (original)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["describe string.wrap ()"] = {
    before = function ()
      subject = "This is a collection of Lua libraries for Lua 5.1 " ..
        "and 5.2. The libraries are copyright by their authors 2000" ..
	"-2013 (see the AUTHORS file for details), and released und" ..
	"er the MIT license (the same license as Lua itself). There" ..
	" is no warranty."
      f = string.wrap
    end,

    {["it inserts newlines to wrap a string"] = function ()
      target = "This is a collection of Lua libraries for Lua 5.1 a" ..
        "nd 5.2. The libraries are\ncopyright by their authors 2000" ..
	"-2013 (see the AUTHORS file for details), and\nreleased un" ..
	"der the MIT license (the same license as Lua itself). Ther" ..
	"e is no\nwarranty."
      expect (f (subject)).should_be (target)
    end},
    {["it honours a column width parameter"] = function ()
      target = "This is a collection of Lua libraries for Lua 5.1 a" ..
        "nd 5.2. The libraries\nare copyright by their authors 2000" ..
	"-2013 (see the AUTHORS file for\ndetails), and released un" ..
	"der the MIT license (the same license as Lua\nitself). The" ..
	"re is no warranty."
      expect (f (subject, 72)).should_be (target)
    end},
    {["it supports indenting by a fixed number of columns"] = function ()
      target = "        This is a collection of Lua libraries for L" ..
        "ua 5.1 and 5.2. The\n        libraries are copyright by th" ..
	"eir authors 2000-2013 (see the\n        AUTHORS file for d" ..
	"etails), and released under the MIT license\n        (the " ..
	"same license as Lua itself). There is no warranty."
      expect (f (subject, 72, 8)).should_be (target)
    end},
    {["it can indent the first line differently"] = function ()
      target = "    This is a collection of Lua libraries for Lua 5" ..
        ".1 and 5.2.\n  The libraries are copyright by their author" ..
	"s 2000-2013 (see\n  the AUTHORS file for details), and rel" ..
	"eased under the MIT\n  license (the same license as Lua it" ..
	"self). There is no\n  warranty."
      expect (f (subject, 64, 2, 4)).should_be (target)
    end},
    {["the original subject is not perturbed"] = function ()
      original = subject
      newstring = f (subject, 55, 5)
      expect (subject).should_be (original)
    end},
    {["it diagnoses indent greater than line width"] = function ()
      expect ("less than the line width").should_error (f, subject, 10, 12)
      expect ("less than the line width").should_error (f, subject, 99, 99)
    end},
    {["it diagnoses non-string arguments"] = function ()
      expect ("string expected").should_error (f, nil)
      expect ("string expected").should_error (f, { "a table" })
    end},
  }},


  {["context when requiring the module"] = {
    before = function ()
      extensions = { "caps", "chomp", "escape_pattern", "escape_shell",
                     "finds", "format", "ltrim", "numbertosi",
                     "ordinal_suffix", "pad", "rtrim", "split", "tfind",
                     "trim", "wrap" }
    end,

    {["it returns the unextended module table"] = function ()
      for _, api in ipairs (extensions) do
	if api ~= "format" then
          expect (unextended[api]).should_be (nil)
	end
      end
    end},
    {["it injects an enhanced format function"] = function ()
      expect (unextended.format).should_not_be (table.format)
    end},
    {["it doesn't override any other module access points"] = function ()
      for api in pairs (unextended) do
	if api ~= "format" then
          expect (string[api]).should_be (unextended[api])
	end
      end
    end},
  }},
}}
