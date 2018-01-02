# General Lua Libraries for Lua 5.1, 5.2 & 5.3
# Copyright (C) 2011-2018 stdlib authors

LDOC	= ldoc
LUA	= lua
MKDIR	= mkdir -p
SED	= sed
SPECL	= specl

VERSION = git

luadir	= lib/std
SOURCES =				\
	$(luadir)/_base.lua		\
	$(luadir)/debug.lua		\
	$(luadir)/init.lua		\
	$(luadir)/io.lua		\
	$(luadir)/math.lua		\
	$(luadir)/package.lua		\
	$(luadir)/string.lua		\
	$(luadir)/table.lua		\
	$(luadir)/version.lua		\
	$(NOTHING_ELSE)


all: doc

$(luadir)/version.lua: .FORCE
	@echo 'return "General Lua libraries / $(VERSION)"' > '$@T';		\
	if cmp -s '$@' '$@T'; then						\
	    rm -f '$@T';							\
	else									\
	    echo 'echo return "General Lua libraries / $(VERSION)" > $@';	\
	    mv '$@T' '$@';							\
	fi

doc: build-aux/config.ld $(SOURCES)
	$(LDOC) -c build-aux/config.ld .

build-aux/config.ld: build-aux/config.ld.in
	$(SED) -e "s,@PACKAGE_VERSION@,$(VERSION)," '$<' > '$@'


CHECK_ENV = LUA=$(LUA)

check:
	LUA=$(LUA) $(SPECL) $(SPECL_OPTS) spec/*_spec.yaml

.FORCE:
