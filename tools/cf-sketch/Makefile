ifeq ($(PREFIX),)
  PREFIX:=/usr/local
endif

ifeq ($(GIT),)
  GIT:=git
endif

BIN:=$(PREFIX)/bin
LIB:=$(PREFIX)/lib/cf-sketch

ifeq ($(UNAME), Solaris)
I:=/usr/local/bin/install
else
I:=/usr/bin/install
endif

help:
	@echo You should probably run '"make install"' unless you want to run cf-sketch.pl directly here.

install-base:
	/bin/rm -rf $(LIB)
	$(I) -d $(LIB) $(BIN)
	$(I) -m 755 ./cf-sketch.pl $(BIN)/cf-sketch
	/bin/cp -rp ./perl-lib/ $(LIB)/
	$(I) -m 644 ./constdata.conf $(LIB)/
	$(I) -m 644 ./config.json $(LIB)/
	/bin/chmod -R a+rX $(LIB)/

install: install-base
	/bin/ln -fs `pwd`/cf-dc-api.pl $(BIN)/cf-dc-api.pl

install-full: install-base
	$(I) -m 755 ./cf-dc-api.pl $(BIN)/cf-dc-api.pl

# Eliminate all signs of cf-sketch from the system. For testing purposes.
# not recommended for general use
clean_system:
	/bin/rm -rf /var/cfengine/inputs/sketches /var/cfengine/masterfiles/sketches $(BIN)/cf-sketch $(BIN)/cf-dc-api.pl $(LIB)
