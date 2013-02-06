## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS = -I m4

SOURCES = $(wildcard src/*.lua)
dist_data_DATA = $(SOURCES)

dist_doc_DATA =				\
	src/index.html			\
	src/luadoc.css
filesdir = $(docdir)/files
dist_files_DATA = $(wildcard src/files/*.html)
modulesdir = $(docdir)/modules
dist_modules_DATA = $(wildcard src/modules/*.html)

EXTRA_DIST =				\
	src/std.lua.in			\
	$(PACKAGE).rockspec.in

DISTCLEANFILES = $(PACKAGE).rockspec

ROCKSPEC = $(PACKAGE)-$(VERSION)-1.rockspec

$(dist_doc_DATA): $(SOURCES)
	cd src && luadoc *.lua

$(ROCKSPEC): $(PACKAGE).rockspec
	cp $< $@

tag-release:
	git diff --exit-code && \
	git tag -a -m "Release tag" v$(VERSION) && \
	git push && git push --tags

check-in-release:
	git checkout release && \
	tar zxf $(PACKAGE)-$(VERSION).tar.gz && \
	cp -af $(PACKAGE)-$(VERSION)/* . && \
	git add . && git ci -m "Release v$(VERSION)" && \
	git tag -a -m "Release tag" release-v$(VERSION) && \
	git push && git push --tags && \
	git checkout master

release: $(ROCKSPEC) distcheck
	$(MAKE) tag-release && \
	$(MAKE) check-in-release && \
	LUAROCKS_CONFIG=$(abs_srcdir)/luarocks-config.lua luarocks --tree=$(abs_srcdir)/luarocks build $(ROCKSPEC) && \
	woger lua package=$(PACKAGE) package_name=$(PACKAGE_NAME) version=$(VERSION) description="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?.rockspec.in' $(LUA) -l$(PACKAGE) -e 'print (description.summary)'`" notes=release-notes-$(VERSION) home="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?.rockspec.in' $(LUA) -l$(PACKAGE) -e 'print (description.homepage)'`"
