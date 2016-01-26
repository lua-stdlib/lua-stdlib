# Local Make rules.
#
# Copyright (C) 2013-2016 Gary V. Vaughan
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

std_path = $(abs_srcdir)/lib/?.lua;$(abs_srcdir)/lib/?/init.lua
LUA_ENV  = LUA_PATH="$(std_path);$(LUA_PATH)"


## ---------- ##
## Bootstrap. ##
## ---------- ##

old_NEWS_hash = d41d8cd98f00b204e9800998ecf8427e

update_copyright_env = \
	UPDATE_COPYRIGHT_HOLDER='(Gary V. Vaughan|Reuben Thomas)' \
	UPDATE_COPYRIGHT_USE_INTERVALS=1 \
	UPDATE_COPYRIGHT_FORCE=1


## ------------- ##
## Declarations. ##
## ------------- ##

doccorefunctionsdir	= $(docdir)/core_functions
doccorelibrariesdir	= $(docdir)/core_libraries
docfunctionaldir	= $(docdir)/functional_style
docmodulesdir		= $(docdir)/modules
docobjectsdir		= $(docdir)/object_system

dist_doc_DATA			=
dist_doccorefunctions_DATA	=
dist_doccorelibraries_DATA	=
dist_docfunctional_DATA		=
dist_docmodules_DATA		=
dist_docobjects_DATA		=

include specs/specs.mk


## ------ ##
## Build. ##
## ------ ##

luastddir = $(luadir)/std

dist_luastd_DATA =			\
	lib/std/base.lua		\
	lib/std/container.lua		\
	lib/std/debug.lua		\
	lib/std/functional.lua		\
	lib/std/io.lua			\
	lib/std/init.lua		\
	lib/std/list.lua		\
	lib/std/math.lua		\
	lib/std/maturity.lua		\
	lib/std/object.lua		\
	lib/std/operator.lua		\
	lib/std/package.lua		\
	lib/std/set.lua			\
	lib/std/strbuf.lua		\
	lib/std/string.lua		\
	lib/std/table.lua		\
	lib/std/tree.lua		\
	lib/std/tuple.lua		\
	lib/std/version.lua		\
	$(NOTHING_ELSE)

luastddeletedir = $(luastddir)/delete-after

dist_luastddelete_DATA =			\
	lib/std/delete-after/2016-01-31.lua	\
	lib/std/delete-after/2016-03-08.lua	\
	lib/std/delete-after/a-year.lua		\
	$(NOTHING_ELSE)

# For bugwards compatibility with LuaRocks 2.1, while ensuring that
# `require "std.debug_init"` continues to work, we have to install
# the former `$(luadir)/std/debug_init.lua` to `debug_init/init.lua`.
# When LuaRocks works again, move this file back to dist_luastd_DATA
# above and rename to debug_init.lua.

luastddebugdir = $(luastddir)/debug_init

dist_luastddebug_DATA =			\
	lib/std/debug_init/init.lua	\
	$(NOTHING_ELSE)

lib/std/version.lua:
	echo 'return "General Lua libraries / $(VERSION)"' > $@T
	@test -f $@ || cp -f $@T $@
	@cmp -s $@T $@ || cp -f $@T $@
	@rm -f $@T


## Use a builtin rockspec build with root at $(srcdir)/lib, and note
## the github repository doesn't have the same name as the rockspec!
mkrockspecs_args = --module-dir $(srcdir)/lib --repository lua-stdlib


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	build-aux/config.ld.in		\
	$(NOTHING_ELSE)


## -------------- ##
## Documentation. ##
## -------------- ##

doccorefunctions = $(srcdir)/doc/core_functions/std
doccorelibraries = $(srcdir)/doc/core_libraries/std
docfunctional    = $(srcdir)/doc/functional_style/std
docmodules       = $(srcdir)/doc/modules/std
docobjects       = $(srcdir)/doc/object_system/std

dist_doc_DATA +=				\
	$(srcdir)/doc/index.html		\
	$(srcdir)/doc/ldoc.css

dist_doccorefunctions_DATA +=			\
	$(doccorefunctions).html		\
	$(NOTHING_ELSE)

dist_doccorelibraries_DATA +=			\
	$(doccorelibraries).debug.html		\
	$(doccorelibraries).io.html		\
	$(doccorelibraries).math.html		\
	$(doccorelibraries).package.html	\
	$(doccorelibraries).string.html		\
	$(doccorelibraries).table.html		\
	$(NOTHING_ELSE)

dist_docfunctional_DATA +=			\
	$(docfunctional).functional.html	\
	$(docfunctional).operator.html		\
	$(NOTHING_ELSE)

dist_docmodules_DATA +=				\
	$(docmodules).maturity.html		\
	$(NOTHING_ELSE)

dist_docobjects_DATA +=				\
	$(docobjects).container.html		\
	$(docobjects).list.html			\
	$(docobjects).object.html		\
	$(docobjects).set.html			\
	$(docobjects).strbuf.html		\
	$(docobjects).tree.html			\
	$(docobjects).tuple.html		\
	$(NOTHING_ELSE)

## Parallel make gets confused when one command ($(LDOC)) produces
## multiple targets (all the html files above), so use the presence
## of the doc directory as a sentinel file.
$(dist_doc_DATA) $(dist_doccorefunctions_DATA): $(srcdir)/doc
$(dist_doccorelibraries_DATA) $(dist_docfunctional_DATA): $(srcdir)/doc
$(dist_docmodules_DATA) $(dist_docobjects_DATA): $(srcdir)/doc

$(srcdir)/doc: $(dist_lua_DATA) $(dist_luastd_DATA)
	test -d $@ || mkdir $@
	$(LDOC) -c build-aux/config.ld -d $(abs_srcdir)/doc .
