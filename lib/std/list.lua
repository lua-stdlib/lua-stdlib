--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Tables as lists.

 This is the 41.x `std.list` API, without the functions 41.x
 deprecated.  Every function is also a List method, and lists
 compare with `<` and `<=`, join with `..` and append with `+`:

      local List = require 'std.list'
      local l = (List {1, 2} .. {3}) + 4
      print(l:tail():compare {2, 3, 4})   --> 0

 Prototype Chain
 ---------------

      table
       `-> Object
            `-> List

 @classmod std.list
]]


local _ = require 'std._base'

local addfunctions = require 'std._container'.addfunctions
local Object = require 'std.object'
local argscheck = _.typecheck and _.typecheck.argscheck
local compare = _.list.compare
local foldl = require 'std.functional.init'.foldl

_ = nil


local _ENV = require 'std.normalize' {}



--[[ =============== ]]--
--[[ Implementation. ]]--
--[[ =============== ]]--


local List


local function push(l, x)
   l[#l + 1] = x
   return l
end


local function pushall(l, m)
   return foldl(m, l, push)
end


local function append(l, x)
   return push(l {}, x)
end


local function concat(...)
   return foldl({...}, List {}, pushall)
end


local function cons(l, x)
   return concat({x}, l)
end


local function rep(l, n)
   local r = List {}
   for _ = 1, n do
      pushall(r, l)
   end
   return r
end


local function sub(l, from, to)
   local n = len(l)
   from, to = from or 1, to or n
   if from < 0 then
      from = from + n + 1
   end
   if to < 0 then
      to = to + n + 1
   end
   local r = List {}
   for i = from, to do
      r[#r + 1] = l[i]
   end
   return r
end


local function tail(l)
   return sub(l, 2)
end


local function X(decl, fn)
   return argscheck and argscheck('std.list.' .. decl, fn) or fn
end


local M = {
   --- Append an item to a list.
   -- @static
   -- @function append
   -- @tparam List l a list
   -- @param x item
   -- @treturn List new list with *x* appended
   -- @usage
   --    longer = append(short, 'last')
   append = X('append(List, any)', append),

   --- Compare two lists element-by-element, from left-to-right.
   -- @static
   -- @function compare
   -- @tparam List l a list
   -- @tparam List|table m another list, or table
   -- @return -1 if *l* is less than *m*, 0 if they are the same, and 1
   --    if *l* is greater than *m*
   -- @usage
   --    if a_list:compare(another_list) == 0 then print 'same' end
   compare = X('compare(List, List|table)', compare),

   --- Concatenate the elements from any number of lists.
   -- @static
   -- @function concat
   -- @tparam List l a list
   -- @param ... tuple of lists
   -- @treturn List new list with elements from arguments
   -- @usage
   --    --> {1, 2, 3, {4, 5}, 6, 7}
   --    list.concat({1, 2, 3}, {{4, 5}, 6, 7})
   concat = X('concat(List, List|table...)', concat),

   --- Prepend an item to a list.
   -- @static
   -- @function cons
   -- @tparam List l a list
   -- @param x item
   -- @treturn List new list with *x* followed by elements of *l*
   -- @usage
   --    --> {'x', 1, 2, 3}
   --    list.cons({1, 2, 3}, 'x')
   cons = X('cons(List, any)', cons),

   --- Repeat a list.
   -- @static
   -- @function rep
   -- @tparam List l a list
   -- @int n number of times to repeat
   -- @treturn List *n* copies of *l* appended together
   -- @usage
   --    --> {1, 2, 3, 1, 2, 3, 1, 2, 3}
   --    list.rep({1, 2, 3}, 3)
   rep = X('rep(List, int)', rep),

   --- Return a sub-range of a list.
   -- (The equivalent of @{string.sub} on strings; negative list indices
   -- count from the end of the list.)
   -- @static
   -- @function sub
   -- @tparam List l a list
   -- @int[opt=1] from start of range
   -- @int[opt=#l] to end of range
   -- @treturn List new list containing elements between *from* and *to*
   --    inclusive
   -- @usage
   --    --> {3, 4, 5}
   --    list.sub({1, 2, 3, 4, 5, 6}, 3, 5)
   sub = X('sub(List, <?int>, <?int>)', sub),

   --- Return a list with its first element removed.
   -- @static
   -- @function tail
   -- @tparam List l a list
   -- @treturn List new list with all but the first element of *l*
   -- @usage
   --    --> {3, {4, 5}, 6, 7}
   --    list.tail{{1, 2}, 3, {4, 5}, 6, 7}
   tail = X('tail(List)', tail),
}



--[[ ================== ]]--
--[[ Type Declarations. ]]--
--[[ ================== ]]--


--- An Object derived List.
-- @object List

List = Object {
   _type = 'List',

   __index = M,

   --- Concatenate lists.
   -- @function __concat
   -- @tparam List l a list
   -- @tparam List|table m another list, or table (hash part is ignored)
   -- @see concat
   -- @usage
   --    new = alist .. {'append', 'these', 'elements'}
   __concat = concat,

   --- Append element to list.
   -- @function __add
   -- @tparam List l a list
   -- @param e element to append
   -- @see append
   -- @usage
   --    list = list + 'element'
   __add = append,

   --- List order operator.
   -- @function __lt
   -- @tparam List l a list
   -- @tparam List m another list
   -- @see compare
   -- @usage
   --    max = list1 > list2 and list1 or list2
   __lt = function(l, m)
      return compare(l, m) < 0
   end,

   --- List equality or order operator.
   -- @function __le
   -- @tparam List l a list
   -- @tparam List m another list
   -- @see compare
   -- @usage
   --    min = list1 <= list2 and list1 or list2
   __le = function(l, m)
      return compare(l, m) <= 0
   end,
}


return addfunctions(List, M)
