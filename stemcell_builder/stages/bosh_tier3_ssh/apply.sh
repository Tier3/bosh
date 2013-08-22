#!/usr/bin/env bash
#
# Copyright (c) 2013 Tier 3, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# Enable root ssh access
sed 's/PermitRootLogin *no/PermitRootLogin yes/i' -i $chroot/etc/ssh/sshd_config

# append command to regen ssh keys to end of $chroot/etc/rc.local
grep -v 'exit 0' $chroot/etc/rc.local > $chroot/etc/rc.local.$$

echo '
if [ ! -f /etc/ssh/ssh_host_rsa_key ]
then
  dpkg-reconfigure openssh-server
fi

exit 0
' >> $chroot/etc/rc.local.$$

mv -vf $chroot/etc/rc.local.$$ $chroot/etc/rc.local

