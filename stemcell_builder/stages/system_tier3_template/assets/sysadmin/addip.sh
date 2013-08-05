#!/bin/sh

if [ $# -ne 2 ]; then
        echo Not enough arguments
        echo Usage: nwsetup.sh ipaddress subnet
        exit 127
fi

IPCount=`grep "auto eth0" /etc/network/interfaces | wc -l`

echo "" >> /etc/network/interfaces
echo auto eth0:$IPCount >> /etc/network/interfaces
echo iface eth0:$IPCount inet static >> /etc/network/interfaces
echo address $1 >> /etc/network/interfaces
echo netmask $2 >> /etc/network/interfaces

# restart services
/etc/init.d/networking restart
