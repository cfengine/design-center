generate-cfsketches:
	grep '"name":' `find . -name sketch.json`|sort|perl -p -e's,^\./,,; s,/sketch.json:\s+"name":\s+"([^"]+)".*, \1,' > cfsketches
