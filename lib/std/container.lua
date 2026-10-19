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
 instead defined by its *meta*methods.  Containers can also supply module
 functions by listing them in `_functions`: they are copied into the new
 prototype as module functions, which are not propagated to instances
 cloned from it.

 Prototype Chain
 ---------------

      table
       `-> Container

 @classmod std.container
]]


local _ = require 'std._base'

local argscheck = _.typecheck and _.typecheck.argscheck

_ = nil


local container = require 'std.prototype.container'

local _ENV = require 'std.normalize' {
   io_type = 'io.type',
   merge = 'table.merge',
   nonempty = next,
}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local proto_mt = getmetatable(container.prototype)


-- Prototypes that hold module functions.
local modular = setmetatable({}, {__mode='k'})


local ModuleFunction = {
   __tostring = function(self)
      return tostring(self.call)
   end,
   __call = function(self, ...)
      return self.call(...)
   end,
}


local function modulefunction(fn)
   if getmetatable(fn) == ModuleFunction then
      return fn
   end
   return setmetatable({_type='modulefunction', call=fn}, ModuleFunction)
end


local function prototype(o)
   return (getmetatable(o) or {})._type or io_type(o) or type(o)
end


-- Move the functions listed in obj's metatable `_functions` field into
-- obj as module functions.
local function functions(obj)
   local mt = getmetatable(obj)
   local fns = mt and mt._functions
   if fns then
      mt._functions = nil
      if not nonempty(mt) then
         setmetatable(obj, nil)
      end
      for k, v in next, fns do
         obj[k] = modulefunction(v)
      end
      modular[obj] = true
   end
   return obj
end


local function mapfields(obj, src, map)
   return functions(container.mapfields(obj, src, map))
end


-- std.prototype's __call copies every field of the prototype, and
-- handles `_functions` like any other '_' prefixed field.  So, as in
-- 41.x, hand it a prototype without module functions, and then make
-- module functions from `_functions` here: a prototype cloned from one
-- with module functions has no `mapfields` module function to do it.
local function __call(self, ...)
   if modular[self] then
      local t = {}
      for k, v in next, self do
         if getmetatable(v) ~= ModuleFunction then
            t[k] = v
         end
      end
      self = setmetatable(t, getmetatable(self))
   end
   local obj = proto_mt.__call(self, ...)
   if type(getmetatable(self)._init) ~= 'function' then
      functions(obj)
   end
   return obj
end


local function X(decl, fn)
   return argscheck and argscheck('std.container.' .. decl, fn) or fn
end


local M = setmetatable({
   mapfields = modulefunction(X('mapfields(table, table|object, [?table])', mapfields)),
   prototype = modulefunction(prototype),
}, merge(proto_mt, {__call = __call}))
modular[M] = true

return M
