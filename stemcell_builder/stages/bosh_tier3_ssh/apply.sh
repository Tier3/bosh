#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source $base_dir/lib/prelude_apply.bash
source $base_dir/lib/prelude_bosh.bash

# Enable root ssh access
sed 's/PermitRootLogin *no/PermitRootLogin yes/i' -i $chroot/etc/ssh/sshd_config

