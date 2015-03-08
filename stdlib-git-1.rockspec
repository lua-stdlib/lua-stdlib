package = "stdlib"
version = "git-1"
description = {
  detailed = "stdlib is a library of modules for common programming tasks, including list, table and functional operations, objects, pickling, pretty-printing and command-line option parsing.",
  homepage = "http://lua-stdlib.github.io/lua-stdlib",
  license = "MIT/X11",
  summary = "General Lua Libraries",
}
source = {
  url = "git://github.com/lua-stdlib/lua-stdlib.git",
}
dependencies = {
  "lua >= 5.1, < 5.4",
}
external_dependencies = nil
build = {
  build_command = "LUA='$(LUA)' ./bootstrap && ./configure LUA='$(LUA)' LUA_INCLUDE='-I$(LUA_INCDIR)' --prefix='$(PREFIX)' --libdir='$(LIBDIR)' --datadir='$(LUADIR)' --datarootdir='$(PREFIX)' && make clean all",
  copy_directories = {},
  install_command = "make install luadir='$(LUADIR)' luaexecdir='$(LIBDIR)'",
  type = "command",
}
