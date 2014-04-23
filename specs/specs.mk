# Specl specs make rules.


## ------------ ##
## Environment. ##
## ------------ ##

## !!WARNING!! When bootstrap.conf:buildreq specl setting requires specl
##             12 or higher, remove this entire Environment section!

specs_path = $(abs_builddir)/specs/?.lua
SPECL_ENV = LUA_PATH="$(specs_path);$(std_path);$(LUA_PATH)" LUA_INIT= LUA_INIT_5_2=


## ------ ##
## Specs. ##
## ------ ##

SPECL_OPTS = --unicode

## For compatibility with Specl < 11, std_spec.yaml has to be
## last, so that when `require "std"` leaks symbols into the
## Specl global environment, subsequent example blocks are not
## affected.

specl_SPECS =					\
	$(srcdir)/specs/base_spec.yaml		\
	$(srcdir)/specs/container_spec.yaml	\
	$(srcdir)/specs/debug_spec.yaml		\
	$(srcdir)/specs/functional_spec.yaml	\
	$(srcdir)/specs/io_spec.yaml		\
	$(srcdir)/specs/list_spec.yaml		\
	$(srcdir)/specs/math_spec.yaml		\
	$(srcdir)/specs/object_spec.yaml	\
	$(srcdir)/specs/optparse_spec.yaml	\
	$(srcdir)/specs/package_spec.yaml	\
	$(srcdir)/specs/set_spec.yaml		\
	$(srcdir)/specs/strbuf_spec.yaml	\
	$(srcdir)/specs/string_spec.yaml	\
	$(srcdir)/specs/table_spec.yaml		\
	$(srcdir)/specs/tree_spec.yaml		\
	$(srcdir)/specs/std_spec.yaml		\
	$(NOTHING_ELSE)

EXTRA_DIST +=					\
	$(srcdir)/specs/spec_helper.lua.in	\
	$(NOTHING_ELSE)

specl-check-local: specs/spec_helper.lua

include build-aux/specl.mk
