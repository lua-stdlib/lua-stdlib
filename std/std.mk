# lua-stdlib make rules.


## ------ ##
## Build. ##
## ------ ##

## Use, e.g. `require "std.list"` for individual modules.
nobase_dist_lua_DATA =			\
	std/base.lua			\
	std/debug_ext.lua		\
	std/debug_init.lua		\
	std/getopt.lua			\
	std/io_ext.lua			\
	std/list.lua			\
	std/math_ext.lua		\
	std/modules.lua			\
	std/object.lua			\
	std/package_ext.lua		\
	std/set.lua			\
	std/strbuf.lua			\
	std/strict.lua			\
	std/string_ext.lua		\
	std/table_ext.lua		\
	std/tree.lua			\
	$(NOTHING_ELSE)

## But, `require "std"` for core module.
dist_lua_DATA =				\
	std/std.lua			\
	$(NOTHING_ELSE)

# In order to avoid regenerating std.lua at configure time, which
# causes the documentation to be rebuilt and hence requires users to
# have luadoc installed, put std/std.lua in as a Makefile dependency.
# (Strictly speaking, distributing an AC_CONFIG_FILE would be wrong.)
std/std.lua: std/std.lua.in
	./config.status --file=$@


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	std/std.lua.in			\
	$(NOTHING_ELSE)


## -------------- ##
## Documentation. ##
## -------------- ##

dist_doc_DATA +=			\
	$(srcdir)/std/index.html	\
	$(srcdir)/std/luadoc.css

dist_files_DATA += $(wildcard $(srcdir)/std/files/*.html)
dist_modules_DATA += $(wildcard $(srcdir)/std/modules/*.html)

$(dist_doc_DATA): $(nobase_dist_lua_DATA)
	cd $(srcdir)/std && $(LUADOC) *.lua
