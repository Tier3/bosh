#!/bin/sh
## arguments expected: hostname.domain ipaddr subnet gateway dns1 dns2

if [ $# -ne 6 ]; then
        echo Not enough arguments
        echo Usage: nwsetup.sh hostname.domain ipaddress subnet gateway dns1 dns2
        exit 127
fi

## split hostname and domain from argument 1 into variables
HN=`echo $1 | sed 's/\([^.]*\)\.\(.*\)$/\1/'`
DN=`echo $1 | sed 's/\([^.]*\)\.\(.*\)$/\2/'`

## stop networking
echo Stopping network services...
/etc/init.d/networking stop

## delete existing files
echo Deleting existing configuration files...
rm -f /etc/hostname
rm -f /etc/network/interfaces
rm -f /etc/resolv.conf

## setup eth0 interface
echo Setting up the eth0 interface...
echo "# The loopback network interface" > /etc/network/interfaces
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "# The primary network interface" >> /etc/network/interfaces
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet static" >> /etc/network/interfaces
echo address $2 >> /etc/network/interfaces
echo netmask $3 >> /etc/network/interfaces
echo gateway $4 >> /etc/network/interfaces

## set system hostname
echo Setting hostname...
echo $HN > /etc/hostname
hostname $HN

## set DNS resolver properties
echo Setting up DNS...
echo search $DN > /etc/resolv.conf
echo nameserver $5 >> /etc/resolv.conf
echo nameserver $6 >> /etc/resolv.conf

## start new network config
echo Starting network services...
service networking start
