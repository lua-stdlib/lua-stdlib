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
	$(srcdir)/specs/package_ext_spec.yaml	\
	$(srcdir)/specs/string_ext_spec.yaml	\
	$(srcdir)/specs/table_ext_spec.yaml	\
	$(NOTHING_ELSE)

include build-aux/specl.mk
