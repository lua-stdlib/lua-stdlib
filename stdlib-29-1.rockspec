package="stdlib"
version="29-1"
source = {
  url = "git://github.com/rrthomas/lua-stdlib.git",
  branch = "v29",
}
description = {
  summary = "General Lua libraries",
  detailed = [[
      stdlib is a library of modules for common programming tasks,
      including list, table and functional operations, regexps, objects,
      pickling, pretty-printing and getopt.
   ]],
  homepage = "http://github.com/rrthomas/lua-stdlib/",
  license = "MIT/X11"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "command",
  build_command = "LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
  install_command = "make install",
  copy_directories = {}
}
