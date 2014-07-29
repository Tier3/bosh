#!/bin/bash

sudo apt-get update
sudo apt-get -y install git parted nano curl zip p7zip-full man-db zlib1g-dev libssl-dev libreadline6-dev libxml2-dev libsqlite3-dev

# For eventmachine
sudo apt-get -y install build-essential

# For Nokogiri
sudo apt-get -y install libxslt-dev libxml2-dev

# For Mysql
sudo apt-get -y install libmysqlclient-dev

# For Postgres
sudo apt-get -y install libpq-dev

# Redis
sudo apt-get -y install redis-server

# Stemcell builds
sudo apt-get -y install debootstrap kpartx

# Ruby 1.9.3
\curl -sSL https://get.rvm.io | sudo bash -s stable
sudo usermod -a -G rvm $USER

echo ""
echo "*****************************"
echo "* Configuration finished."
echo "*   NOTE: Logout and back in for the RVM configuration to take effect."
echo "*****************************"
echo ""
