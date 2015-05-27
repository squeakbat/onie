#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of efivar
#

EFIVAR_VERSION			= 0.18
EFIVAR_TARBALL			= efivar-$(EFIVAR_VERSION).tar.bz2
EFIVAR_TARBALL_URLS		+= $(ONIE_MIRROR) https://github.com/rhinstaller/efivar/releases/download/$(EFIVAR_VERSION)
EFIVAR_BUILD_DIR		= $(MBUILDDIR)/efivar
EFIVAR_DIR			= $(EFIVAR_BUILD_DIR)/efivar-$(EFIVAR_VERSION)

EFIVAR_SRCPATCHDIR		= $(PATCHDIR)/efivar
EFIVAR_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/efivar-download
EFIVAR_SOURCE_STAMP		= $(STAMPDIR)/efivar-source
EFIVAR_PATCH_STAMP		= $(STAMPDIR)/efivar-patch
EFIVAR_BUILD_STAMP		= $(STAMPDIR)/efivar-build
EFIVAR_INSTALL_STAMP		= $(STAMPDIR)/efivar-install
EFIVAR_STAMP			= $(EFIVAR_SOURCE_STAMP) \
				  $(EFIVAR_PATCH_STAMP) \
				  $(EFIVAR_BUILD_STAMP) \
				  $(EFIVAR_INSTALL_STAMP)

EFIVAR_PROGRAMS		= efivar

PHONY += efivar efivar-download efivar-source efivar-patch \
	efivar-build efivar-install efivar-clean efivar-download-clean

EFIVAR_BINS = efivar
EFIVAR_LIBS = libefivar.so.0 libefivar.so

efivar: $(EFIVAR_STAMP)

DOWNLOAD += $(EFIVAR_DOWNLOAD_STAMP)
efivar-download: $(EFIVAR_DOWNLOAD_STAMP)
$(EFIVAR_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream efivar ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(EFIVAR_TARBALL) $(EFIVAR_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(EFIVAR_SOURCE_STAMP)
efivar-source: $(EFIVAR_SOURCE_STAMP)
$(EFIVAR_SOURCE_STAMP): $(TREE_STAMP) | $(EFIVAR_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream efivar ===="
	$(Q) $(SCRIPTDIR)/extract-package $(EFIVAR_BUILD_DIR) $(DOWNLOADDIR)/$(EFIVAR_TARBALL)
	$(Q) touch $@

efivar-patch: $(EFIVAR_PATCH_STAMP)
$(EFIVAR_PATCH_STAMP): $(EFIVAR_SRCPATCHDIR)/* $(EFIVAR_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching efivar ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(EFIVAR_SRCPATCHDIR)/series $(EFIVAR_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
EFIVAR_NEW_FILES = $(shell test -d $(EFIVAR_DIR) && test -f $(EFIVAR_BUILD_STAMP) && \
	              find -L $(EFIVAR_DIR) -newer $(EFIVAR_BUILD_STAMP) -type f -print -quit)
endif

efivar-build: $(EFIVAR_BUILD_STAMP)
$(EFIVAR_BUILD_STAMP): $(EFIVAR_PATCH_STAMP) $(EFIVAR_NEW_FILES) $(POPT_INSTALL_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building efivar-$(EFIVAR_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(EFIVAR_DIR) CROSS_COMPILE=$(CROSSPREFIX)
	$(Q) touch $@

efivar-install: $(EFIVAR_INSTALL_STAMP)
$(EFIVAR_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(EFIVAR_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing efivar in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(EFIVAR_DIR) CROSS_COMPILE=$(CROSSPREFIX) DESTDIR=$(DEV_SYSROOT) install
	$(Q) for file in $(EFIVAR_BINS); do \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/bin/ ; \
	     done
	$(Q) for file in $(EFIVAR_LIBS); do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	     done
	$(Q) touch $@

USERSPACE_CLEAN += efivar-clean
efivar-clean:
	$(Q) rm -rf $(EFIVAR_BUILD_DIR)
	$(Q) rm -f $(EFIVAR_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += efivar-download-clean
efivar-download-clean:
	$(Q) rm -f $(EFIVAR_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(EFIVAR_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
