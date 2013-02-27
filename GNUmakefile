## maintainer rules.

dont-forget-to-bootstrap = $(wildcard Makefile)

ifeq ($(dont-forget-to-bootstrap),)

Makefile: Makefile.in
	./configure
	$(MAKE)

Makefile.in:
	autoreconf --force --verbose --install

else

include Makefile

MKROCKSPECS = $(ROCKSPEC_ENV) $(LUA) $(srcdir)/mkrockspecs.lua
ROCKSPEC_TEMPLATE = $(srcdir)/$(PACKAGE)-rockspec.lua

luarocks-config.lua:
	$(AM_V_GEN){				\
	  echo 'rocks_trees = {';		\
	  echo '  "$(abs_srcdir)/luarocks"';	\
	  echo '}';				\
	} > '$@'

rockspecs: luarocks-config.lua
	rm -f *.rockspec
	$(MKROCKSPECS) $(PACKAGE) $(VERSION) $(ROCKSPEC_TEMPLATE)
	$(MKROCKSPECS) $(PACKAGE) git $(ROCKSPEC_TEMPLATE)

GIT ?= git

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
	{ $(GIT) checkout -b release 2>/dev/null || $(GIT) checkout release; } && \
	{ $(GIT) pull origin release || true; } && \
	$(unpack-distcheck-release) && \
	$(GIT) add . && \
	$(GIT) commit -a -m "Release v$(VERSION)" && \
	$(GIT) tag -f -a -m "Full source release tag" release-v$(VERSION)


## To test the release process without publishing upstream, use:
##   make release WOGER=: GIT_PUBLISH=:
GIT_PUBLISH ?= $(GIT)
WOGER ?= woger

WOGER_ENV = LUA_INIT= LUA_PATH='$(abs_srcdir)/?-git-1.rockspec'
WOGER_OUT = $(WOGER_ENV) $(LUA) -l$(PACKAGE) -e

release: rockspecs
	current_branch=`$(GIT) symbolic-ref HEAD`; \
	$(MAKE) tag-release && \
	$(MAKE) check-in-release && \
	$(GIT_PUBLISH) push && $(GIT_PUBLISH) push --tags && \
	LUAROCKS_CONFIG=$(abs_srcdir)/luarocks-config.lua luarocks \
	  --tree=$(abs_srcdir)/luarocks build $(PACKAGE)-$(VERSION)-1.rockspec && \
	$(WOGER) lua \
	  package=$(PACKAGE) \
	  package_name=$(PACKAGE_NAME) \
	  version=$(VERSION) \
	  notes=release-notes-$(VERSION) \
	  home="`$(WOGER_OUT) 'print (description.homepage)'`" \
	  description="`$(WOGER_OUT) 'print (description.summary)'`"
	$(GIT) checkout `echo "$$current_branch" | sed 's,.*/,,g'`

endif
