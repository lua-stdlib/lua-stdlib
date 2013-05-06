package = "lua-stdlib"
version = "35-1"
description = {
  homepage = "http://rrthomas.github.io/lua-stdlib",
  license = "MIT/X11",
  summary = "General Lua Libraries",
  detailed = "stdlib is a library of modules for common programming tasks, including list, table and functional operations, regexps, objects, pickling, pretty-printing and getopt.",
}
source = {
  url = "http://github.com/rrthomas/lua-stdlib/archive/release-v35.zip",
  dir = "lua-stdlib-release-v35",
}
dependencies = {
  "lua >= 5.1",
}
external_dependencies = nil
build = {
  build_command = "./configure LUA='$(LUA)' LUA_INCLUDE='-I$(LUA_INCDIR)' --prefix='$(PREFIX)' --libdir='$(LIBDIR)' --datadir='$(LUADIR)' && make clean all",
  type = "command",
  copy_directories = {},
  install_command = "make install luadir='$(LUADIR)'",
}
