-- -*- lua -*-
title = "stdlib 41.2.2 Reference"
project = "stdlib 41.2.2"
description = [[
# Standard Lua Libraries

This is a collection of Lua libraries for Lua 5.1 (including LuaJIT),
5.2, 5.3 and 5.4.  Stdlib has no prerequisites beyond a standard Lua
system.

## LICENSE

The libraries are copyright by their authors 2000-2018, and released under
the MIT license (the same license as Lua itself). There is no warranty.
]]

dir = "../doc"

file = {
  -- Modules
  "../lib/std.lua",
  "../lib/std/debug.lua",
  "../lib/std/functional.lua",
  "../lib/std/io.lua",
  "../lib/std/math.lua",
  "../lib/std/operator.lua",
  "../lib/std/package.lua",
  "../lib/std/strict.lua",
  "../lib/std/string.lua",
  "../lib/std/table.lua",
  "../lib/std/tree.lua",

  -- Classes
  "../lib/std/container.lua",
  "../lib/std/object.lua",
  "../lib/std/list.lua",
  "../lib/std/optparse.lua",
  "../lib/std/set.lua",
  "../lib/std/strbuf.lua",
}

new_type ("object", "Objects", false, "Fields")

format = "markdown"

sort = true

backtick_references = false
