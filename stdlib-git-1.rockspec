package = "stdlib"
version = "git-1"
description = {
  detailed = "stdlib is a library of modules for common programming tasks, including list, table and functional operations, regexps, objects, pickling, pretty-printing and getopt.",
  homepage = "http://rrthomas.github.io/lua-stdlib",
  license = "MIT/X11",
  summary = "General Lua Libraries",
}
source = {
  url = "git://github.com/rrthomas/lua-stdlib.git",
}
dependencies = {
  "lua >= 5.1",
}
external_dependencies = nil
build = {
  build_command = "./bootstrap && ./configure LUA='$(LUA)' LUA_INCLUDE='-I$(LUA_INCDIR)' --prefix='$(PREFIX)' --libdir='$(LIBDIR)' --datadir='$(LUADIR)' && make clean all",
  copy_directories = {},
  install_command = "make install luadir='$(LUADIR)'",
  type = "command",
}
