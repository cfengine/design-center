ifeq ($(INSTALLDIR),)
  INSTALLDIR:=/var/cfengine/share/NovaBase
endif

ifeq ($(BUNDLEREF),)
  BUNDLEREF:=master
endif

check:
	cd tools/test; make api_selftest_junit NOIGNORE=1

install:
	mkdir -p $(INSTALLDIR)
	git bundle create $(INSTALLDIR)/design-center.bundle $(BUNDLEREF)
	@echo "NOTE: extract bundle with git clone -b $(BUNDLEREF) $(INSTALLDIR)/design-center.bundle"
