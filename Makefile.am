## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS = -I m4

SOURCES = $(wildcard $(srcdir)/src/*.lua)
dist_data_DATA = $(SOURCES)

dist_doc_DATA =				\
	$(top_srcdir)/src/index.html	\
	$(top_srcdir)/src/luadoc.css
filesdir = $(docdir)/files
dist_files_DATA = $(wildcard $(top_srcdir)/src/files/*.html)
modulesdir = $(docdir)/modules
dist_modules_DATA = $(wildcard $(top_srcdir)/src/modules/*.html)

EXTRA_DIST =				\
	src/std.lua.in			\
	$(PACKAGE).rockspec.in

DISTCLEANFILES = $(PACKAGE).rockspec

ROCKSPEC = $(PACKAGE)-$(VERSION)-1.rockspec

# In order to avoid regenerating std.lua at configure time, which
# causes the documentation to be rebuilt and hence requires users to
# have luadoc installed, put src/std.lua in as a Makefile dependency.
# (Strictly speaking, distributing an AC_CONFIG_FILE would be wrong.)
src/std.lua: src/std.lua.in
	./config.status --file=$@

$(dist_doc_DATA): $(SOURCES)
	cd src && luadoc *.lua

$(ROCKSPEC): $(PACKAGE).rockspec
	cp $< $@

bootstrap:
	autoreconf -i && \
	./configure

tag-release:
	git diff --exit-code && \
	git tag -a -m "Release tag" v$(VERSION) && \
	git push && git push --tags

check-in-release: distcheck
	git checkout release && \
	tar zxf $(PACKAGE)-$(VERSION).tar.gz && \
	cp -af $(PACKAGE)-$(VERSION)/* . && \
	git add . && git ci -m "Release v$(VERSION)" && \
	git tag -a -m "Full source release tag" release-v$(VERSION) && \
	git push && git push --tags && \
	git checkout master && \
	rm -rf $(PACKAGE)-$(VERSION)/

# After check-in-release we need to bootstrap to get the build files back
release: $(ROCKSPEC)
	$(MAKE) tag-release && \
	$(MAKE) check-in-release && \
	$(MAKE) bootstrap && \
	$(MAKE) $(ROCKSPEC) && \
	LUAROCKS_CONFIG=$(abs_srcdir)/luarocks-config.lua luarocks --tree=$(abs_srcdir)/luarocks build $(ROCKSPEC) && \
	woger lua package=$(PACKAGE) package_name=$(PACKAGE_NAME) version=$(VERSION) description="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?.rockspec.in' $(LUA) -l$(PACKAGE) -e 'print (description.summary)'`" notes=release-notes-$(VERSION) home="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?.rockspec.in' $(LUA) -l$(PACKAGE) -e 'print (description.homepage)'`"
