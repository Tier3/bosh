#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash

# Password tool
apt_get install mkpasswd

# sysadmin scripts
cp -r $assets_dir/sysadmin $chroot/sysadmin
run_in_chroot $chroot "
chown -R root:root /sysadmin/*.sh
chmod 700 /sysadmin/*.sh
"

# configure network for DHCP
# code taken from /sysadmin/setdhcp.sh but we're not
# using that script because it tries to restart the interface
rm -f $chroot/etc/network/interfaces
echo "# The loopback network interface" > $chroot/etc/network/interfaces
echo "auto lo" >> $chroot/etc/network/interfaces
echo "iface lo inet loopback" >> $chroot/etc/network/interfaces
echo "" >> $chroot/etc/network/interfaces
echo "# The primary network interface" >> $chroot/etc/network/interfaces
echo "auto eth0" >> $chroot/etc/network/interfaces
echo "iface eth0 inet dhcp" >> $chroot/etc/network/interfaces

# Change root password
run_in_chroot $chroot "
echo root:Password123 | chpasswd
"

# add tier3sa user
run_in_chroot $chroot "
useradd -G sudo tier3sa
echo tier3sa:Password123 | chpasswd
"

#Prevent new or changed network adapters
touch $chroot/etc/udev/rules.d/75-persistent-net-generator.rules
