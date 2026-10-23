--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Functional forms of Lua operators.

 This is the 41.x `std.operator` API, which is `std.functional.operator`
 now:

      local operator = require 'std.operator'
      print(operator.sum(2, 3), operator.concat('foo', 'bar'))

 @module std.operator
]]


return require 'std.functional.operator'
