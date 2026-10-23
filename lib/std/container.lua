--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Container prototype.

 This is the 41.x `std.container` API, built on the Container from
 `std.prototype.container`.  Unlike that module, which returns a table
 with the prototype in its `prototype` field, `std.container` returns
 the Container prototype itself:

      local Container = require 'std.container'
      local things = Container {'foo', 'bar', baz='quux'}

 A container is a @{std.object} with no methods.  Its functionality is
 instead defined by its *meta*methods.

 For 41.x compatibility, the functions listed in a `_functions` field of
 the constructor table become module functions of the new prototype,
 which are not propagated to instances cloned from it.  That is
 deprecated: put module functions in a module table, beside a
 `prototype` field, as `std.prototype` does.

 Prototype Chain
 ---------------

      table
       `-> Container

 @classmod std.container
]]


local _ = require 'std._container'
local container = require 'std.prototype.container'


return _.Module(container, {
   mapfields = _.mapfields,
   prototype = _.prototype,
})
