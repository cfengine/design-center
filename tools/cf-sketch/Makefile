PREFIX:=/usr/local
BIN:=$(PREFIX)/bin
LIB:=$(PREFIX)/lib/cf-sketch
I:=/usr/bin/install

help:
	@echo You should probably run '"make install"' unless you want to run cf-sketch.pl directly here.

install:
	$(I) -d $(LIB) $(BIN)
	$(I) -m 755 ./cf-sketch.pl $(BIN)/cf-sketch
	/usr/bin/rsync -a --delete ./perl-lib/ $(LIB)/
	$(I) -m 644 ./constdata.conf $(LIB)/
	/bin/chmod -R a+rX $(LIB)/
	/bin/ln -fs `pwd`/cf-dc-api.pl $(BIN)/cf-dc-api.pl

# Eliminate all signs of cf-sketch from the system. For testing purposes.
# not recommended for general use
clean_system:
	/bin/rm -rf /var/cfengine/inputs/sketches /var/cfengine/masterfiles/sketches $(BIN)/cf-sketch $(BIN)/cf-dc-api.pl $(LIB)
