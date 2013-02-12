version = "git-1"
package = "stdlib"
dependencies = {
  "lua >= 5.1",
}
build = {
  install_command = "make install",
  build_command = "autoreconf -i && LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
  type = "command",
  copy_directories = {
  },
}
source = {
  url = "git://github.com/rrthomas/lua-stdlib.git",
}
description = {
  license = "MIT/X11",
  detailed = "    stdlib is a library of modules for common programming tasks,\
    including list, table and functional operations, regexps, objects,\
    pickling, pretty-printing and getopt.\
 ",
  homepage = "http://github.com/rrthomas/lua-stdlib/",
  summary = "General Lua libraries",
}
