-- -*- lua -*-
project = "stdlib"
description = "Standard Lua Libraries"
dir = "."

new_type("metamethod", "Metamethods", false, "params")
file = {
  -- Modules
  "../ext/std.lua",
  "../ext/std/debug.lua",
  "../ext/std/functional.lua",
  "../ext/std/getopt.lua",
  "../ext/std/io.lua",
  "../ext/std/math.lua",
  "../ext/std/package.lua",
  "../ext/std/strict.lua",
  "../ext/std/string.lua",
  "../ext/std/table.lua",
  "../ext/std/tree.lua",

  -- Classes
  "../ext/std/object.lua",
  "../ext/std/list.lua",
  "../ext/std/set.lua",
  "../ext/std/strbuf.lua",
}

format = "markdown"
sort = true

