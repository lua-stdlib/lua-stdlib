description = {
  license = "MIT/X11",
  summary = "General Lua libraries",
  homepage = "http://github.com/rrthomas/lua-stdlib/",
  detailed = "    stdlib is a library of modules for common programming tasks,\
    including list, table and functional operations, regexps, objects,\
    pickling, pretty-printing and getopt.\
 ",
}
build = {
  type = "command",
  build_command = "LUA=$(LUA) CPPFLAGS=-I$(LUA_INCDIR) ./configure --prefix=$(PREFIX) --libdir=$(LIBDIR) --datadir=$(LUADIR) && make clean && make",
  copy_directories = {
  },
  install_command = "make install",
}
version = "30-1"
dependencies = {
  "lua >= 5.1",
}
package = "stdlib"
source = {
  branch = "release-v30",
  url = "git://github.com/rrthomas/lua-stdlib.git",
}
