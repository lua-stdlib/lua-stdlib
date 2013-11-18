-- -*- lua -*-
project = "stdlib"
description = "Standard Lua Libraries"
dir = "."

new_type("metamethod", "Metamethods", false, "params")
file = {
  "../ext/std/debug.lua",
  "../ext/std/functional.lua",
  "../ext/std/getopt.lua",
  "../ext/std/io.lua",
  "../ext/std/list.lua",
  "../ext/std/math.lua",
  "../ext/std/object.lua",
  "../ext/std/package.lua",
  "../ext/std/set.lua",
  "../ext/std/strbuf.lua",
  "../ext/std/strict.lua",
  "../ext/std/string.lua",
  "../ext/std/table.lua",
  "../ext/std/tree.lua",
  "../ext/std.lua",
}

format = "markdown"
sort = true
