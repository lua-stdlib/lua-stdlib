# Lua Standard Libraries for Lua 5.1, 5.2, 5.3 & 5.4
# Copyright (C) 2002-2018 stdlib authors

LDOC	= ldoc
LUA	= lua
MKDIR	= mkdir -p
SED	= sed
SPECL	= specl

VERSION	= 41.2.2

luadir	= lib/std
SOURCES =				\
	$(luadir).lua			\
	$(luadir)/base.lua		\
	$(luadir)/container.lua		\
	$(luadir)/debug.lua		\
	$(luadir)/debug_init/init.lua	\
	$(luadir)/functional.lua	\
	$(luadir)/io.lua		\
	$(luadir)/list.lua		\
	$(luadir)/math.lua		\
	$(luadir)/object.lua		\
	$(luadir)/operator.lua		\
	$(luadir)/optparse.lua		\
	$(luadir)/package.lua		\
	$(luadir)/set.lua		\
	$(luadir)/strbuf.lua		\
	$(luadir)/strict.lua		\
	$(luadir)/string.lua		\
	$(luadir)/table.lua		\
	$(luadir)/tree.lua		\
	$(NOTHING_ELSE)

all:

doc: build-aux/config.ld $(SOURCES)
	$(LDOC) -c build-aux/config.ld .

build-aux/config.ld: build-aux/config.ld.in
	$(SED) -e "s,@PACKAGE_VERSION@,$(VERSION)," '$<' > '$@'


CHECK_ENV = LUA=$(LUA)

check: $(SOURCES)
	LUA=$(LUA) $(SPECL) --unicode $(SPECL_OPTS) spec/*_spec.yaml


.FORCE:
