--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Set container prototype.

 This is the 41.x `std.set` API, built on the Set from
 `std.prototype.set`.  Unlike that module, which returns a table with
 the prototype in its `prototype` field, `std.set` returns the Set
 prototype itself, with the module functions of `std.prototype.set`:

      local Set = require 'std.set'
      local s = Set {'foo', 'bar', 'bar'}
      print(Set.member(s, 'foo'), s + Set {'baz'})

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Set

 @classmod std.set
]]


local Module = require 'std._container'.Module
local set = require 'std.prototype.set'


return Module(set)
