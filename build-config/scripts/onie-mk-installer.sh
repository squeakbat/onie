#!/bin/sh

#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# Script to create an ONIE binary installer, suitable for downloading
# to a running ONIE system during "update" mode.
#

arch=$1
machine_dir=$2
machine_conf=$3
installer_dir=$4
output_file=$5

shift 5

[ -d "$machine_dir" ] || {
    echo "ERROR: machine directory '$machine_dir' does not exist."
    exit 1
}
if [ "$arch" = "x86_64" ] ; then
    # installer_conf is required for x86_64
    installer_conf="${machine_dir}/installer.conf"
    [ -r "$installer_conf" ] || {
        echo "ERROR: unable to read machine installer file: $installer_conf"
        exit 1
    }
fi

[ -r "$machine_conf" ] || {
    echo "ERROR: unable to read machine configuration file: $machine_conf"
    exit 1
}

[ -d "$installer_dir" ] || {
    echo "ERROR: installer directory does not exist: $installer_dir"
    exit 1
}

touch $output_file || {
    echo "ERROR: unable to create output file: $output_file"
    exit 1
}
rm -f $output_file

[ $# -gt 0 ] || {
    echo "Error: No ONIE update image files found"
    exit 1
}

tmp_dir=
clean_up()
{
    rm -rf $tmp_dir
}

trap clean_up EXIT

# make the data archive
# contents:
#   - OS image files
#   - $machine_conf

echo -n "Building self-extracting ONIE installer image ."
tmp_dir=$(mktemp --directory)
tmp_installdir="$tmp_dir/installer"
mkdir $tmp_installdir || exit 1
tmp_tardir="$tmp_dir/tar"
mkdir $tmp_tardir || exit 1

for f in $* ; do
    cp -rL "$f" $tmp_tardir || exit 1
    echo -n "."
done

# Bundle data into a tar file
tar -C $tmp_tardir -cJf $tmp_installdir/onie-update.tar.xz $(ls $tmp_tardir) || exit 1
echo -n "."

cp $installer_dir/install.sh $tmp_installdir || exit 1
echo -n "."
cp -r $installer_dir/$arch/* $tmp_installdir

[ -r $machine_dir/installer/install-platform ] && {
    cp $machine_dir/installer/install-platform $tmp_installdir
}

# Escape special chars in the user provide kernel cmdline string for use in
# sed. Special chars are: \ / &
EXTRA_CMDLINE_LINUX=`echo $EXTRA_CMDLINE_LINUX | sed -e 's/[\/&]/\\\&/g'`

# Massage install-arch
if [ "$arch" = "x86_64" ] ; then
    sed -e "s/%%CONSOLE_SPEED%%/$CONSOLE_SPEED/" \
        -e "s/%%CONSOLE_DEV%%/$CONSOLE_DEV/" \
        -e "s/%%CONSOLE_PORT%%/$CONSOLE_PORT/" \
        -e "s/%%EXTRA_CMDLINE_LINUX%%/$EXTRA_CMDLINE_LINUX/" \
	-i $tmp_installdir/install-arch
elif [ "$arch" = "powerpc-softfloat" ] ; then
    sed -e "s/%%UPDATER_UBOOT_NAME%%/$UPDATER_UBOOT_NAME/" \
	-i $tmp_installdir/install-arch
fi
echo -n "."

# Add optional installer configuration file
if [ "$arch" = "x86_64" ] ; then
    cp "$installer_conf" $tmp_installdir || exit 1
    echo -n "."
    GRUB_MACHINE_CONF="$tmp_installdir/grub/grub-machine.cfg"
    echo "## Begin grub-machine.cfg" > $GRUB_MACHINE_CONF
    # make sure each var is 'exported' for GRUB shell
    sed -e 's/\(.*\)=\(.*$\)/\1=\2\nexport \1/' $machine_conf >> $GRUB_MACHINE_CONF
    echo "## End grub-machine.cfg" >> $GRUB_MACHINE_CONF
    echo -n "."
fi
sed -e 's/onie_/image_/' $machine_conf > $tmp_installdir/machine.conf || exit 1
echo -n "."

sharch="$tmp_dir/sharch.tar"
tar -C $tmp_dir -cf $sharch installer || {
    echo "Error: Problems creating $sharch archive"
    exit 1
}
echo -n "."

[ -f "$sharch" ] || {
    echo "Error: $sharch not found"
    exit 1
}
sha1=$(cat $sharch | sha1sum | awk '{print $1}')
echo -n "."
cp $installer_dir/sharch_body.sh $output_file || {
    echo "Error: Problems copying sharch_body.sh"
    exit 1
}

# Replace variables in the sharch template
sed -i -e "s/%%IMAGE_SHA1%%/$sha1/" $output_file
echo -n "."
cat $sharch >> $output_file
rm -rf $tmp_dir
echo " Done."

echo "Success:  ONIE install image is ready in ${output_file}:"
ls -l ${output_file}
