version = "33-1"
source = {
  url = "git://github.com/rrthomas/lua-stdlib.git",
  branch = "release-v33",
}
dependencies = {
  "lua >= 5.1",
}
package = "stdlib"
build = {
  install_command = "make install",
  type = "command",
  copy_directories = {
  },
  build_command = "LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
}
description = {
  license = "MIT/X11",
  summary = "General Lua libraries",
  detailed = "    stdlib is a library of modules for common programming tasks,\
    including list, table and functional operations, regexps, objects,\
    pickling, pretty-printing and getopt.\
 ",
  homepage = "http://github.com/rrthomas/lua-stdlib/",
}
