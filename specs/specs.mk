# Specl specs make rules.


## ------------ ##
## Environment. ##
## ------------ ##

SPECL_ENV = $(LUA_ENV)


## ------ ##
## Tools. ##
## ------ ##

SPECL     ?= specl
SPECL_MIN  = 3

MULTICHECK = $$HOME/.luamultienv


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

check_local += specs-check-local
specs-check-local:
	@v=`specl --version | sed -e 's|^.* ||' -e 1q`;			\
	if test "$$v" -lt "$(SPECL_MIN)"; then				\
	  printf "%s%s\n%s\n"						\
	    "ERROR: Specl version $$v is too old,"			\
	    " please upgrade to at least version $(SPECL_MIN),"		\
	    "ERROR: and rerun \`make check\`";				\
	  exit 1;							\
	else								\
	  $(SPECL_ENV) $(SPECL) $(SPECL_OPTS) $(specl_SPECS);	\
	fi
## Rerun checks with, e.g. https://raw.github.com/rrthomas/lua-stdlib/master/.luamultienv
	@if test -z "$$LUAMULTIENV" && test -f "$(MULTICHECK)";		\
	then								\
	  LUAMULTIENV=loop-me-not $(SHELL) $(MULTICHECK);		\
	fi


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	$(specl_SPECS)			\
	$(NOTHING_ELSE)
