-- @module std
-- Lua standard library

-- TODO: Add @module, @class and @meth tags; introduce @meth by
--   replacing @func Foo:bar with @meth bar
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; OO vs non-OO (a thorny problem)
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: precompile and make import check for a .lc version of
--   each file, and load it if it's newer than the .lua version.

module ("std", package.seeall)

require "std.base"
require "std.debug"
require "std.table"
require "std.list"
require "std.object"
require "std.lcs"
require "std.string"
require "std.xml"
require "std.rex"
require "std.math"
require "std.io"
require "std.getopt"
require "std.set"
require "std.parser"
require "std.mbox"

-- Lift std libraries into the global environment
for i, v in pairs (std) do
  if _G[i] == nil then
    _G[i] = v
  end
end
