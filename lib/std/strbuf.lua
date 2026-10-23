--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 String buffer prototype.

 This is the 41.x `std.strbuf` API, built on the StrBuf from
 `std.prototype.strbuf`.  Unlike that module, which returns a table
 with the prototype in its `prototype` field, `std.strbuf` returns the
 StrBuf prototype itself, which also has 41.x's `prototype` and `type`
 methods:

      local StrBuf = require 'std.strbuf'
      local buf = StrBuf {'foo'} .. 'bar'
      print(buf:prototype(), tostring(buf))   --> StrBuf   foobar

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Object
                 `-> StrBuf

 @classmod std.strbuf
]]


local _ = require 'std._container'
local strbuf = require 'std.prototype.strbuf'

local merge = require 'std.normalize'.table.merge


local StrBuf = _.Module(strbuf)

local mt = getmetatable(StrBuf)
mt.__index = merge(_.objectmethods, merge(mt.__index))

return StrBuf
