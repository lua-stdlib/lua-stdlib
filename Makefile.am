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

$(ROCKSPEC): $(PACKAGE).rockspec dist
	sed -e 's/@MD5@/'`$(MD5SUM) $(distdir).zip | cut -d " " -f 1`'/g' < $(PACKAGE).rockspec > $@

html: $(SOURCES)
	cd src && luadoc *.lua

ChangeLog:
	git2cl > ChangeLog

release: distcheck $(ROCKSPEC)
	grep md5 $(ROCKSPEC) | sed -e 's/[^"]*"\([0-9a-f]\+\)",/\1  $(distdir).zip/' | md5sum --check - && \
	git diff --exit-code && \
	git push && \
	woger lua,github package=$(PACKAGE) package_name=$(PACKAGE_NAME) version=$(VERSION) description="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?.rockspec.in' $(LUA) -l$(PACKAGE) -e 'print (description.summary)'`" notes=release-notes-$(VERSION) dist_type=zip github_user=rrthomas
	git tag -a -m "Release tag" rel-`echo $(VERSION) | sed -e 's/\./-/g'` && \
	git push --tags
