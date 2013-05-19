# Local Make rules.

## ------------ ##
## Environment. ##
## ------------ ##

std_path = $(abs_srcdir)/lib/?.lua
LUA_ENV  = LUA_PATH="$(std_path);$(LUA_PATH)"


## ---------- ##
## Bootstrap. ##
## ---------- ##

old_NEWS_hash = 7ef01dfb840329db3d8db218bfe9d075


## ------------- ##
## Declarations. ##
## ------------- ##

filesdir		= $(docdir)/files
modulesdir		= $(docdir)/modules

dist_doc_DATA		=
dist_files_DATA		=
dist_modules_DATA	=

include specs/specs.mk


## ------ ##
## Build. ##
## ------ ##

dist_lua_DATA +=			\
	lib/std.lua			\
	$(NOTHING_ELSE)

luastddir = $(luadir)/std

dist_luastd_DATA =			\
	lib/std/base.lua		\
	lib/std/debug.lua		\
	lib/std/debug_init.lua		\
	lib/std/functional.lua		\
	lib/std/getopt.lua		\
	lib/std/io.lua			\
	lib/std/list.lua		\
	lib/std/math.lua		\
	lib/std/modules.lua		\
	lib/std/object.lua		\
	lib/std/package.lua		\
	lib/std/set.lua			\
	lib/std/strbuf.lua		\
	lib/std/strict.lua		\
	lib/std/string.lua		\
	lib/std/table.lua		\
	lib/std/tree.lua		\
	$(NOTHING_ELSE)

# In order to avoid regenerating std.lua at configure time, which
# causes the documentation to be rebuilt and hence requires users to
# have luadoc installed, put std/std.lua in as a Makefile dependency.
# (Strictly speaking, distributing an AC_CONFIG_FILE would be wrong.)
lib/std.lua: lib/std.lua.in
	./config.status --file=$@


## Use a builtin rockspec build with root at $(srcdir)/lib
mkrockspecs_args = --module-dir $(srcdir)/lib


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	lib/std.lua.in			\
	$(NOTHING_ELSE)


## -------------- ##
## Documentation. ##
## -------------- ##

dist_doc_DATA +=			\
	$(srcdir)/lib/index.html	\
	$(srcdir)/lib/luadoc.css

dist_files_DATA += $(wildcard $(srcdir)/lib/files/*.html)
dist_modules_DATA += $(wildcard $(srcdir)/lib/modules/*.html)

$(dist_doc_DATA): $(dist_lua_DATA) $(dist_luastd_DATA)
	cd $(srcdir)/lib && $(LUADOC) *.lua std/*.lua
