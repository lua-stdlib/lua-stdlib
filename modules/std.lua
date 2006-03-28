-- @module std
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

--module ("std", package.seeall)

-- Modules that require the standard libraries
require "base-ext"
require "assert-ext"
require "debug-ext"
require "table-ext"
require "list"
require "object"
require "algorithm"
require "string-ext"
require "math-ext"
require "io-ext"
require "set"
require "parser"
require "mbox"


-- Modules that require non-standard libraries

if type (bit) == "table" then
  require "bit-ext"
end

if type (rex) == "table" then
  require "rex-ext"
end
