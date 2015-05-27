# KVM x86_64 Virtual Machin

#  Copyright (C) 2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Stephen Su <sustephen@juniper.net>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>

ONIE_ARCH ?= x86_64

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION = .12.34

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 42623

# Skip the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = no

# The onie-syseeprom command in i2ctools is deprecated.  It is recommended to
# use the one implemented in busybox instead.  The option intends to provide a
# quick way to turn off the feature in i2ctools.  The command will be removed
# from i2ctools in the future once all machines migrate their support of
# sys_eeprom to busybox.
#
# The option is significant when I2CTOOLS_ENABLE is 'yes'
#
#I2CTOOLS_SYSEEPROM = no

# Set the desired kernel version.
LINUX_VERSION		= 4.0
LINUX_MINOR_VERSION	= 4

# Set the desired uClibc version
UCLIBC_VERSION = 0.9.33.2

#
# Console parameters can be defined here (default values are in
# build-config/arch/x86_64.make).
# For example,
# 
# CONSOLE_SPEED = 9600
# CONSOLE_DEV = 0

# Specify any extra parameters that you'd want to pass to the onie linux
# kernel command line in EXTRA_CMDLINE_LINUX env variable. Eg:
#
#EXTRA_CMDLINE_LINUX ?= install_url=http://server/path/to/installer debug earlyprintk=serial
#
# NOTE: You can give multiple space separated parameters

# Specify the default menu option when booting a recovery image.  Valid
# values are "rescue" or "embed" (without double-quotes). This
# parameter defaults to "rescue" mode if not specified here.
# RECOVERY_DEFAULT_ENTRY = embed

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
