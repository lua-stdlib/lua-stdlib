-- Lua Standard library

-- TODO: LuaDocify
-- TODO: LTN7-ify
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; philosophy of renaming (and hence weak typing,
--   using raw tables wherever possible)
-- TODO: Implement hslibs pretty-printing (sdoc) routines (use .. for
--   <> and + for <+>), and use in getopt
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: precompile and make require check for a .luc [sic] version of
--   each file, and load it if it's newer than the .lua version

require "std/patch40.lua"
require "std/data.lua"
require "std/text.lua"
require "std/io.lua"
require "std/debug.lua"
