--[[
 General Lua Libraries for Lua 5.1, 5.2, 5.3, 5.4 & 5.5
 Copyright (C) 2002-2026 stdlib authors
]]
--[[--
 Tree container prototype.

 This is the 41.x `std.tree` API, built on the Trie from
 `std.prototype.trie`, which is what a 41.x Tree always was.  Unlike
 that module, which returns a table with the prototype in its
 `prototype` field, `std.tree` returns the prototype itself, still
 called Tree, with the module functions of `std.prototype.trie`:

      local Tree = require 'std.tree'
      local tr = Tree {}
      tr[{'branch', 'leaf'}] = 'value'
      for path, value in Tree.leaves(tr) do print(value) end

 Prototype Chain
 ---------------

      table
       `-> Container
            `-> Tree

 @classmod std.tree
]]


local Module = require 'std._container'.Module
local trie = require 'std.prototype.trie'


local Tree = Module(trie)
getmetatable(Tree)._type = 'Tree'

return Tree
