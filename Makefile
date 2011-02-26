all:
	@echo "REL=VERSION make {release,dist}"

zip = stdlib-${REL}.zip

dist:
	cd modules && ../utils/ldoc *.lua
	rm -f *.zip && cd .. && zip $(zip) -r stdlib -x "stdlib/.git/*" "*.gitignore" "*release-notes-*" && mv $(zip) stdlib/

release: dist
	git diff --exit-code && \
	git tag -a -m "Release tag" rel-${REL} && \
	git push && \
	woger lua-l stdlib stdlib "release ${REL}" "General Lua libraries" release-notes-${REL}
	@cat release-notes-$(REL) && echo "\n\nDon't forget to release on LuaForge!"
