-- Lua Standard library

-- TODO: LuaDocify (use Nick Trout's selfdoc)
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; philosophy of renaming (and hence weak typing,
--   using raw tables wherever possible)
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: precompile and make import check for a .luac version of
--   each file, and load it if it's newer than the .lua version.

require "std.import"

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
import "std.bit"
import "std.rex"
import "std.set"
import "std.parser"
