# Specl specs make rules.


## ------------ ##
## Environment. ##
## ------------ ##

SPECL_ENV = $(LUA_ENV)


## ------ ##
## Specs. ##
## ------ ##

specl_SPECS =					\
	$(srcdir)/specs/debug_ext_spec.yaml	\
	$(srcdir)/specs/getopt_spec.yaml	\
	$(srcdir)/specs/io_ext_spec.yaml	\
	$(srcdir)/specs/math_ext_spec.yaml	\
	$(srcdir)/specs/object_spec.yaml	\
	$(srcdir)/specs/package_ext_spec.yaml	\
	$(srcdir)/specs/set_spec.yaml		\
	$(srcdir)/specs/strbuf_spec.yaml	\
	$(srcdir)/specs/string_ext_spec.yaml	\
	$(srcdir)/specs/table_ext_spec.yaml	\
	$(NOTHING_ELSE)

EXTRA_DIST +=					\
	$(srcdir)/specs/spec_helper.lua		\
	$(NOTHING_ELSE)

include build-aux/specl.mk
