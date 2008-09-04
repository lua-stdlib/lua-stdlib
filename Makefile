all:
	@echo "REL=VERSION make dist"

dist:
	cd modules && ../utils/ldoc *.lua
	cd .. && tar czf stdlib-${REL}.tar.gz --exclude=CVS --exclude=.cvsignore --exclude=".#*" stdlib