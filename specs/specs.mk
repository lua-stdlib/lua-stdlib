# Specl specs make rules.


## ------------ ##
## Environment. ##
## ------------ ##

SPECL_ENV = $(LUA_ENV)


## ------ ##
## Specs. ##
## ------ ##

specl_SPECS =					\
	$(srcdir)/specs/container_spec.yaml	\
	$(srcdir)/specs/debug_spec.yaml		\
	$(srcdir)/specs/getopt_spec.yaml	\
	$(srcdir)/specs/io_spec.yaml		\
	$(srcdir)/specs/list_spec.yaml		\
	$(srcdir)/specs/math_spec.yaml		\
	$(srcdir)/specs/object_spec.yaml	\
	$(srcdir)/specs/package_spec.yaml	\
	$(srcdir)/specs/set_spec.yaml		\
	$(srcdir)/specs/strbuf_spec.yaml	\
	$(srcdir)/specs/string_spec.yaml	\
	$(srcdir)/specs/table_spec.yaml		\
	$(srcdir)/specs/tree_spec.yaml		\
	$(NOTHING_ELSE)

EXTRA_DIST +=					\
	$(srcdir)/specs/spec_helper.lua		\
	$(NOTHING_ELSE)

include build-aux/specl.mk
