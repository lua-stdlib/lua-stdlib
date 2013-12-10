-- -*- lua -*-
project = "stdlib"
description = "Standard Lua Libraries"
dir = "."

file = {
  -- Modules
  "../lib/std.lua",
  "../lib/std/debug.lua",
  "../lib/std/functional.lua",
  "../lib/std/getopt.lua",
  "../lib/std/io.lua",
  "../lib/std/math.lua",
  "../lib/std/package.lua",
  "../lib/std/strict.lua",
  "../lib/std/string.lua",
  "../lib/std/table.lua",
  "../lib/std/tree.lua",

  -- Classes
  "../lib/std/container.lua",
  "../lib/std/object.lua",
  "../lib/std/list.lua",
  "../lib/std/set.lua",
  "../lib/std/strbuf.lua",
}

format = "markdown"
sort = true
