## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS = -I m4

src_spec = $(abs_srcdir)/src/?.lua
lib_spec = $(abs_srcdir)/specs/lib/?.lua

LUA_PATH ?= ;
LUA_ENV  = LUA_PATH="$(src_spec);$(LUA_PATH)"
SPEC_ENV = LUA_PATH="$(lib_spec);$(src_spec);$(LUA_PATH)"

NOTHING_ELSE =

SOURCES = 				\
	src/base.lua			\
	src/bin.lua			\
	src/debug_ext.lua		\
	src/debug_init.lua		\
	src/fstable.lua			\
	src/getopt.lua			\
	src/io_ext.lua			\
	src/lcs.lua			\
	src/list.lua			\
	src/math_ext.lua		\
	src/mbox.lua			\
	src/modules.lua			\
	src/object.lua			\
	src/package_ext.lua		\
	src/parser.lua			\
	src/set.lua			\
	src/std.lua			\
	src/strbuf.lua			\
	src/strict.lua			\
	src/string_ext.lua		\
	src/table_ext.lua		\
	src/tree.lua			\
	src/xml.lua			\
	$(NOTHING_ELSE)

SPECS =					\
	specs/package_ext_spec.lua	\
	specs/table_ext_spec.lua	\
	$(NOTHING_ELSE)

dist_data_DATA = $(SOURCES)

dist_doc_DATA =				\
	$(top_srcdir)/src/index.html	\
	$(top_srcdir)/src/luadoc.css
filesdir = $(docdir)/files
dist_files_DATA = $(wildcard $(top_srcdir)/src/files/*.html)
modulesdir = $(docdir)/modules
dist_modules_DATA = $(wildcard $(top_srcdir)/src/modules/*.html)

EXTRA_DIST =				\
	specs/specl			\
	specs/lib/specl.lua		\
	src/std.lua.in			\
	$(SPECS)			\
	$(NOTHING_ELSE)

DISTCLEANFILES = $(PACKAGE).rockspec

# In order to avoid regenerating std.lua at configure time, which
# causes the documentation to be rebuilt and hence requires users to
# have luadoc installed, put src/std.lua in as a Makefile dependency.
# (Strictly speaking, distributing an AC_CONFIG_FILE would be wrong.)
src/std.lua: src/std.lua.in
	./config.status --file=$@

$(dist_doc_DATA): $(SOURCES)
	cd src && $(LUADOC) *.lua

rockspecs:
	rm -f *.rockspec
	$(LUA_ENV) $(LUA) mkrockspecs.lua $(PACKAGE) $(VERSION)
	$(LUA_ENV) $(LUA) mkrockspecs.lua $(PACKAGE) git

check-local:
	$(AM_V_at)$(SPEC_ENV) $(LUA) $(srcdir)/specs/specl $(srcdir)/specs/*_spec.lua

GIT ?= git
LN_S ?= ln -sf

tag-release:
	$(GIT) diff --exit-code && \
	$(GIT) tag -f -a -m "Release tag" v$(VERSION)

define unpack-distcheck-release
	rm -rf $(PACKAGE)-$(VERSION)/ && \
	tar zxf $(PACKAGE)-$(VERSION).tar.gz && \
	cp -a -f $(PACKAGE)-$(VERSION)/* . && \
	rm -rf $(PACKAGE)-$(VERSION)/ && \
	echo "unpacked $(PACKAGE)-$(VERSION).tar.gz over current directory" && \
	echo './configure && make all rockspecs' && \
	./configure --version && ./configure && \
	$(MAKE) all rockspecs
endef

check-in-release: distcheck
	current_branch=`$(GIT) symbolic-ref HEAD`; \
	{ $(GIT) checkout -b release 2>/dev/null || $(GIT) checkout release; } && \
	{ $(GIT) pull origin release || true; } && \
	$(unpack-distcheck-release) && \
	$(GIT) add . && \
	$(GIT) commit -a -m "Release v$(VERSION)" && \
	$(GIT) tag -f -a -m "Full source release tag" release-v$(VERSION); \
	$(GIT) checkout `echo "$$current_branch" | sed 's,.*/,,g'`


## To test the release process without publishing upstream, use:
##   make release WOGER=: GIT_PUBLISH=:
GIT_PUBLISH ?= $(GIT)

release: rockspecs
	$(MAKE) tag-release && \
	$(MAKE) check-in-release && \
	$(GIT_PUBLISH) push && $(GIT_PUBLISH) push --tags && \
	LUAROCKS_CONFIG=$(abs_srcdir)/luarocks-config.lua luarocks --tree=$(abs_srcdir)/luarocks build $(PACKAGE)-$(VERSION)-1.rockspec && \
	$(WOGER) lua package=$(PACKAGE) package_name=$(PACKAGE_NAME) version=$(VERSION) description="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?-git-1.rockspec' $(LUA) -l$(PACKAGE) -e 'print (description.summary)'`" notes=release-notes-$(VERSION) home="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?-git-1.rockspec' $(LUA) -l$(PACKAGE) -e 'print (description.homepage)'`"
