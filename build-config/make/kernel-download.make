#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the download of the kernel version
#

#-------------------------------------------------------------------------------
# Need the Linux kernel downloaded before building xtools

LINUX_VERSION		?= 3.2
LINUX_MAJOR_VERSION	= $(firstword $(subst ., ,$(LINUX_VERSION)))
LINUX_MINOR_VERSION	?= 35
LINUX_RELEASE		?= $(LINUX_VERSION).$(LINUX_MINOR_VERSION)
LINUX_TARBALL		?= linux-$(LINUX_RELEASE).tar.xz
export LINUX_TARBALL
export LINUX_RELEASE
LINUX_TARBALL_URLS	+= $(ONIE_MIRROR) https://www.kernel.org/pub/linux/kernel/v$(LINUX_MAJOR_VERSION).x

KERNEL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/kernel-download-$(LINUX_RELEASE)

PHONY += kernel-download kernel-download-clean

DOWNLOAD += $(KERNEL_DOWNLOAD_STAMP)
kernel-download: $(KERNEL_DOWNLOAD_STAMP)
$(KERNEL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting Linux ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LINUX_TARBALL) $(LINUX_TARBALL_URLS)
	$(Q) touch $@

DOWNLOAD_CLEAN += kernel-download-clean
kernel-download-clean:
	$(Q) rm -f $(KERNEL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LINUX_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
