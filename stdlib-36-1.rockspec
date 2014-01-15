package = "stdlib"
version = "36-1"
description = {
  detailed = "stdlib is a library of modules for common programming tasks, including list, table and functional operations, regexps, objects, pickling, pretty-printing and getopt.",
  homepage = "http://rrthomas.github.io/lua-stdlib",
  license = "MIT/X11",
  summary = "General Lua Libraries",
}
source = {
  dir = "lua-stdlib-release-v36",
  url = "http://github.com/rrthomas/lua-stdlib/archive/release-v36.zip",
}
dependencies = {
  "lua >= 5.1",
}
external_dependencies = nil
build = {
  modules = {
    std = "lib/std.lua",
    ["std.base"] = "lib/std/base.lua",
    ["std.container"] = "lib/std/container.lua",
    ["std.debug"] = "lib/std/debug.lua",
    ["std.debug_init"] = "lib/std/debug_init.lua",
    ["std.functional"] = "lib/std/functional.lua",
    ["std.getopt"] = "lib/std/getopt.lua",
    ["std.io"] = "lib/std/io.lua",
    ["std.list"] = "lib/std/list.lua",
    ["std.math"] = "lib/std/math.lua",
    ["std.modules"] = "lib/std/modules.lua",
    ["std.object"] = "lib/std/object.lua",
    ["std.package"] = "lib/std/package.lua",
    ["std.set"] = "lib/std/set.lua",
    ["std.strbuf"] = "lib/std/strbuf.lua",
    ["std.strict"] = "lib/std/strict.lua",
    ["std.string"] = "lib/std/string.lua",
    ["std.table"] = "lib/std/table.lua",
    ["std.tree"] = "lib/std/tree.lua",
  },
  type = "builtin",
}
