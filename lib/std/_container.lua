--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Give std.prototype objects the 41.x module shape.

 In 41.x, `require 'std.set'` and friends return the prototype object
 itself, holding module functions that are not propagated to its
 clones.  std.prototype returns a module table with the prototype in
 its `prototype` field instead.  `Module` makes a 41.x module from a
 std.prototype prototype.

 Every frame between a client and a `_functions` deprecation warning is
 in this file, so that the warning can blame the first frame outside it.
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


local ModuleFunction = {
   __tostring = function(self)
      return tostring(self.call)
   end,
   __call = function(self, ...)
      return self.call(...)
   end,
}


-- By value, as 41.x did, so that copies of a prototype, such as those
-- from `std.table.clone`, still have their module functions recognised.
local function ismodulefunction(v)
   return type(v) == 'table' and rawget(v, '_type') == 'modulefunction'
end


local function modulefunction(fn)
   if ismodulefunction(fn) then
      return fn
   end
   return setmetatable({_type='modulefunction', call=fn}, ModuleFunction)
end


-- Copy the functions in *fns* into *obj* as module functions, and list
-- their names in the `_modulefunctions` field of its metatable, if any,
-- where __call looks for them.  Deep copies of *obj* copy that list too.
local function addfunctions(obj, fns)
   local mt = getmetatable(obj)
   local names = mt and merge(mt._modulefunctions or {}, {})
   for k, v in next, fns do
      obj[k] = modulefunction(v)
      if names then
         names[k] = true
      end
   end
   if mt then
      mt._modulefunctions = names
   end
   return obj
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


-- Warn about `_functions` only the first time it is used.
local functions_warned = false


-- Unless *fns* is nil, warn about it, blaming the code that called
-- std.container, and copy its functions into *obj* as module functions.
local function modulefunctions(obj, fns)
   if not fns then
      return obj
   end
   if not functions_warned and _debug.deprecate == nil then
      functions_warned = true
      stderr:write(DEPRECATIONMSG('42', "'_functions'", FUNCTIONS_MSG, blame()))
   end
   return addfunctions(obj, fns)
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
   local t
   for k in next, getmetatable(self)._modulefunctions or {} do
      if ismodulefunction(rawget(self, k)) then
         t = t or merge(self, {})
         t[k] = nil
      end
   end
   if t then
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


-- Return a copy of *proto*, with a copy of its metatable, in which the
-- fields of *mtfields*, if any, replace its own.  Callers may adjust
-- the copy and its metatable without affecting *proto*.
local function copy(proto, mtfields)
   return setmetatable(merge(proto, {}),
      merge(getmetatable(proto), mtfields or {}))
end


-- Add 41.x Object methods to a copy of *obj*'s `__index`, keeping its
-- other methods, and return *obj*.  As in 41.x, `clone` is `__call`, so
-- call this after setting `__call`, on a metatable of *obj*'s own, such
-- as one from `copy` or `Module`.
local function addobjectmethods(obj)
   local mt = getmetatable(obj)
   local index = merge({
      mapfields = mapfields,
      prototype = prototype,
      type = prototype,
   }, merge(mt.__index or {}))
   index.clone = mt.__call
   mt.__index = index
   return obj
end


-- Return a copy of the prototype from std.prototype module *m*, as the
-- 41.x module for it: its clones are made by std.prototype, but don't
-- inherit its module functions, which are the other fields of *m*, and
-- *fns*, if any.
local function Module(m, fns)
   local r = copy(m.prototype, {__call = __call})
   local mfns = merge(m, merge(fns or {}))
   mfns.prototype = fns and fns.prototype
   return addfunctions(r, mfns)
end


return {
   Module = Module,
   addfunctions = addfunctions,
   addobjectmethods = addobjectmethods,
   copy = copy,
   mapfields = mapfields,
   prototype = prototype,
}
