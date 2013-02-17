## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS = -I m4

LUA_PATH ?= ;
LUA_ENV = LUA_PATH="$(abs_srcdir)/src/?.lua;$(LUA_PATH)"

SOURCES = $(filter-out $(srcdir)/src/std.lua, $(wildcard $(srcdir)/src/*.lua))
SOURCES += $(srcdir)/src/std.lua
dist_data_DATA = $(SOURCES)

dist_doc_DATA =				\
	$(top_srcdir)/src/index.html	\
	$(top_srcdir)/src/luadoc.css
filesdir = $(docdir)/files
dist_files_DATA = $(wildcard $(top_srcdir)/src/files/*.html)
modulesdir = $(docdir)/modules
dist_modules_DATA = $(wildcard $(top_srcdir)/src/modules/*.html)

EXTRA_DIST =				\
	src/std.lua.in

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

bootstrap:
	autoreconf -i && \
	./configure

tag-release:
	git diff --exit-code && \
	git tag -a -m "Release tag" v$(VERSION) && \
	git push && git push --tags

check-in-release: distcheck
	cd ../lua-stdlib-release && \
	tar zxf ../lua-stdlib/$(PACKAGE)-$(VERSION).tar.gz && \
	cp -af $(PACKAGE)-$(VERSION)/* . && \
	rm -rf $(PACKAGE)-$(VERSION)/ && \
	git add . && git ci -m "Release v$(VERSION)" && \
	git tag -a -m "Full source release tag" release-v$(VERSION) && \
	git push && git push --tags

# After check-in-release we need to bootstrap to get the build files back
release: rockspecs
	$(MAKE) tag-release && \
	$(MAKE) check-in-release && \
	LUAROCKS_CONFIG=$(abs_srcdir)/luarocks-config.lua luarocks --tree=$(abs_srcdir)/luarocks build $(PACKAGE)-$(VERSION)-1.rockspec && \
	woger lua package=$(PACKAGE) package_name=$(PACKAGE_NAME) version=$(VERSION) description="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?-git-1.rockspec' $(LUA) -l$(PACKAGE) -e 'print (description.summary)'`" home="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?-git-1.rockspec' $(LUA) -l$(PACKAGE) -e 'print (description.homepage)'`"
