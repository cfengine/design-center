ifeq ($(DESTDIR),)
  DESTDIR:=/var/cfengine/share/NovaBase
endif

ifeq ($(GIT),)
  GIT:=git
endif

ifeq ($(BUNDLEREF),)
  BUNDLEREF:=master
endif

UNAME := $(shell uname)

ifeq ($(UNAME), Solaris)
I:=/usr/local/bin/install
else
I:=/usr/bin/install
endif

check:
	cd tools/test; make api_selftest_junit NOIGNORE=1

# NOTE: extract bundle with git clone -b $(BUNDLEREF) $(DESTDIR)/design-center.bundle
install-bundle:
	mkdir -p $(DESTDIR)
	$(GIT) bundle create $(DESTDIR)/design-center.bundle $(BUNDLEREF)

install-sketches:
	/bin/mkdir -p $(DESTDIR)
# disabled # $(GIT) ls-files sketches | $(GIT) checkout-index --stdin -f --prefix=$(DESTDIR)/
	$(I) -d $(DESTDIR)
	/bin/cp -rp ./sketches $(DESTDIR)/

install-tools:
	cd tools/cf-sketch; make install-full PREFIX=$(DESTDIR) GIT=$(GIT)

install: install-sketches install-tools
