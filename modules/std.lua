-- @module std
-- Lua standard library

-- TODO: Add @class and @meth tags; introduce @meth by replacing @func
--   Foo:bar with @meth bar
-- TODO: Write a style guide (indenting/wrapping, capitalisation,
--   function and variable names); library functions should call
--   error, not die; OO vs non-OO (a thorny problem)
-- TODO: Add tests for each function immediately after the function;
--   this also helps to check module dependencies
-- TODO: pre-compile

module ("std", package.seeall)

for _, m in ipairs (require "modules") do
  require (m)
end
