--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Parse and process command line options.

 This is the 41.x `std.optparse` API, built on the OptionParser from
 the `optparse` package.  Unlike that module, which returns a table
 with the prototype in its `prototype` field, `std.optparse` returns
 the OptionParser prototype itself, which also has 41.x's `clone`,
 `mapfields`, `prototype` and `type` methods:

      local OptionParser = require 'std.optparse'
      local parser = OptionParser(helptext)
      _G.arg, _G.opts = parser:parse(_G.arg)

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> OptionParser

 @classmod std.optparse
]]


local _ = require 'std._container'
local optparse = require 'optparse'


-- Not `_.Module`, whose `__call` would replace optparse's, which takes
-- help text rather than a table of fields.  The copy keeps `optparse`
-- users from seeing the 41.x methods.
return _.addobjectmethods(_.copy(optparse.prototype))
