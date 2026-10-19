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


local _ = require 'std._base'

local argscheck = _.typecheck and _.typecheck.argscheck

_ = nil


local DEPRECATIONMSG = require 'std._deprecation'.DEPRECATIONMSG
local container = require 'std.prototype.container'

local _ENV = require 'std.normalize' {
   _debug = require 'std._debug',
   getinfo = 'debug.getinfo',
   io_type = 'io.type',
   merge = 'table.merge',
   stderr = 'io.stderr',
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


-- Return the `_functions` field of *src*, and a copy of *src* without
-- it, unless `std._debug.deprecate` is `true`: then, as in std.prototype,
-- `_functions` is just another '_' prefixed field.
local function splitfunctions(src)
   local fns = type(src) == 'table' and rawget(src, '_functions')
   if not fns or _debug.deprecate == true then
      return nil, src
   end
   src = merge(src, {})
   src._functions = nil
   return fns, src
end


local this = getinfo(1, 'S').source


-- Return the stack level, relative to our caller, of the first Lua
-- function outside this file.
local function blame()
   local i = 3
   while true do
      local info = getinfo(i, 'S')
      if info == nil or info.source ~= this and (info.what == 'Lua' or info.what == 'main') then
         return i - 1
      end
      i = i + 1
   end
end


local FUNCTIONS_MSG = "put module functions in the module table, " ..
   "beside a 'prototype' field, as std.prototype does"


-- Unless *fns* is nil, warn about it, blaming the code that called
-- std.container, and copy its functions into *obj* as module functions.
local function modulefunctions(obj, fns)
   if not fns then
      return obj
   end
   if _debug.deprecate == nil then
      stderr:write(DEPRECATIONMSG('42', "'_functions'", FUNCTIONS_MSG, blame()))
   end
   for k, v in next, fns do
      obj[k] = modulefunction(v)
   end
   modular[obj] = true
   return obj
end


local function X(decl, fn)
   return argscheck and argscheck('std.container.' .. decl, fn) or fn
end


local checked_mapfields = X('mapfields(table, table|object, [?table])', container.mapfields)


local function mapfields(obj, src, map)
   local fns
   fns, src = splitfunctions(src)
   return modulefunctions(checked_mapfields(obj, src, map), fns)
end


-- std.prototype's __call copies every field of the prototype, and
-- handles `_functions` like any other '_' prefixed field.  So, as in
-- 41.x, hand it a prototype without module functions, and a constructor
-- table without `_functions`, and then make the module functions here.
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
   if type(getmetatable(self)._init) ~= 'function' then
      local fns, x = splitfunctions((...))
      if fns then
         return modulefunctions(proto_mt.__call(self, x, select(2, ...)), fns)
      end
   end
   return proto_mt.__call(self, ...)
end


local M = setmetatable({
   mapfields = modulefunction(mapfields),
   prototype = modulefunction(prototype),
}, merge(proto_mt, {__call = __call}))
modular[M] = true

return M
