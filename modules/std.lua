-- Lua Standard library

-- TODO: LuaDocify (use Nick Trout's selfdoc)
-- TODO: Lua 5-ify data, io, debug, assert (debug)
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; philosophy of renaming (and hence weak typing,
--   using raw tables wherever possible)
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: precompile and make require check for a .luac version of
--   each file, and load it if it's newer than the .lua version

require "std.base"
require "std.data"
require "std.string"
require "std.rex"
require "std.io"
require "std.debug"
