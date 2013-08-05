#!/bin/sh

# replace existing interfaces file with default
rm -f /etc/network/interfaces
echo "# The loopback network interface" > /etc/network/interfaces
echo "auto lo" >> /etc/network/interfaces
echo "iface lo inet loopback" >> /etc/network/interfaces
echo "" >> /etc/network/interfaces
echo "# The primary network interface" >> /etc/network/interfaces
echo "auto eth0" >> /etc/network/interfaces
echo "iface eth0 inet dhcp" >> /etc/network/interfaces

# restart services
/etc/init.d/networking restart
