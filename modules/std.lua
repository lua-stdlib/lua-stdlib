-- Lua standard library

-- N.B. Although the libraries use import internally, you should use
-- require to load them.

-- TODO: Add @class and @meth tags; introduce @meth by replacing
--   @func Foo:bar with @meth bar
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; OO vs non-OO (a thorny problem)
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: Sort out how to deal with dependencies on C modules
-- TODO: precompile and make import check for a .luac version of
--   each file, and load it if it's newer than the .lua version.

require "std.import"

-- Modules that require the standard libraries
import "std.base"
import "std.assert"
import "std.debug"
import "std.table"
import "std.list"
import "std.object"
import "std.algorithm"
import "std.string"
import "std.math"
import "std.io"
import "std.set"
import "std.parser"
import "std.mbox"


-- Modules that require non-standard libraries

if type (bit) == "table" then
  import "std.bit"
end

if type (rex) == "table" then
  import "std.rex"
end
