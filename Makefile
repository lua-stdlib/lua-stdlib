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
	$(luadir)/debug_init/init.lua	\
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
	    mv '$@T' '$@';							\
	fi

doc: doc/config.ld $(SOURCES)
	$(LDOC) -c doc/config.ld .

doc/config.ld: doc/config.ld.in
	version=`LUA_PATH=$$(pwd)'/lib/?.lua;;' $(LUA) -e 'io.stdout:write(require"std.version")'`; \
	$(SED) -e "s,@PACKAGE_VERSION@,$$version," '$<' > '$@'


CHECK_ENV = LUA=$(LUA)

check:
	LUA=$(LUA) $(SPECL) $(SPECL_OPTS) spec/*_spec.yaml

.FORCE:
