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

html: $(SOURCES)
	cd src && luadoc *.lua

ChangeLog:
	git2cl > ChangeLog

WOGER_ARGS = package=$(PACKAGE) package_name=$(PACKAGE_NAME) archive=stdlib-$(VERSION).zip version=$(VERSION) description="`LUA_INIT= LUA_PATH='$(abs_srcdir)/?.rockspec.in' $(LUA) -l$(PACKAGE) -e 'print (description.summary)'`" notes=release-notes-$(VERSION) dist_type=zip github_user=rrthomas

# Depend on distcheck so that 'make release' runs distcheck before
# making the rockspec, so the release archive MD5sum is correct in the
# rockspec
$(ROCKSPEC): $(PACKAGE).rockspec distcheck
	sed -e 's/_MD5_/'`$(MD5SUM) $(distdir).zip | cut -d " " -f 1`'/g' < $(PACKAGE).rockspec > $@

release: $(ROCKSPEC)
	grep md5 $(ROCKSPEC) | sed -e 's/[^"]*"\([0-9a-f]\+\)",/\1  $(distdir).zip/' | md5sum --check - && \
	git diff --exit-code && \
	git push && \
	woger github $(WOGER_ARGS) && \
	LUAROCKS_CONFIG=$(abs_srcdir)/luarocks-config.lua luarocks --tree=$(abs_srcdir)/luarocks build $(ROCKSPEC) && \
	woger lua $(WOGER_ARGS) && \
	git tag -a -m "Release tag" v$(VERSION) && \
	git push --tags
