all:
	@echo "REL=VERSION make {release,dist}"

tar = stdlib-${REL}.tar.gz

dist:
	cd modules && ../utils/ldoc *.lua
	rm *.tar.gz && cd .. && tar czf $(tar) --exclude=.git --exclude=.gitignore --exclude=".#*" --exclude="release-notes-*" stdlib && mv $(tar) stdlib/

release: dist
	git diff --exit-code && \
	git tag -a -m "Release tag" rel-${REL} && \
	git push && \
	woger lua-l stdlib stdlib "release ${REL}" "General Lua libraries" release-notes-${REL}
	@cat release-notes-$(REL) && echo "Don't forget to release on LuaForge!"
