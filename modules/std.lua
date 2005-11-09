-- Lua standard library

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

-- Modules that require the standard libraries
require "std.base"
require "std.assert"
require "std.debug"
require "std.table"
require "std.list"
require "std.object"
require "std.algorithm"
require "std.string"
require "std.math"
require "std.io"
require "std.set"
require "std.parser"
require "std.mbox"


-- Modules that require non-standard libraries

if type (bit) == "table" then
  require "std.bit"
end

if type (rex) == "table" then
  require "std.rex"
end
