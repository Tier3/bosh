#!/bin/sh

## split hostname and domain from argument 1 into variables
HN=`echo $1 | sed 's/\([^.]*\)\.\(.*\)$/\1/'`
DN=`echo $1 | sed 's/\([^.]*\)\.\(.*\)$/\2/'`

## set system hostname
rm -f /etc/hostname
echo Setting hostname...
echo $HN > /etc/hostname
hostname $HN
