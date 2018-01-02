--[[
 General Lua Libraries for Lua 5.1, 5.2 & 5.3
 Copyright (C) 2002-2018 stdlib authors
]]
--[[--
 Prevent dependency loops with key function implementations.

 A few key functions are used in several stdlib modules; we implement those
 functions in this internal module to prevent dependency loops in the first
 instance, and to minimise coupling between modules where the use of one of
 these functions might otherwise load a whole selection of other supporting
 modules unnecessarily.

 Although the implementations are here for logistical reasons, we re-export
 them from their respective logical modules so that the api is not affected
 as far as client code is concerned. The functions in this file do not make
 use of `argcheck` or similar, because we know that they are only called by
 other stdlib functions which have already performed the necessary checking
 and neither do we want to slow everything down by recheckng those argument
 types here.

 This implies that when re-exporting from another module when argument type
 checking is in force, we must export a wrapper function that can check the
 user's arguments fully at the API boundary.
]]


local _ENV = require 'std.normalize' {
   concat = 'table.concat',
   dirsep = 'package.dirsep',
   find = 'string.find',
   gsub = 'string.gsub',
   insert = 'table.insert',
   min = 'math.min',
   shallow_copy = 'table.merge',
   sort = 'table.sort',
   sub = 'string.sub',
   table_maxn = table.maxn,
   wrap = 'coroutine.wrap',
   yield = 'coroutine.yield',
}



--[[ ============================ ]]--
--[[ Enhanced Core Lua functions. ]]--
--[[ ============================ ]]--


-- These come as early as possible, because we want the rest of the code
-- in this file to use these versions over the core Lua implementation
-- (which have slightly varying semantics between releases).


local maxn = table_maxn or function(t)
   local n = 0
   for k in pairs(t) do
      if type(k) == 'number' and k > n then
         n = k
      end
   end
   return n
end



--[[ ============================ ]]--
--[[ Shared Stdlib API functions. ]]--
--[[ ============================ ]]--


-- No need to recurse because functables are second class citizens in
-- Lua:
-- func = function() print 'called' end
-- func() --> 'called'
-- functable=setmetatable({}, {__call=func})
-- functable() --> 'called'
-- nested=setmetatable({}, {__call=functable})
-- nested()
-- --> stdin:1: attempt to call a table value(global 'd')
-- --> stack traceback:
-- -->	stdin:1: in main chunk
-- -->		[C]: in ?
local function callable(x)
   if type(x) == 'function' then
      return x
   end
   return (getmetatable(x) or {}).__call
end


local function catfile(...)
   return concat({...}, dirsep)
end


local function compare(l, m)
   local lenl, lenm = len(l), len(m)
   for i = 1, min(lenl, lenm) do
      local li, mi = tonumber(l[i]), tonumber(m[i])
      if li == nil or mi == nil then
         li, mi = l[i], m[i]
      end
      if li < mi then
         return -1
      elseif li > mi then
         return 1
      end
   end
   if lenl < lenm then
      return -1
   elseif lenl > lenm then
      return 1
   end
   return 0
end


local function escape_pattern(s)
   return (gsub(s, '[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end


local function invert(t)
   local i = {}
   for k, v in pairs(t) do
      i[v] = k
   end
   return i
end


local function leaves(it, tr)
   local function visit(n)
      if type(n) == 'table' then
         for _, v in it(n) do
            visit(v)
         end
      else
         yield(n)
      end
   end
   return wrap(visit), tr
end


local function split(s, sep)
   local r, patt = {}
   if sep == '' then
      patt = '(.)'
      insert(r, '')
   else
      patt = '(.-)' ..(sep or '%s+')
   end
   local b, slen = 0, len(s)
   while b <= slen do
      local e, n, m = find(s, patt, b + 1)
      insert(r, m or sub(s, b + 1, slen))
      b = n or slen + 1
   end
   return r
end


--[[ ============= ]]--
--[[ Internal API. ]]--
--[[ ============= ]]--


-- For efficient use within stdlib, these functions have no type-checking.
-- In debug mode, type-checking wrappers are re-exported from the public-
-- facing modules as necessary.
--
-- Also, to provide some sanity, we mirror the subtable layout of stdlib
-- public API here too, which means everything looks relatively normal
-- when importing the functions into stdlib implementation modules.
return {
   io = {
      catfile = catfile,
   },

   list = {
      compare = compare,
   },

   object = {
      Module = Module,
      mapfields = mapfields,
   },

   string = {
      escape_pattern = escape_pattern,
      split = split,
   },

   table = {
      invert = invert,
      maxn = maxn,
   },

   tree = {
      leaves = leaves,
   },
}
