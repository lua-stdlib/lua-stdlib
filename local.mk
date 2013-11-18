# Local Make rules.

## ------------ ##
## Environment. ##
## ------------ ##

std_path = $(abs_srcdir)/ext/?.lua
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
	ext/std.lua			\
	$(NOTHING_ELSE)

luastddir = $(luadir)/std

dist_luastd_DATA =			\
	ext/std/base.lua		\
	ext/std/debug.lua		\
	ext/std/debug_init.lua		\
	ext/std/functional.lua		\
	ext/std/getopt.lua		\
	ext/std/io.lua			\
	ext/std/list.lua		\
	ext/std/math.lua		\
	ext/std/modules.lua		\
	ext/std/object.lua		\
	ext/std/package.lua		\
	ext/std/set.lua			\
	ext/std/strbuf.lua		\
	ext/std/strict.lua		\
	ext/std/string.lua		\
	ext/std/table.lua		\
	ext/std/tree.lua		\
	$(NOTHING_ELSE)

# In order to avoid regenerating std.lua at configure time, which
# causes the documentation to be rebuilt and hence requires users to
# have luadoc installed, put std/std.lua in as a Makefile dependency.
# (Strictly speaking, distributing an AC_CONFIG_FILE would be wrong.)
ext/std.lua: ext/std.lua.in
	./config.status --file=$@


## Use a builtin rockspec build with root at $(srcdir)/ext
mkrockspecs_args = --module-dir $(srcdir)/ext


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	doc/config.ld			\
	ext/std.lua.in			\
	$(NOTHING_ELSE)


## -------------- ##
## Documentation. ##
## -------------- ##

dist_doc_DATA +=			\
	$(srcdir)/doc/index.html	\
	$(srcdir)/doc/luadoc.css

dist_files_DATA += $(wildcard $(srcdir)/ext/files/*.html)
dist_modules_DATA += $(wildcard $(srcdir)/ext/modules/*.html)

$(dist_doc_DATA): $(dist_lua_DATA) $(dist_luastd_DATA)
	cd $(srcdir) && $(LDOC) -c doc/config.ld .
