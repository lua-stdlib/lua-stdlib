-- Lua Standard library

-- TODO: LuaDocify (use Nick Trout's selfdoc)
-- TODO: LTN7-ify
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; philosophy of renaming (and hence weak typing,
--   using raw tables wherever possible)
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: precompile and make require check for a .luc [sic] version of
--   each file, and load it if it's newer than the .lua version

require "std.patch40"
require "std.data"
require "std.logic"
require "std.text"
require "std.io"
require "std.debug"
