#!/bin/sh
sudo ./avahi-aliases-install.sh
sudo ./ldap-install.sh
sudo ./apache-install.sh
sudo ./samba-install.sh

sudo ./ldap-setup.sh
sudo ./apache-setup.sh
sudo ./samba-setup.sh
