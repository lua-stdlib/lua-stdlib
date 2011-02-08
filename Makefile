all:
	@echo "REL=VERSION make {release,dist}"

dist:
	cd modules && ../utils/ldoc *.lua
	cd .. && tar czf stdlib-${REL}.tar.gz --exclude=.git --exclude=.gitignore --exclude=".#*" --exclude="release-notes-*" stdlib

release: dist
	git diff --exit-code && \
	git tag -a -m "Release tag" rel-${REL} && \
	git push && \
	woger lua-l stdlib stdlib "release ${REL}" "General Lua libraries" release-notes-${REL}
	@cat release-notes-$(REL) && echo "Don't forget to release on LuaForge!"
