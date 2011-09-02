all:
	@echo "REL=VERSION make {release,dist}"

zip = stdlib-${REL}.zip

dist:
	cd modules && luadoc *.lua
	rm -f *.zip && cd .. && zip $(zip) -r stdlib -x "stdlib/.git/*" "*.gitignore" "*release-notes-*" && mv $(zip) stdlib/

release: dist
	git diff --exit-code && \
	git push && \
	woger lua-l package=stdlib package_name=stdlib version="release ${REL}" description="General Lua libraries" notes=release-notes-${REL} && \
	git tag -a -m "Release tag" rel-${REL} && \
	git push --tags
	@cat release-notes-$(REL) && echo "\n\nDon't forget to release on LuaForge!"
