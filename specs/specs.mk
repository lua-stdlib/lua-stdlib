# Specl specs make rules.


## ------ ##
## Specs. ##
## ------ ##

SPECL_OPTS = --unicode

## For compatibility with Specl < 11, std_spec.yaml has to be
## last, so that when `require "std"` leaks symbols into the
## Specl global environment, subsequent example blocks are not
## affected.

specl_SPECS =					\
	$(srcdir)/specs/container_spec.yaml	\
	$(srcdir)/specs/debug_spec.yaml		\
	$(srcdir)/specs/functional_spec.yaml	\
	$(srcdir)/specs/io_spec.yaml		\
	$(srcdir)/specs/list_spec.yaml		\
	$(srcdir)/specs/math_spec.yaml		\
	$(srcdir)/specs/object_spec.yaml	\
	$(srcdir)/specs/operator_spec.yaml	\
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
	$(srcdir)/specs/spec_helper.lua		\
	$(NOTHING_ELSE)

include build-aux/specl.mk
