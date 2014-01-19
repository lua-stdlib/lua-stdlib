# Local Make rules.
#
# Copyright (C) 2013-2014 Gary V. Vaughan
# Written by Gary V. Vaughan, 2013
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


## ------------ ##
## Environment. ##
## ------------ ##

std_path = $(abs_srcdir)/lib/?.lua
LUA_ENV  = LUA_PATH="$(std_path);$(LUA_PATH)"


## ---------- ##
## Bootstrap. ##
## ---------- ##

old_NEWS_hash = 7a7647cb5b2d5d886a18070e1f4ac5fd

update_copyright_env = \
	UPDATE_COPYRIGHT_HOLDER='(Gary V. Vaughan|Reuben Thomas)' \
	UPDATE_COPYRIGHT_USE_INTERVALS=1 \
	UPDATE_COPYRIGHT_FORCE=1


## ------------- ##
## Declarations. ##
## ------------- ##

classesdir		= $(docdir)/classes
modulesdir		= $(docdir)/modules

dist_doc_DATA		=
dist_classes_DATA	=
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
	lib/std/container.lua		\
	lib/std/debug.lua		\
	lib/std/functional.lua		\
	lib/std/io.lua			\
	lib/std/list.lua		\
	lib/std/math.lua		\
	lib/std/modules.lua		\
	lib/std/object.lua		\
	lib/std/optparse.lua		\
	lib/std/package.lua		\
	lib/std/set.lua			\
	lib/std/strbuf.lua		\
	lib/std/strict.lua		\
	lib/std/string.lua		\
	lib/std/table.lua		\
	lib/std/tree.lua		\
	$(NOTHING_ELSE)


# For bugwards compatibility with LuaRocks 2.1, while ensuring that
# `require "std.debug_init"` continues to work, we have to install
# the former `$(luadir)/std/debug_init.lua` to `debug_init/init.lua`.
# When everyone has upgraded to a LuaRocks that works, move this
# file back to dist_luastd_DATA above and rename to debug_init.lua.

luastddebugdir = $(luastddir)/debug_init

dist_luastddebug_DATA =			\
	lib/std/debug_init/init.lua	\
	$(NOTHING_ELSE)

# In order to avoid regenerating std.lua at configure time, which
# causes the documentation to be rebuilt and hence requires users to
# have ldoc installed, put std/std.lua in as a Makefile dependency.
# (Strictly speaking, distributing an AC_CONFIG_FILE would be wrong.)
lib/std.lua: lib/std.lua.in
	./config.status --file=$@


## Use a builtin rockspec build with root at $(srcdir)/lib, and note
## the github repository doesn't have the same name as the rockspec!
mkrockspecs_args = --module-dir $(srcdir)/lib --repository lua-stdlib


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	build-aux/config.ld.in		\
	lib/std.lua.in			\
	$(NOTHING_ELSE)


## -------------- ##
## Documentation. ##
## -------------- ##


dist_doc_DATA +=			\
	$(srcdir)/doc/index.html	\
	$(srcdir)/doc/ldoc.css

dist_classes_DATA +=					\
	$(srcdir)/doc/classes/std.container.html	\
	$(srcdir)/doc/classes/std.list.html		\
	$(srcdir)/doc/classes/std.object.html		\
	$(srcdir)/doc/classes/std.optparse.html		\
	$(srcdir)/doc/classes/std.set.html		\
	$(srcdir)/doc/classes/std.strbuf.html		\
	$(srcdir)/doc/classes/std.tree.html		\
	$(NOTHING_ELSE)

dist_modules_DATA +=					\
	$(srcdir)/doc/modules/std.html			\
	$(srcdir)/doc/modules/std.debug.html		\
	$(srcdir)/doc/modules/std.functional.html	\
	$(srcdir)/doc/modules/std.io.html		\
	$(srcdir)/doc/modules/std.math.html		\
	$(srcdir)/doc/modules/std.package.html		\
	$(srcdir)/doc/modules/std.strict.html		\
	$(srcdir)/doc/modules/std.string.html		\
	$(srcdir)/doc/modules/std.table.html		\
	$(NOTHING_ELSE)

ldoc_DEPS = $(dist_lua_DATA) $(dist_luastd_DATA)

$(dist_doc_DATA) $(dist_classes_DATA) $(dist_modules_DATA): $(ldoc_DEPS)
	test -d "$(srcdir)/doc" || mkdir "$(srcdir)/doc"
	$(LDOC) -c build-aux/config.ld -d $(abs_srcdir)/doc .
