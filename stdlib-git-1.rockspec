package = "stdlib"
version = "git-1"

description = {
  summary = "General Lua Libraries",
  detailed = [[
    stdlib is a library of modules for common programming tasks,
    including list and table operations, and pretty-printing.
  ]],
  homepage = "http://lua-stdlib.github.io/lua-stdlib",
  license = "MIT/X11",
}

source = {
  url = "git://github.com/lua-stdlib/lua-stdlib.git",
}

dependencies = {
  "lua >= 5.1, < 5.4",
}

build = {
  type = "builtin",
  modules = {
    std			= "lib/std/init.lua",
    ["std._base"]	= "lib/std/_base.lua",
    ["std.debug"]	= "lib/std/debug.lua",
    ["std.debug_init"]	= "lib/std/debug_init/init.lua",
    ["std.io"]		= "lib/std/io.lua",
    ["std.math"]	= "lib/std/math.lua",
    ["std.package"]	= "lib/std/package.lua",
    ["std.string"]	= "lib/std/string.lua",
    ["std.table"]	= "lib/std/table.lua",
  },
}
