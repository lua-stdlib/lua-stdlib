description = {
  license = "MIT/X11",
  homepage = "http://github.com/rrthomas/lua-stdlib/",
  detailed = "    stdlib is a library of modules for common programming tasks,\
    including list, table and functional operations, regexps, objects,\
    pickling, pretty-printing and getopt.\
 ",
  summary = "General Lua libraries",
}
build = {
  type = "command",
  copy_directories = {
  },
  build_command = "LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
  install_command = "make install",
}
dependencies = {
  "lua >= 5.1",
}
package = "stdlib"
source = {
  branch = "release-v32",
  url = "git://github.com/rrthomas/lua-stdlib.git",
}
version = "32-1"
