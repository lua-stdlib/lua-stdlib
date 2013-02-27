build = {
  build_command = "LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
  copy_directories = {
  },
  install_command = "make install",
  type = "command",
}
dependencies = {
  "lua >= 5.1",
}
version = "33-1"
description = {
  summary = "General Lua libraries",
  license = "MIT/X11",
  detailed = "    stdlib is a library of modules for common programming tasks,\
    including list, table and functional operations, regexps, objects,\
    pickling, pretty-printing and getopt.\
 ",
  homepage = "http://github.com/rrthomas/lua-stdlib/",
}
package = "stdlib"
source = {
  branch = "release-v33",
  url = "git://github.com/rrthomas/lua-stdlib.git",
}
