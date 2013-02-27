version = "git-1"
source = {
  url = "git://github.com/rrthomas/lua-stdlib.git",
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "command",
  install_command = "make install",
  build_command = "autoreconf -i && LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
  copy_directories = {
  },
}
description = {
  license = "MIT/X11",
  homepage = "http://github.com/rrthomas/lua-stdlib/",
  summary = "General Lua libraries",
  detailed = "    stdlib is a library of modules for common programming tasks,\
    including list, table and functional operations, regexps, objects,\
    pickling, pretty-printing and getopt.\
 ",
}
package = "stdlib"
