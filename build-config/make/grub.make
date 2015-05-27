#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014-2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of grub
#

GRUB_VERSION		= e4a1fe391
GRUB_TARBALL		= grub-$(GRUB_VERSION).tar.xz
GRUB_TARBALL_URLS	+= $(ONIE_MIRROR) http://git.savannah.gnu.org/cgit/grub.git/snapshot/
GRUB_BUILD_DIR		= $(MBUILDDIR)/grub
GRUB_DIR		= $(GRUB_BUILD_DIR)/grub-$(GRUB_VERSION)
GRUB_I386_DIR		= $(GRUB_BUILD_DIR)/grub-i386-pc
GRUB_UEFI_DIR		= $(GRUB_BUILD_DIR)/grub-x86_64-efi

GRUB_SRCPATCHDIR	= $(PATCHDIR)/grub
GRUB_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/grub-download
GRUB_SOURCE_STAMP	= $(STAMPDIR)/grub-source
GRUB_PATCH_STAMP	= $(STAMPDIR)/grub-patch
GRUB_CONFIGURE_I386_STAMP	= $(STAMPDIR)/grub-configure-i386-pc
GRUB_CONFIGURE_UEFI_STAMP	= $(STAMPDIR)/grub-configure-x86_64-efi
GRUB_CONFIGURE_STAMP	= $(STAMPDIR)/grub-configure
GRUB_BUILD_I386_STAMP	= $(STAMPDIR)/grub-build-i386-pc
GRUB_BUILD_UEFI_STAMP	= $(STAMPDIR)/grub-build-x86_64-efi
GRUB_BUILD_STAMP	= $(STAMPDIR)/grub-build
GRUB_INSTALL_STAMP	= $(STAMPDIR)/grub-install

GRUB_STAMP		= $(GRUB_SOURCE_STAMP) \
			  $(GRUB_PATCH_STAMP) \
			  $(GRUB_CONFIGURE_I386_STAMP) \
			  $(GRUB_CONFIGURE_UEFI_STAMP) \
			  $(GRUB_CONFIGURE_STAMP) \
			  $(GRUB_BUILD_I386_STAMP) \
			  $(GRUB_BUILD_UEFI_STAMP) \
			  $(GRUB_BUILD_STAMP) \
			  $(GRUB_INSTALL_STAMP)

# GRUB configuration options common to i386-pc and x86_64-efi
GRUB_COMMON_CONFIG = 			\
		--prefix=/usr		\
		--enable-device-mapper	\
		--disable-nls		\
		--disable-efiemu	\
		--disable-grub-mkfont	\
		--disable-grub-themes

PHONY += grub grub-download grub-source grub-patch \
	 grub-configure grub-build grub-install grub-clean \
	 grub-download-clean

GRUB_SBIN = grub-install grub-bios-setup grub-probe grub-reboot grub-set-default
GRUB_BIN = grub-mkrelpath grub-mkimage grub-editenv

grub: $(GRUB_STAMP)

