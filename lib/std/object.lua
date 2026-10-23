--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Object prototype.

 This is the 41.x `std.object` API: `require 'std.object'` returns the
 Object prototype itself, rather than a module table with the prototype
 in its `prototype` field as `std.prototype.object` does.  An Object is
 a @{std.container} that stores its methods in `__index`:

      local Object = require 'std.object'
      local Point = Object {_type = 'Point', x = 0, y = 0}
      local p = Point {x = 1}
      print(p:prototype(), p.x, p.y)   --> Point   1   0

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object

 @classmod std.object
]]


local addobjectmethods = require 'std._container'.addobjectmethods
local container = require 'std.container'


return addobjectmethods(container {_type = 'Object'})
