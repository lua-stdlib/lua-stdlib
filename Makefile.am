# Non-recursive Make rules.


## ------------ ##
## Environment. ##
## ------------ ##

LUA_PATH ?= ;


## ---------- ##
## Bootstrap. ##
## ---------- ##

ACLOCAL_AMFLAGS = -I m4


## ------------- ##
## Declarations. ##
## ------------- ##

CLEANFILES		=
DISTCLEANFILES		=
EXTRA_DIST		=
MAINTAINERCLEANFILES	=
NOTHING_ELSE		=

filesdir		= $(docdir)/files
modulesdir		= $(docdir)/modules

check_local		=
dist_doc_DATA		=
dist_files_DATA		=
dist_modules_DATA	=

include std/std.mk
include specs/specs.mk


## ------------ ##
## Local Tests. ##
## ------------ ##

check-local: $(check_local)


## ------------- ##
## Distribution. ##
## ------------- ##

EXTRA_DIST +=				\
	GNUmakefile			\
	$(NOTHING_ELSE)

DISTCLEANFILES += $(PACKAGE).rockspec