DOWNLOAD += $(GRUB_DOWNLOAD_STAMP)
grub-download: $(GRUB_DOWNLOAD_STAMP)
$(GRUB_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream grub ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(GRUB_TARBALL) $(GRUB_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(GRUB_SOURCE_STAMP)
grub-source: $(GRUB_SOURCE_STAMP)
$(GRUB_SOURCE_STAMP): $(TREE_STAMP) | $(GRUB_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream grub ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GRUB_BUILD_DIR) $(DOWNLOADDIR)/$(GRUB_TARBALL)
	$(Q) touch $@

grub-patch: $(GRUB_PATCH_STAMP)
$(GRUB_PATCH_STAMP): $(GRUB_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching grub-$(GRUB_VERSION) ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GRUB_SRCPATCHDIR)/series $(GRUB_DIR)
	$(Q) cd $(GRUB_DIR) && ./autogen.sh
	$(Q) touch $@

$(GRUB_CONFIGURE_I386_STAMP): $(GRUB_PATCH_STAMP) $(LVM2_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-i386-pc-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_I386_DIR)
	$(Q) cd $(GRUB_I386_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--host=$(TARGET)				\
		--with-platform=pc				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

$(GRUB_CONFIGURE_UEFI_STAMP): $(GRUB_PATCH_STAMP) $(LVM2_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-x86_64-efi-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_UEFI_DIR)
	$(Q) cd $(GRUB_UEFI_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--host=$(TARGET)				\
		--with-platform=efi				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

grub-configure: $(GRUB_CONFIGURE_STAMP)
$(GRUB_CONFIGURE_STAMP): $(GRUB_CONFIGURE_I386_STAMP) $(GRUB_CONFIGURE_UEFI_STAMP)
	$(Q) touch $@

$(GRUB_BUILD_I386_STAMP): $(GRUB_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-i386-pc-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_I386_DIR)
	$(Q) touch $@

$(GRUB_BUILD_UEFI_STAMP): $(GRUB_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-x86_64-efi-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_UEFI_DIR)
	$(Q) touch $@

grub-build: $(GRUB_BUILD_STAMP)
$(GRUB_BUILD_STAMP): $(GRUB_BUILD_I386_STAMP) $(GRUB_BUILD_UEFI_STAMP)
	$(Q) touch $@

grub-install: $(GRUB_INSTALL_STAMP)
$(GRUB_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(GRUB_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing grub in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(GRUB_I386_DIR) install DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(GRUB_UEFI_DIR) install DESTDIR=$(DEV_SYSROOT)
	$(Q) cp -a $(DEV_SYSROOT)/usr/lib/grub $(SYSROOTDIR)/usr/lib
	$(Q) cp -a $(DEV_SYSROOT)/usr/share/grub $(SYSROOTDIR)/usr/share
	$(Q) for f in $(GRUB_SBIN) ; do \
		cp -a $(DEV_SYSROOT)/usr/sbin/$$f $(SYSROOTDIR)/usr/sbin ; \
	done
	$(Q) for f in $(GRUB_BIN) ; do \
		cp -a $(DEV_SYSROOT)/usr/bin/$$f $(SYSROOTDIR)/usr/bin ; \
	done
	$(Q) touch $@

USERSPACE_CLEAN += grub-clean
grub-clean:
	$(Q) rm -rf $(GRUB_BUILD_DIR)
	$(Q) rm -f $(GRUB_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += grub-download-clean
grub-download-clean:
	$(Q) rm -f $(GRUB_DOWNLOAD_STAMP) $(DOWNLOADDIR)/grub*

# ---------------------------------------------------------------------------
# grub-host build rules

# Building the .ISO image requires a host build of GRUB.

GRUB_HOST_BUILD_DIR		= $(MBUILDDIR)/grub-host
GRUB_HOST_DIR			= $(GRUB_HOST_BUILD_DIR)/grub-$(GRUB_VERSION)
GRUB_HOST_I386_DIR		= $(GRUB_HOST_BUILD_DIR)/grub-i386-pc
GRUB_HOST_UEFI_DIR		= $(GRUB_HOST_BUILD_DIR)/grub-x86_64-efi
GRUB_HOST_INSTALL_I386_DIR	= $(GRUB_HOST_BUILD_DIR)/i386-pc-install
GRUB_HOST_LIB_I386_DIR		= $(GRUB_HOST_INSTALL_I386_DIR)/usr/lib/grub/i386-pc
GRUB_HOST_BIN_I386_DIR		= $(GRUB_HOST_INSTALL_I386_DIR)/usr/bin
GRUB_HOST_INSTALL_UEFI_DIR	= $(GRUB_HOST_BUILD_DIR)/x86_64-efi-install
GRUB_HOST_LIB_UEFI_DIR		= $(GRUB_HOST_INSTALL_UEFI_DIR)/usr/lib/grub/x86_64-efi
GRUB_HOST_BIN_UEFI_DIR		= $(GRUB_HOST_INSTALL_UEFI_DIR)/usr/bin
GRUB_HOST_CONFIGURE_I386_STAMP	= $(STAMPDIR)/grub-host-configure-i386-pc
GRUB_HOST_CONFIGURE_UEFI_STAMP	= $(STAMPDIR)/grub-host-configure-x86_64-efi
GRUB_HOST_CONFIGURE_STAMP	= $(STAMPDIR)/grub-host-configure
GRUB_HOST_BUILD_I386_STAMP	= $(STAMPDIR)/grub-host-build-i386-pc
GRUB_HOST_BUILD_UEFI_STAMP	= $(STAMPDIR)/grub-host-build-x86_64-efi
GRUB_HOST_BUILD_STAMP		= $(STAMPDIR)/grub-host-build
GRUB_HOST_INSTALL_STAMP		= $(STAMPDIR)/grub-host-install

PHONY += grub-host-configure grub-host-build grub-host-install grub-host-clean

GRUB_HOST_STAMP = $(GRUB_HOST_CONFIGURE_STAMP) \
		$(GRUB_HOST_CONFIGURE_I386_STAMP) \
		$(GRUB_HOST_CONFIGURE_UEFI_STAMP) \
		$(GRUB_HOST_BUILD_STAMP) \
		$(GRUB_HOST_BUILD_I386_STAMP) \
		$(GRUB_HOST_BUILD_UEFI_STAMP) \
		$(GRUB_HOST_INSTALL_STAMP)

grub-host: $(GRUB_HOST_STAMP)

$(GRUB_HOST_CONFIGURE_I386_STAMP): $(GRUB_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-host-i386-pc-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_HOST_I386_DIR)
	$(Q) cd $(GRUB_HOST_I386_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--with-platform=pc
	$(Q) touch $@

$(GRUB_HOST_CONFIGURE_UEFI_STAMP): $(GRUB_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-host-x86_64-efi-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_HOST_UEFI_DIR)
	$(Q) cd $(GRUB_HOST_UEFI_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--with-platform=efi
	$(Q) touch $@

grub-host-configure: $(GRUB_HOST_CONFIGURE_STAMP)
$(GRUB_HOST_CONFIGURE_STAMP): $(GRUB_HOST_CONFIGURE_I386_STAMP) $(GRUB_HOST_CONFIGURE_UEFI_STAMP)
	$(Q) touch $@

$(GRUB_HOST_BUILD_I386_STAMP): $(GRUB_HOST_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-host-i386-pc-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_HOST_I386_DIR)
	$(Q) touch $@

$(GRUB_HOST_BUILD_UEFI_STAMP): $(GRUB_HOST_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-host-x86_64-efi-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_HOST_UEFI_DIR)
	$(Q) touch $@

grub-host-build: $(GRUB_HOST_BUILD_STAMP)
$(GRUB_HOST_BUILD_STAMP): $(GRUB_HOST_BUILD_I386_STAMP) $(GRUB_HOST_BUILD_UEFI_STAMP)
	$(Q) touch $@

grub-host-install: $(GRUB_HOST_INSTALL_STAMP)
$(GRUB_HOST_INSTALL_STAMP): $(GRUB_HOST_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing grub-host in $(GRUB_HOST_INSTALL_DIR) ===="
	$(Q) $(MAKE) -C $(GRUB_HOST_I386_DIR) install DESTDIR=$(GRUB_HOST_INSTALL_I386_DIR)
	$(Q) $(MAKE) -C $(GRUB_HOST_UEFI_DIR) install DESTDIR=$(GRUB_HOST_INSTALL_UEFI_DIR)
	$(Q) touch $@

USERSPACE_CLEAN += grub-host-clean
grub-host-clean:
	$(Q) rm -rf $(GRUB_HOST_BUILD_DIR)
	$(Q) rm -f $(GRUB_HOST_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
